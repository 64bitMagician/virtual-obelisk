import 'package:art_platform/core/constants.dart';
import 'package:art_platform/ui/widgets/media_reader_and_widgets/media_reader.dart';
import 'package:flutter/material.dart';

/// HomeScreen of the Platform
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MediaReader(mediaReaderConfiguration: MediaReaderConfiguration.HOME_FEED);
  }
}
