import 'package:art_platform/ui/widgets/media_representation/audio_reader_widget.dart';
import 'package:art_platform/ui/widgets/media_representation/image_reader_widget.dart';
import 'package:art_platform/ui/widgets/media_representation/text_reader_widget.dart';
import 'package:art_platform/ui/widgets/media_representation/video_reader_widget.dart';
import 'package:flutter/material.dart';
import 'package:art_platform/data/models/art_post.dart';

/// Acts as a wrapper for
class ArtPostRepresentation extends StatelessWidget {
  // Data which defines the ArtPostCard object
  final ArtPost post; // contains all data related to the ArtPost
  final bool postInformationVisible; // state variable for the fading and position effects of the post information widgets
  final VoidCallback callStartHideTimer;

  /// Constructor requires a [ArtPost] and [bool] to be passed to the [post] and [postInformationVisible] parameters.
  const ArtPostRepresentation({super.key, required this.post, required this.postInformationVisible, required this.callStartHideTimer});

  // The visual representation of the ArtPostCard
  @override
  Widget build(BuildContext context) {
    Widget innerWidget;
    switch (post.mediaType) {
      case MediaType.image:
        innerWidget =  ImageReaderWidget(post: post, postInformationVisible: postInformationVisible);
      case MediaType.video:
        innerWidget = VideoReaderWidget(post: post, postInformationVisible: postInformationVisible);
      case MediaType.audio:
        innerWidget = AudioReaderWidget(post: post, postInformationVisible: postInformationVisible);
      case MediaType.text:
        innerWidget = TextReaderWidget(post: post, postInformationVisible: postInformationVisible, callStartHideTimer: callStartHideTimer,);
      default:
        return const Center(child: Text("Unsupported format"));
    }

    return innerWidget;
  }

}