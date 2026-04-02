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
      // Tell the player to load the audio from your Firebase URL
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
    // ! Stop the audio and free up resources when the widget is destroyed
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return const Center(child: Text('Error loading audio', style: TextStyle(color: Colors.red)));
    }



    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900], // Dark background for audio posts
        image: widget.coverUrl != "default" ? DecorationImage(image: NetworkImage(widget.coverUrl!), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken)) : DecorationImage(image: AssetImage('assets/icons/user-profile-icon.png')),
      ),
      child: Center(
        // We use a StreamBuilder to listen to the player's state
        // This automatically updates the UI to show a Play, Pause, or Loading button
        child: StreamBuilder<PlayerState>(
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
            if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering) {
              return const CircularProgressIndicator(color: Colors.white);
            } else if (processingState == ProcessingState.idle) {
              // audio player has not been provided an Url
              return Text("No audio has been provided to the audio player", style: TextStyle(color: Colors.red));
            } else if (playing == false) {
              // if not loading nor buffering, and also playing is set to pause, we show the "play" icon button
              return IconButton(
                icon: const Icon(Icons.play_circle_fill),
                iconSize: 80.0,
                color: Colors.white,
                onPressed: _audioPlayer.play, // trigger audio to play
              );
              // else if the player is playing (playing==true), and there is still audio to be processed, we show "pause" icon button
            } else if (processingState != ProcessingState.completed) {
              return IconButton(
                icon: const Icon(Icons.pause_circle_filled),
                iconSize: 80.0,
                color: Colors.white,
                onPressed: _audioPlayer.pause, // trigger audio to pause
              );
            } else {
              // there is no more audio to be processed, because ProcessingState is not complete
              // Audio has finished playing, show replay button
              return IconButton(icon: const Icon(Icons.replay_circle_filled), iconSize: 80.0, color: Colors.white, onPressed: () => _audioPlayer.seek(Duration.zero));
            }
          },
        ),
      ),
    );
  }
}
