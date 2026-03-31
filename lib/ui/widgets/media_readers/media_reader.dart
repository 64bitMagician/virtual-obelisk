import 'dart:async';
import 'package:art_platform/ui/widgets/media_readers/media_navigator.dart';
import 'package:art_platform/ui/widgets/media_readers/post_info.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:art_platform/data/models/art_post.dart';
import 'package:art_platform/data/repositories/database_repository.dart';
import 'package:art_platform/ui/widgets/media/art_post_representation.dart';

/// HomeScreen of the Platform
class MediaReader extends StatefulWidget {
  const MediaReader({super.key});

  @override
  State<MediaReader> createState() => _ParentMediaReader();
}

class _ParentMediaReader extends State<MediaReader> {
  final DatabaseRepository _repository = DatabaseRepository(); // Firestore connection

  // Manages the content visible in PageView. Manages transition animations, etc...
  late final PageController _pageController;

  // This Stream represents the Feed Posts
  late final Stream<List<ArtPost>> _postsStream;

  bool _postInformationVisible = true; // starts of true
  Timer? _hideTimer;

  // the initial state of the HomeScreen Widget
  // We use it to configure stuff...
  void initState() {
    super.initState();
    _pageController = PageController();

    _postsStream = _repository.getHomeFeedPosts();

    _startHideTimer();
  }

  // used to set state of _postInformationVisible
  // When timer runs out, the fading transition effect takes place for data appearing above the content
  // Timer resets everytime this method is called. It also lasts 3 seconds.
  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _postInformationVisible) { // if data visible, and also exists in the tree
        setState(() => _postInformationVisible = false); // rebuild the HomeScreen widget with new state (ui==false)
      }
    });
  }

  // This method gets called when mouse has been moved within the HomeScreen Widget Area
  // If the UI info above the content of the post is invisible, we rebuild the widget with the new state,
  // making the UI info above content visible again
  // This method, resets the "mouse has been moved" timer, regardless of the state of the _postInformationVisible
  void _handleMouseMove(PointerEvent details) {
    if (!_postInformationVisible) {
      setState(() => _postInformationVisible = true);
    }
    // Mouse has been moved, so start timer again
    _startHideTimer();
  }

  // this is called when the object is permanently removed from the tree
  @override
  void dispose() {
    _pageController.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  // The visibal part of the widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: MouseRegion( // used to detect mouse activity within the region of it's child
        // The region is the whole region where the post is visible
        onHover: _handleMouseMove, // when mouse is moved within the region (not counted if stationary)
        child: StreamBuilder<List<ArtPost>>(
          stream: _postsStream, // the stream representing the feed posts
          builder: (context, snapshot) { // this retriggers everytime a new post arrives from stream
            if (snapshot.connectionState == ConnectionState.waiting) { // Loading Animation while fetching post list
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) { // if we have a list containing null, or empty list
              return const Center(
                child: Text(
                  "No art found.",
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            // if it's not fetching post, and we do actually retreived the list of posts,
            // we store it in this variable
            final posts = snapshot.data!;

            // Now we return (rebuild) with the new post fetched
            return Stack(
              children: [
                PageView.builder( // the tool that acts as a viewable collection of Widgets (ArtPostRepresentation Widgets in our case)
                  controller: _pageController, // the controller which controls the PageView Widget. Responsible for Page Navigation
                  // ammount of posts (does not build all of them, only the current one and maybe previous and next pages to prevent loading times)
                  // it also keeps previously loaded pages built (maybe there is a limit...)
                  itemCount: posts.length, // determine, the size of the
                  // itemBuilder rebuilds itself when the controller calls the methods to go back or forth from the current Page
                  // it only does this for pages that have not already been built
                  itemBuilder: (context, index) { // ? index sure is passed by the controller...?
                    return Stack(
                      children: [
                        // WIDGET: The actual Media Content
                        ArtPostRepresentation(
                          post: posts[index], // shows the post at the determined index
                          postInformationVisible: _postInformationVisible, // ArtPostRepresentation also has it's own implementation with _isUiVisible for animating the Post information Overlay
                        ),
                        // WIDGET: Information that sits on top of the post. Info about post...
                        PostInfo(post: posts[index], postInformationVisible: _postInformationVisible),
                      ]

                    );
                  },
                ),

                // WDIGET: Arrows that control navigation of PageView Widget
                MediaNavigator(isVisible: _postInformationVisible, pageController: _pageController, callStartHideTimer: _startHideTimer,)
              ],
            );
          },
        ),
      ),
    );
  }


}