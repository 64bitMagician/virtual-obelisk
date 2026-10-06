import 'package:art_platform/data/models/art_post.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoReaderWidget extends StatefulWidget {
  final ArtPost post;
  final bool postInformationVisible;

  const VideoReaderWidget({
    super.key,
    required this.post,
    required this.postInformationVisible,
  });

  @override
  State<VideoReaderWidget> createState() => _VideoReaderWidgetState();
}

class _VideoReaderWidgetState extends State<VideoReaderWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.post.mediaUrl));

      await _controller.initialize();

      await _controller.setLooping(true);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _controller.play();
      }
    } catch (e) {
      debugPrint("Error loading video: $e");
      if (mounted) setState(() => _isError = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String minutes = duration.inMinutes.toString();
    String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return const Center(
        child: Text('Error loading video', style: TextStyle(color: Colors.red)),
      );
    }

    if (!_isInitialized) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.post.additionalMediaUrl != "default")
              Image.network(widget.post.additionalMediaUrl, fit: BoxFit.cover, color: Colors.black45, colorBlendMode: BlendMode.darken)
            else
              Image.asset("assets/icons/default-video-gallery-asset.png", fit: BoxFit.cover, color: Colors.black45, colorBlendMode: BlendMode.darken),
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),

          Positioned.fill(
            child: GestureDetector(
              onTap: _togglePlayPause,
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: Colors.transparent,

                child: ValueListenableBuilder(
                  valueListenable: _controller,
                  builder: (context, VideoPlayerValue value, child) {

                    if (value.isBuffering) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    if (!value.isPlaying) {
                      return Center(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 80.0,
                          ),
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            bottom: widget.postInformationVisible ? 40 : -100,
            left: 20,
            right: 20,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: widget.postInformationVisible ? 1.0 : 0.0,
              child: ValueListenableBuilder(
                valueListenable: _controller,
                builder: (context, VideoPlayerValue value, child) {
                  final position = value.position.inMilliseconds.toDouble();
                  final duration = value.duration.inMilliseconds.toDouble();

                  return Row(
                    children: [
                      Text(_formatDuration(value.position), style: const TextStyle(color: Colors.white, shadows: [Shadow(blurRadius: 4, color: Colors.black)])),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4.0,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                            activeTrackColor: Colors.white,
                            inactiveTrackColor: Colors.white38,
                            thumbColor: Colors.white,
                          ),
                          child: Slider(
                            min: 0.0,
                            max: duration > 0 ? duration : 1.0,
                            value: position > duration ? duration : position,
                            onChanged: (newPosition) {
                              _controller.seekTo(Duration(milliseconds: newPosition.toInt()));
                            },
                          ),
                        ),
                      ),
                      Text(_formatDuration(value.duration), style: const TextStyle(color: Colors.white, shadows: [Shadow(blurRadius: 4, color: Colors.black)])),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}