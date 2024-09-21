import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:mega_project/consts.dart';
import 'package:web_socket_channel/io.dart';

void main() {
  runApp(MaterialApp(
    home: MapPage(),
  ));
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Location _locationController = new Location();

  final Completer<GoogleMapController> _mapController =
  Completer<GoogleMapController>();

  static const LatLng initialPosition = LatLng(16.69531, 74.1987433);
  static const LatLng finalPosition = LatLng(19.0330, 73.0297);
  LatLng? _currentPosition = null;

  Map<PolylineId, Polyline> polylines = {};

  Set<Circle> _circles = {};

  late IOWebSocketChannel _webSocketChannel;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    getLocationAndUpdate().then((_) => getPolyLinePoints()
        .then((coordinates) => {generatePolyLineFromPoints(coordinates)}));
  }

  // Connect to web socket

  void _connectWebSocket(){
    _webSocketChannel = IOWebSocketChannel.connect('ws://${TESTURL}');

    _webSocketChannel.stream.listen((message) {
      var data = jsonDecode(message);

      if(data['latitude'] !=null && data['longitude']!=null){
        setState(() {
          _currentPosition = LatLng(data['latitude'], data['longitude']);
          _updateCircle();
        });
      }
    });
  }

  Future<void> getLocationAndUpdate() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _locationController.serviceEnabled();

    if (_serviceEnabled) {
      _serviceEnabled = await _locationController.requestService();
    } else {
      return;
    }

    _permissionGranted = await _locationController.hasPermission();

    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationController.requestPermission();

      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
    _locationController.changeSettings(interval: 1000);
    _locationController.onLocationChanged
        .listen((LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          _currentPosition =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
        });
        _cameraPosition(_currentPosition!);
        _updateCircle();

        //   Send location to the WebSocket server
        _webSocketChannel.sink.add(jsonEncode({
          'userId':"Aabid1234",
          'latitude': currentLocation.latitude,
          'longitude': currentLocation.longitude,
          'timestamp': DateTime.now().toIso8601String(),
        }));
      }
    });
  }

  Future<void> _cameraPosition(LatLng position) async {
    final GoogleMapController controller = await _mapController.future;
    CameraPosition _newCameraPosition =
    CameraPosition(target: position, zoom: 13);

    await controller
        .animateCamera(CameraUpdate.newCameraPosition(_newCameraPosition));
  }

  Future<List<LatLng>> getPolyLinePoints() async {
    List<LatLng> polylineCoords = [];

    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        GOOGLE_API_KEY,
        PointLatLng(initialPosition.latitude, initialPosition.longitude),
        PointLatLng(finalPosition.latitude, finalPosition.longitude),
        travelMode: TravelMode.driving);

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoords.add(LatLng(point.latitude, point.longitude));
      });
    } else {
      Fluttertoast.showToast(msg: result.errorMessage!);
    }
    return polylineCoords;
  }

  void generatePolyLineFromPoints(List<LatLng> polylineCoordinate) async {
    PolylineId id = PolylineId('poly');
    Polyline polyline = Polyline(
        polylineId: id,
        color: Colors.blue.shade900,
        width: 6,
        points: polylineCoordinate);

    setState(() {
      polylines[id] = polyline;
    });
  }

  void _updateCircle() {
    if (_currentPosition != null) {
      setState(() {
        _circles.clear();
        _circles.add(
          Circle(
              circleId: CircleId("currentLocationCircle"),
              center: _currentPosition!,
              radius: 10,
              strokeColor: Colors.blueAccent,
              strokeWidth: 2,
              fillColor: Colors.blueAccent.withOpacity(0.2)),
        );
      });
    }
  }



  @override
  void dispose() {
    _webSocketChannel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentPosition == null
          ? Text('Loading...')
          : GoogleMap(
        onMapCreated: ((GoogleMapController controller) =>
            _mapController.complete(controller)),
        initialCameraPosition:
        CameraPosition(target: initialPosition, zoom: 13),
        markers: {
          Marker(
              markerId: MarkerId("currentLocation"),
              icon: BitmapDescriptor.defaultMarker,
              position: initialPosition),
          Marker(
              markerId: MarkerId("finalLocation"),
              icon: BitmapDescriptor.defaultMarker,
              position: finalPosition),
          Marker(
              markerId: MarkerId("mainMarker"),
              icon:  BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              position: _currentPosition!)
        },
        polylines: Set<Polyline>.of(polylines.values),
        circles: _circles,
      ),
    );
  }
}
