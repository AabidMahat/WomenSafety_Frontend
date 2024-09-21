import 'package:audioplayers/audioplayers.dart';
import 'package:background_sms/background_sms.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:porcupine_flutter/porcupine_error.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:mega_project/consts.dart';


class VoiceCommand extends StatefulWidget {
  const VoiceCommand({super.key});

  @override
  State<VoiceCommand> createState() => _VoiceCommandState();
}

class _VoiceCommandState extends State<VoiceCommand> {
  PorcupineManager? _porcupineManager;
  bool _speechEnable = false;
  String _wordsSpoken = "";
  double _confidenceLevel = 0;

  bool _isRinging = false;


  final String _keywordAsset = "assets/HELP-ME_en_android_v3_0_0.ppn";
  final String _accessKey = PICOVOICE_API_KEY;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    print('Initializing Porcupine...');
    initPorcupine();
  }

  void initPorcupine() async {
    try {
      _porcupineManager = await PorcupineManager.fromKeywordPaths(
        _accessKey,
        [_keywordAsset],
        _wakeWordCallback,
      );
      await _porcupineManager?.start();
      print('Porcupine initialized and listening...');
    } on PorcupineException catch (err) {
      Fluttertoast.showToast(msg: 'Error: ${err.message}');
    }
  }

  void _wakeWordCallback(int keywordIndex) {
    print("Wake word detected: $keywordIndex");
    if (keywordIndex == 0) {
      // Keyword detected
      _sendEmergencySMS();
    }
  }

  Future<void> _sendEmergencySMS() async {
    try {
      Position position = await _determinePosition();
      final mapsLink =
          'https://www.google.com/maps/?q=${position.latitude},${position.longitude}';

      final detailedMessage =
          "I'm in trouble and need help! Here is my current location: $mapsLink. Please come as soon as possible.";

      String guardianPhoneNumber = '7559153594'; // Replace with the actual phone number

      await BackgroundSms.sendMessage(
        phoneNumber: guardianPhoneNumber,
        message: detailedMessage,
        simSlot: 1,
      ).then((SmsStatus status) {
        if (status == SmsStatus.sent) {
          Fluttertoast.showToast(msg: "Emergency message sent!");
          setState(() {
            _isRinging = true;
          });
          _playBeepSound();
        } else {
          Fluttertoast.showToast(msg: "Failed to send emergency message.");
        }
      });
    } catch (e) {
      print("SMS Error: $e");
      Fluttertoast.showToast(msg: 'Error: ${e.toString()}');
    }
  }

  Future<void> _playBeepSound() async {
    while(_isRinging) {
      await _audioPlayer.play(AssetSource("alert.mp3"));
      await _audioPlayer.onPlayerComplete.first; // Wait until the sound finishes playing
      await Future.delayed(Duration(milliseconds: 500));
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(msg: 'Location services are disabled.');
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: 'Location permissions are denied.');
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(
          msg: 'Location permissions are permanently denied.');
      return Future.error('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }



  @override
  void dispose() {
    _porcupineManager?.delete();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red.shade900,
        title: Text(
          "Voice Command",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              child: Text(
                'Porcupine is listening...',
                style: TextStyle(fontSize: 20),
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(10),
                child: Text(_wordsSpoken),
              ),
            ),
            if (_confidenceLevel > 0)
              Text(
                "Confidence: ${(_confidenceLevel * 100).toStringAsFixed(1)}%",
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          setState(() {
            _isRinging = false;
          });
        },
        child: Icon(Icons.volume_mute,color: Colors.black,),
      ),
    );
  }
}
