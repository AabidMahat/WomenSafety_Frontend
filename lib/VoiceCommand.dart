import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

class NewVoiceCommand extends StatefulWidget {
  const NewVoiceCommand({super.key});

  @override
  State<NewVoiceCommand> createState() => _NewVoiceCommandState();
}

class _NewVoiceCommandState extends State<NewVoiceCommand> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnable = false;

  String _wordsSpoken = "";
  double _confidenceLevel = 0;



  @override
  void initState() {
    super.initState();
    initSpeech();
  }

  void initSpeech() async {
    try {
      _speechEnable = await _speechToText.initialize();
      if (_speechEnable) {
        print('Speech recognition initialized successfully.');
      } else {
        print('Speech recognition initialization failed.');
      }
      setState(() {});
    } catch (e) {
      print('Speech recognition initialization error: $e');
    }
  }


  void _startlistening() async {
    try {
      if (!_speechEnable) {
        print('Speech recognition is not enabled.');
        return;
      }
      print("Anaylizing the text");
      await _speechToText.listen(
          onResult: (result) {
            _onSpeechResult(result);
          });
      setState(() {
        _confidenceLevel = 0;
      });
      print('Listening started');
    } catch (e) {
      print('Error starting listening: $e');
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(result) {
    print("Recognized Words: ${result.recognizedWords}");
    print("Confidence Level: ${result.confidence}");
    setState(() {
      _wordsSpoken = result.recognizedWords;
      _confidenceLevel = result.confidence ?? 0;
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red.shade900,
        title: Text(
          "Speech Demo",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              child: Text(
                _speechToText.isListening
                    ? 'Listening...'
                    : _speechEnable
                        ? 'Tap the microphone to start listening...'
                        : "Speech is not available",
                style: TextStyle(fontSize: 20),
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(10),
                child: Text(_wordsSpoken),
              ),
            ),
            if (_speechToText.isNotListening && _confidenceLevel > 0)
              Text(
                "Confidence: ${(_confidenceLevel * 100).toStringAsFixed(1)}%",
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _speechToText.isListening ? _stopListening : _startlistening,
        tooltip: 'Listen',
        child: Icon(
          _speechToText.isNotListening ? Icons.mic_off : Icons.mic,
          color: Colors.black,
        ),
      ),
    );
  }
}
