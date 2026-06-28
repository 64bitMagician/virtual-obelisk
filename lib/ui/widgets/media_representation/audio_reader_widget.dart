import 'package:art_platform/data/models/art_post.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioReaderWidget extends StatefulWidget {
  final ArtPost post;
  final bool postInformationVisible;

  const AudioReaderWidget({
    super.key,
    required this.post,
    required this.postInformationVisible,
  });

  String get audioUrl => post.mediaUrl;
  String get coverUrl => post.additionalMediaUrl;

  @override
  State<AudioReaderWidget> createState() => _AudioReaderWidgetState();
}

class _AudioReaderWidgetState extends State<AudioReaderWidget> {
  late AudioPlayer _audioPlayer;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      await _audioPlayer.setUrl(widget.audioUrl);
    } catch (e) {
      print("Error loading audio: $e");
      if (mounted) {
        setState(() => _isError = true);
      }
    }
  }

  @override
  void dispose() {
    // Stop the audio and free up resources when the widget is destroyed
    _audioPlayer.dispose();
    super.dispose();
  }

  // Helper method to format Duration into mm:ss
  String _formatDuration(Duration? duration) {
    if (duration == null) return "0:00";
    String minutes = (duration.inMinutes % 60).toString(); // return the whole minutes passed
    String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0'); // return timestamp of seconds
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return const Center(child: Text('Error loading audio', style: TextStyle(color: Colors.red)));
    }

    return Container(
      color: Colors.grey[900], // Solid dark background for the player
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  image: widget.coverUrl != "default"
                      ? DecorationImage(
                    image: NetworkImage(widget.coverUrl),
                    fit: BoxFit.cover,
                  )
                      : const DecorationImage(
                    image: AssetImage('assets/icons/default-audio-coverart.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          StreamBuilder<Duration>(
            stream: _audioPlayer.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = _audioPlayer.duration ?? Duration.zero;

              // Prevent slider from breaking if position briefly exceeds duration
              double sliderValue = position.inMilliseconds.toDouble();
              double sliderMax = duration.inMilliseconds.toDouble();
              if (sliderValue > sliderMax) sliderValue = sliderMax;

              return Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4.0,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.grey[700],
                      thumbColor: Colors.white,
                    ),
                    child: Slider(
                      min: 0.0,
                      max: sliderMax > 0 ? sliderMax : 1.0,
                      value: sliderValue,
                      onChanged: (value) {
                        _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                      },
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(position), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(_formatDuration(duration), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // PLAYBACK CONTROLS
          // This represents the Play/Stop/Repeat Button, and their behaviours
          // Also represents the state of the Audio Player in relation to the Streamed Audio
          StreamBuilder<PlayerState>(
          // Because just_audio package uses a Stream to update the UI, it has to emit a single object every
          // time something changes. [PlayerState] is that object. Whenever the user presses play,
          // or whenever the network buffers, just_audio package spits out a brand new PlayerState object
          // so the StreamBuilder can rebuild the UI.
            stream: _audioPlayer.playerStateStream,
            builder: (context, snapshot) {
              // [PlayerState?] is just a wrapper object that packages playing and processingState together.
              final PlayerState? playerState = snapshot.data;
              // [ProcessingState?] is an enum that tells you exactly what the underlying audio engine is
              // currently doing. It has five possible states:
              // - idle: The player is empty. No Url provided yet.
              // - loading: You gave it a URL, and it is actively downloading the very first chunk of data. (You usually show a spinner here).
              // - buffering: The audio was playing, but it ran out of downloaded data. It has paused automatically to fetch the next chunk
              //              over the network. (You usually show a spinner here, too).
              // - ready: The player has enough data loaded into memory to play audio smoothly.
              // - completed: The audio track has reached the very end.
              final ProcessingState? processingState = playerState?.processingState;
              // [playing] is a boolean that represents whether the audio player is playing or paused state
              // .play() and .pause() alter the state of this boolean...
              // Note: Just because playing is true does not mean the user is actually hearing music.
              // Note: For example, the user might have pressed play, but the app is still downloading the MP3
              // Note: over a slow 3G connection. This relates to [ProcessingState] object.
              final bool? playing = playerState?.playing;

              // So we show loading animation if player is loading or buffering
              if (processingState == ProcessingState.loading ||
                  processingState == ProcessingState.buffering) {
                return Container(
                  margin: const EdgeInsets.all(16.0),
                  width: 48.0,
                  height: 48.0,
                  child: const CircularProgressIndicator(color: Colors.white),
                );
              } else if (processingState == ProcessingState.idle) {
                // audio player has not been provided an Url
                return Text("No audio has been provided to the audio player", style: TextStyle(color: Colors.red));
              }  else if (playing == false) {
                // if not loading nor buffering, and also playing is set to pause, we show the "play" icon button
                return IconButton(
                  icon: const Icon(Icons.play_circle_fill),
                  iconSize: 80.0,
                  color: Colors.white,
                  onPressed: _audioPlayer.play, // trigger audio to play
                );
              } else if (processingState != ProcessingState.completed) {
                return IconButton(
                  icon: const Icon(Icons.pause_circle_filled),
                  iconSize: 80.0,
                  color: Colors.white,
                  onPressed: _audioPlayer.pause, // trigger audio to pause
                );
              } else {
                // there is no more audio to be processed, because ProcessingState is now completed
                // Audio has finished playing, show replay button
                return IconButton(
                  icon: const Icon(Icons.replay_circle_filled),
                  iconSize: 80.0,
                  color: Colors.white,
                  onPressed: () => _audioPlayer.seek(Duration.zero),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}




