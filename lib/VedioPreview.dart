import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mega_project/api/Firebase_api.dart';
import 'package:video_player/video_player.dart';

class VideoPreview extends StatefulWidget {
  final File videoFile;
  final String videoPath;
  const VideoPreview({required this.videoFile, required this.videoPath, super.key});

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  FirebaseApi firebaseApi = FirebaseApi();
  String ? downloadUrl;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        setState(() {});  // Ensure the first frame is shown after the video is initialized
      });
    _downloadVideo();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _downloadVideo()async{
    downloadUrl = await firebaseApi.uploadVideo(widget.videoPath);
    print("Download Url $downloadUrl");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Preview'),
      ),
      body: Center(
        child: _controller.value.isInitialized
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: () {
                    setState(() {
                      _isPlaying ? _controller.pause() : _controller.play();
                      _isPlaying = !_isPlaying;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.replay),
                  onPressed: () {
                    _controller.seekTo(Duration.zero);
                    _controller.play();
                    setState(() {
                      _isPlaying = true;
                    });
                  },
                ),
              ],
            ),
          ],
        )
            : const CircularProgressIndicator(),  // Show a loader while video is loading
      ),
    );
  }
}
