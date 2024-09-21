import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:mega_project/VedioPreview.dart';
import 'package:path_provider/path_provider.dart';

class VideoCaptureService {
  final BuildContext context;
  CameraController? _cameraController;
  late List<CameraDescription> _cameras;
  bool isRecording = false;

  VideoCaptureService(this.context);

  Future<void> initializeCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(_cameras[0], ResolutionPreset.low);

    await _cameraController?.initialize();
  }

  Future<void> startRecording() async {
    if (_cameraController != null &&
        !_cameraController!.value.isRecordingVideo) {
      final directory = await getApplicationDocumentsDirectory();
      final videoPath =
          '${directory.path}/video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      await _cameraController!.startVideoRecording();
      isRecording = true;

      // Automatically stop recording after 30 seconds
      Timer(Duration(seconds: 30), () async {
        if (isRecording) {
          await stopRecording();
        }
      });
    }
  }

  Future<void> stopRecording() async {
    if (_cameraController != null &&
        _cameraController!.value.isRecordingVideo) {
      final videoFile = await _cameraController!.stopVideoRecording();
      isRecording = false;

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => VideoPreview(
                  videoFile: File(videoFile.path), videoPath: videoFile.path)));
    }
  }
  Widget buildCameraPreview() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return CameraPreview(_cameraController!);
  }

  void disposeCamera() {
    _cameraController?.dispose();
  }
}
