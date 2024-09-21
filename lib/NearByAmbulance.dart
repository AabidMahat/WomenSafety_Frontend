import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_config/flutter_config.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mega_project/consts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterConfig.loadEnvVariables();

  runApp(MaterialApp(
    home: Ambulance(),
  ));
}

class Ambulance extends StatefulWidget {
  const Ambulance({super.key});

  @override
  State<Ambulance> createState() => _AmbulanceState();
}

class _AmbulanceState extends State<Ambulance> {
  GoogleMapController? _mapController;
  Position? _currentPosition;

  Set<Marker> _marker = {};

  @override
  void initState() {
    _getUserLocation();
    super.initState();
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
    _getNearbyAmbulances();
  }

  void _addCurrentLocationMarker() {
    if (_currentPosition != null) {
      final currentLocationMarker = Marker(
          markerId: MarkerId('current_location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(title: "Your Location"));

      setState(() {
        _marker.add(currentLocationMarker);
      });
    }
  }

  Future<void> _getNearbyAmbulances() async {
    final apiKey = GOOGLE_API_KEY; // Make sure to load the API key
    final radius = 5000;

    final baseURl = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json';
    final url = '$baseURl?location=${_currentPosition!.latitude},${_currentPosition!.longitude}&radius=$radius&type=hospital&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        setState(() {
          _marker.addAll(data['results'].map<Marker>((place) {
            return Marker(
                markerId: MarkerId(place['place_id']),
                position: LatLng(
                  place['geometry']['location']['lat'],
                  place['geometry']['location']['lng'],
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                infoWindow: InfoWindow(
                    title: place['name'], snippet: place['vicinity']));
          }).toSet());
        });
      } else {
        Fluttertoast.showToast(msg: "No ambulance services found nearby.");
      }
    } else {
      Fluttertoast.showToast(msg: "Failed to fetch nearby ambulance services.");
    }
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
        onMapCreated: (controller) {
          setState(() {
            _mapController = controller;
          });
        },
      ),
    );
  }
}
