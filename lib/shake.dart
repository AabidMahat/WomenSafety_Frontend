import 'dart:async';

import 'package:background_sms/background_sms.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mega_project/FeedBack/FeedBackMap.dart';
import 'package:mega_project/MapPage.dart';
import 'package:mega_project/NearByAmbulance.dart';
import 'package:mega_project/NearByPoliceStation.dart';

import 'package:mega_project/Porcupine.dart';
import 'package:mega_project/api/NotificationApi.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state/phone_state.dart';
import 'package:shake/shake.dart';

import 'package:mega_project/api/Firebase_api.dart';
import 'package:mega_project/firebase_options.dart';

import 'package:mega_project/vedioPlayer.dart';

import 'package:image_picker/image_picker.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseApi().initNotification();

  runApp(MaterialApp(
    home: ShakeWidget(),
    navigatorKey: navigatorKey,
    routes: {
      '/shake': (context) => ShakeWidget(),
    },
  ));
}

class ShakeWidget extends StatefulWidget {
  const ShakeWidget({super.key});

  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget> {
  Position? _currentPosition;
  String _currentAddress = 'Fetching Location...';
  late ShakeDetector _shakeDetector;
  late PhoneStateStatus _callState;
  late VideoCaptureService videoCaptureService;
  bool showCamera = false;
  Timer ? timer;

  @override
  void initState() {
    super.initState();
    videoCaptureService = VideoCaptureService(context);
    videoCaptureService.initializeCamera();
    _requestPhoneStatePermission();
    _startListening();

    // ConnectivityService();
    // Initialize ShakeDetector
    _shakeDetector = ShakeDetector.autoStart(
      onPhoneShake: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shake detected!'),
          ),
        );
        // Actions on phone shake
        _requestSmsPermission(); // Request permission on shake
      },
      minimumShakeCount: 2,
      shakeSlopTimeMS: 500,
      shakeCountResetTime: 3000,
      shakeThresholdGravity: 2.7,
    );

    _getCurrentLocation();
  }

  @override
  void dispose() {
    videoCaptureService.disposeCamera();
    _shakeDetector.stopListening(); // Stop ShakeDetector when not needed
    super.dispose();
  }

  Future<void> _requestPhoneStatePermission() async {
    final status = await Permission.phone.request();
    if (!status.isGranted) {
      Fluttertoast.showToast(msg: 'Phone state permission is not granted');
    }
  }

  void _startListening(){
    print("Listener Initialized");
    PhoneState.stream.listen((PhoneState state) {
      setState(() {
        _callState =state.status;
      });
      if(_callState==PhoneStateStatus.CALL_ENDED){
        _onCallEnd();
      }
    });
  }

  Future<void> _onCallEnd()async{
    print("Call ended. Sending notification and SMS...");
    // sendNotification();
    await Future.delayed(Duration(seconds: 5));
    _sendSMS("7559153594", "");
  }

  _getCurrentLocation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: 'Location Permission is denied');
        return;
      } else if (permission == LocationPermission.deniedForever) {
        Fluttertoast.showToast(
            msg: 'Location permission is permanently denied');
        return;
      }
    }

    Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      forceAndroidLocationManager: true,
    ).then((Position position) {
      setState(() {
        _currentPosition = position;
      });

      _getAddressFromLatLng();
    }).catchError((e) {
      print(e);
    });
  }

  _getAddressFromLatLng() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          _currentPosition!.latitude, _currentPosition!.longitude);

      Placemark place = placemarks[0];

      setState(() {
        _currentAddress =
            "${place.locality}, ${place.street}, ${place.administrativeArea}, ${place.postalCode}";
      });
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  Future<void> _requestSmsPermission() async {
    final status = await Permission.sms.request();
    if (status.isGranted) {
      _sendSMS('7559153594', _currentAddress);
    } else {
      Fluttertoast.showToast(msg: 'SMS permission is not granted');
    }
  }

  Future<void> _sendSMS(String phoneNumber, String message) async {
    try {
      final mapsLink =
          'https://www.google.com/maps/?q=${_currentPosition?.latitude},${_currentPosition?.longitude}';

      // Construct a more detailed message
      final detailedMessage =
          "I'm in trouble and need help! Here is my current location: $mapsLink. ";

      await BackgroundSms.sendMessage(
        phoneNumber: phoneNumber,
        message: detailedMessage,
      ).then((SmsStatus status) {
        if (status == SmsStatus.sent) {
          Fluttertoast.showToast(msg: "Message Sent");
        } else {
          Fluttertoast.showToast(msg: "Failed to send SMS");
        }
      });
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Shake"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_currentAddress),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => MapPage()));
              },
              child: const Text("See Location"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => VoiceCommand()));
              },
              child: const Text("Voice Command"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => PoliceStation()));
              },
              child: const Text("All Nearby Police Station"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Ambulance()));
              },
              child: const Text("All Nearby Ambulance"),
            ),
            ElevatedButton(
              onPressed: () {
                sendNotification();
              },
              child: const Text("Send Firebase Notification"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=>FeedbackScreen(currentPosition:_currentPosition!)));
                // Navigator.push(context, MaterialPageRoute(builder: (context)=>FeedbackForm(
                //     position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude))));

              },
              child: const Text("Show Form"),
            ),
            ElevatedButton(
              onPressed: () {
               makeCall();

              },
              child: const Text("Make Call"),
            ),

            ElevatedButton(
              onPressed: () {
                if (!videoCaptureService.isRecording) {
                  setState(() {
                    videoCaptureService.startRecording();
                    showCamera = true;
                  });
                } else {
                  setState(() {
                    videoCaptureService.stopRecording();
                    showCamera =false;
                  });
                }
              },
              child: Text(videoCaptureService.isRecording ? 'Stop Recording' : 'Start Recording'),
            ),
            if (showCamera)
              Expanded(child: videoCaptureService.buildCameraPreview()),
          ],
        ),
      ),
    );
  }
}
