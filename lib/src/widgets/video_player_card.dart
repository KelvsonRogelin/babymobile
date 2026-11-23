import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerCard extends StatefulWidget {
  const VideoPlayerCard({
    super.key,
    required this.filePath,
    this.autoPlay = false,
    this.loop = false,
    this.onEnded,
  });

  final String filePath;
  final bool autoPlay;
  final bool loop;
  final VoidCallback? onEnded;

  @override
  State<VideoPlayerCard> createState() => _VideoPlayerCardState();
}

class _VideoPlayerCardState extends State<VideoPlayerCard> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  @override
  void didUpdateWidget(covariant VideoPlayerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath) {
      _disposeController();
      _setup();
    }
  }

  Future<void> _setup() async {
    final controller = VideoPlayerController.file(File(widget.filePath));
    await controller.initialize();
    await controller.setLooping(widget.loop);
    if (widget.autoPlay) {
      await controller.play();
    }
    controller.addListener(() {
      if (widget.onEnded != null &&
          controller.value.isInitialized &&
          !controller.value.isPlaying &&
          controller.value.position >= controller.value.duration &&
          controller.value.duration > Duration.zero) {
        widget.onEnded!.call();
      }
    });
    if (mounted) {
      setState(() => _controller = controller);
    } else {
      await controller.dispose();
    }
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;
    await controller?.dispose();
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const AspectRatio(
        aspectRatio: 9 / 16,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio == 0 ? 9 / 16 : controller.value.aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            VideoPlayer(controller),
            Align(
              alignment: Alignment.bottomCenter,
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.white,
                  bufferedColor: Colors.white54,
                  backgroundColor: Colors.black26,
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 18,
              child: FloatingActionButton.small(
                heroTag: null,
                onPressed: () async {
                  if (controller.value.isPlaying) {
                    await controller.pause();
                  } else {
                    await controller.play();
                  }
                  if (mounted) setState(() {});
                },
                child: Icon(controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
