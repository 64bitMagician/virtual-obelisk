import 'package:art_platform/ui/widgets/media/audio_feed_widget.dart';
import 'package:art_platform/ui/widgets/media/image_feed_widget.dart';
import 'package:art_platform/ui/widgets/media/text_feed_widget.dart';
import 'package:art_platform/ui/widgets/media/video_feed_widget.dart';
import 'package:flutter/material.dart';
import 'package:art_platform/data/models/art_post.dart';

class ArtPostRepresentation extends StatelessWidget {
  // Data which defines the ArtPostCard object
  final ArtPost post; // contains all data related to the ArtPost
  final bool postInformationVisible; // state variable for the fading and position effects of the post information widgets

  /// Constructor requires a [ArtPost] and [bool] to be passed to the [post] and [postInformationVisible] parameters.
  const ArtPostRepresentation({super.key, required this.post, required this.postInformationVisible});

  // The visual representation of the ArtPostCard
  @override
  Widget build(BuildContext context) {
    Widget innerWidget;
    switch (post.type) {
      case MediaType.image:
        innerWidget =  ImageFeedWidget(post: post, postInformationVisible: postInformationVisible);
      case MediaType.video:
        innerWidget = VideoFeedWidget();
      case MediaType.audio:
        innerWidget = AudioFeedWidget(post: post, postInformationVisible: postInformationVisible);
      case MediaType.text:
        innerWidget = TextFeedWidget();
      default:
        return const Center(child: Text("Unsupported format"));
    }

    return innerWidget;
  }

}