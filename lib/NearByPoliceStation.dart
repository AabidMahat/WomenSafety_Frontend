import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_config/flutter_config.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mega_project/consts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterConfig.loadEnvVariables();

  runApp(MaterialApp(
    home: PoliceStation(),
  ));
}

class PoliceStation extends StatefulWidget {
  const PoliceStation({super.key});

  @override
  State<PoliceStation> createState() => _PoliceStationState();
}

class _PoliceStationState extends State<PoliceStation> {
  BitmapDescriptor? policeIcon;
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _marker = {};
  Set<Polyline> _polyline = {};
  final List<LatLng> _polylineCoordinates = [];

  @override
  void initState() {
    _getUserLocation();
    setUpIcon();
    super.initState();
  }

  void setUpIcon() {
    BitmapDescriptor.fromAssetImage(
      ImageConfiguration(),
      'assets/policeMarker.png',
    ).then((icon) {
      setState(() {
        policeIcon = icon;
      });
    }).catchError((e) {
      print("Error loading icon: $e");
      Fluttertoast.showToast(msg: "Failed to load police icon.");
    });
  }



  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    _currentPosition = await Geolocator.getCurrentPosition();
    _addCurrentLocationMarker();
    _getNearbyPoliceStations();
  }

  void _addCurrentLocationMarker() {
    if (_currentPosition != null) {
      final currentLocationMarker = Marker(
          markerId: MarkerId('current_location'),
          position:
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(title: "Your Location"));

      setState(() {
        _marker.add(currentLocationMarker);
      });
    }
  }

  Future<void> _getNearbyPoliceStations() async {
    final apiKey = GOOGLE_API_KEY;
    final radius = 5000;

    final baseURl =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

    final url =
        '$baseURl?location=${_currentPosition!.latitude},${_currentPosition!.longitude}&radius=$radius&type=police&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['status'] == 'OK' && policeIcon != null) {
        for (var place in data['results']) {
          // Fetch and display the details including the phone number
          _getPoliceStationDetails(place);
        }
      } else {
        Fluttertoast.showToast(msg: "No police stations found nearby.");
      }
    } else {
      Fluttertoast.showToast(msg: "Failed to fetch nearby police stations.");
    }
  }

  Future<void> _getPoliceStationDetails(Map<String, dynamic> place) async {
    final apiKey = GOOGLE_API_KEY;
    final placeId = place['place_id'];
    final url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final result = data['result'];

        final phoneNumber = result['formatted_phone_number'] ?? 'No phone available';

        // Create a marker with the police station details
        final marker = Marker(
          markerId: MarkerId(placeId),
          position: LatLng(
            place['geometry']['location']['lat'],
            place['geometry']['location']['lng'],
          ),
          icon: policeIcon!,
          infoWindow: InfoWindow(
            title: place['name'],
            snippet: " ${place['vicinity']}\nPhone: $phoneNumber",
          ),
          onTap: () => _getRouteToMarker(LatLng(
            place['geometry']['location']['lat'],
            place['geometry']['location']['lng'],
          )),
        );

        // Update the markers on the map
        setState(() {
          _marker.add(marker);
        });
      } else {
        Fluttertoast.showToast(msg: "Failed to fetch police station details.");
      }
    } else {
      Fluttertoast.showToast(msg: "Failed to fetch police station details.");
    }
  }


  Future<void> _getRouteToMarker(LatLng destination) async {
    final apiKey = GOOGLE_API_KEY;

    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${_currentPosition!.latitude},${_currentPosition!.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final routes = data['routes'] as List;
        if (routes.isNotEmpty) {
          final polyline = routes[0]['overview_polyline']['points'];
          _decodePolyline(polyline);
        }
      } else {
        Fluttertoast.showToast(msg: "Failed to fetch route.");
      }
    } else {
      Fluttertoast.showToast(msg: "Failed to fetch route.");
    }
  }

  void _decodePolyline(String encodedPolyline) {
    final List<LatLng> points = _convertToLatLng(_decodePoly(encodedPolyline));
    setState(() {
      _polyline.add(Polyline(
        polylineId: PolylineId('route'),
        color: Colors.blue,
        width: 5,
        points: points,
      ));
    });
  }

  List<LatLng> _convertToLatLng(List<PointLatLng> points) {
    return points.map((point) => LatLng(point.latitude, point.longitude)).toList();
  }

  List<PointLatLng> _decodePoly(String encoded) {
    List<PointLatLng> poly = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      PointLatLng point = PointLatLng(
        (lat / 1E5).toDouble(),
        (lng / 1E5).toDouble(),
      );
      poly.add(point);
    }
    return poly;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentPosition == null
          ? Center(
        child: CircularProgressIndicator(
          color: Colors.blue.shade900,
        ),
      )
          : GoogleMap(
        initialCameraPosition: CameraPosition(
            target: LatLng(
                _currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 14.0),
        markers: _marker,
        polylines: _polyline,
        onMapCreated: (controller) {
          setState(() {
            _mapController = controller;
          });
        },
      ),
    );
  }
}
