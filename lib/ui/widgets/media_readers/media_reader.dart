import 'dart:async';
import 'package:art_platform/core/constants.dart';
import 'package:art_platform/ui/widgets/media_readers/media_navigator.dart';
import 'package:art_platform/ui/widgets/media_readers/post_info.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:art_platform/data/models/art_post.dart';
import 'package:art_platform/data/repositories/database_repository.dart';
import 'package:art_platform/ui/widgets/media/art_post_representation.dart';

import 'artpost_options_widget.dart';

/// [MediaReader] is required to have one of the three configurations available:
/// [MediaReaderConfiguration.HOME_FEED],[MediaReaderConfiguration.PROFILE_FEED] or [MediaReaderConfiguration.CATEGORY_FEED].
/// They are passed to the required [mediaReaderConfiguration] parameter...
///
/// Since it is an enum, only one configuration is possible at the time.
/// Depending on which Configuration you choose, there are additional parameters you need to fill.
/// Here is a list with each Configuration and what additional parameters in requires.
/// HOME_FEED: no additional parameters required.
/// PROFILE_FEED: [profilePostIndex] - determines the art asset that will be initially displayed. Very useful
/// when used in conjunction with a GridView, that can detect the index of objects interacted with user gestures.
/// This combination creates the behaviour of "you see what you clicked on..."
/// CATEGORY_FEED: [category] - it will configure [MediaReader] to fetch only ArtPost of the passed category.
///
/// There is also an optional parameter [exitButton]. If set to true, it will add an exit button that will redirect
/// the user to the previous page. If set to false or not set at all, the button simply won't show up.
class MediaReader extends StatefulWidget {
  final MediaReaderConfiguration mediaReaderConfiguration;
  final int profilePostIndex;
  final String? category;
  final bool? exitButton;
  final String? profileUid;

  const MediaReader({
    super.key,
    required this.mediaReaderConfiguration,
    this.exitButton,
    // the first post in the streamed list. Special case for Profile Screen, where you select the index through
    // tapping on a post from the Gallery of the Profile
    this.profilePostIndex = 0,
    this.category,
    // required to not be null if mediaReaderConfiguration == PROFILE_FEED
    this.profileUid,
  });

  @override
  State<MediaReader> createState() => _ParentMediaReader();
}

class _ParentMediaReader extends State<MediaReader> {
  final DatabaseRepository _repository = DatabaseRepository(); // Firestore connection

  // Manages the content visible in PageView. Manages transition animations, etc...
  late final PageController _pageController;

  // This Stream represents the Feed Posts
  late final Stream<List<ArtPost>> _postsStream;

  // determines visibilty for widgets on top of the post (Post Info, Navigation)
  bool _isVisible = true;
  Timer? _hideTimer;

  // the initial state of the HomeScreen Widget
  // We use it to configure stuff...
  void initState() {
    super.initState();
    // Configure it to start at received index from constructor
    _pageController = PageController(initialPage: widget.profilePostIndex);

    // Assign the right stream depending on MediaReader Configuration
    if (widget.mediaReaderConfiguration == MediaReaderConfiguration.HOME_FEED)
      _postsStream = _repository.getHomeFeedPosts();
    else if (widget.mediaReaderConfiguration == MediaReaderConfiguration.CATEGORY_FEED) {
      if (widget.category == null) throw Exception("MediaReader is configured for Category Feed. But at construction of MediaReader no value has been passed for category parameter...");

      _postsStream = _repository.getCategoryFeedPosts(category: widget.category!);
    } else if (widget.mediaReaderConfiguration == MediaReaderConfiguration.PROFILE_FEED) {
      if(widget.profileUid==null)
        throw Exception("ERROR: COULD NOT FETCH THE USER ID OF THE PROFILE YOU ARE TRYING TO ACCESS");

      _postsStream = _repository.getUserPosts(widget.profileUid!);
    }

    _startHideTimer();
  }

  // used to set state of _postInformationVisible
  // When timer runs out, the fading transition effect takes place for data appearing above the content
  // Timer resets everytime this method is called. It also lasts 3 seconds.
  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isVisible) {
        // if data visible, and also exists in the tree
        setState(() => _isVisible = false); // rebuild the HomeScreen widget with new state (ui==false)
      }
    });
  }

  // This method gets called when mouse has been moved within the HomeScreen Widget Area
  // If the UI info above the content of the post is invisible, we rebuild the widget with the new state,
  // making the UI info above content visible again
  // This method, resets the "mouse has been moved" timer, regardless of the state of the _postInformationVisible
  void _handleMouseMove(PointerEvent details) {
    if (!_isVisible) {
      setState(() => _isVisible = true);
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
      body: MouseRegion(
        // used to detect mouse activity within the region of it's child
        // The region is the whole region where the post is visible
        onHover: _handleMouseMove, // when mouse is moved within the region (not counted if stationary)
        child: StreamBuilder<List<ArtPost>>(
          stream: _postsStream, // the stream representing the feed posts
          builder: (context, snapshot) {
            // this retriggers everytime a new post arrives from stream
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Loading Animation while fetching post list
              return const Center(child: CircularProgressIndicator());
            }
            // Reveal the hidden Firebase error if there are any
            if (snapshot.hasError) {
              print("STREAM ERROR: ${snapshot.error}");
              return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)),
                  )
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              // if we have a list containing null, or empty list
              return const Center(child: Text("No art found.", style: TextStyle(color: Colors.white)));
            }

            // if it's not fetching post, and we do actually retreived the list of posts,
            // we store it in this variable
            final posts = snapshot.data!;

            // Now we return (rebuild) with the new post fetched
            return Stack(
              children: [
                PageView.builder(
                  // the tool that acts as a viewable collection of Widgets (ArtPostRepresentation Widgets in our case)
                  controller: _pageController, // the controller which controls the PageView Widget. Responsible for Page Navigation
                  // ammount of posts (does not build all of them, only the current one and maybe previous and next pages to prevent loading times)
                  // it also keeps previously loaded pages built (maybe there is a limit...)
                  itemCount: posts.length, // determine, the size of the
                  // itemBuilder rebuilds itself when the controller calls the methods to go back or forth from the current Page
                  // it only does this for pages that have not already been built
                  itemBuilder: (context, index) {
                    // ? index sure is passed by the controller...?
                    return Stack(
                      children: [
                        // WIDGET: The actual Media Content
                        ArtPostRepresentation(
                          post: posts[index], // shows the post at the determined index
                          postInformationVisible: _isVisible, // ArtPostRepresentation also has it's own implementation with _isUiVisible for animating the Post information Overlay
                          callStartHideTimer: _startHideTimer,
                        ),
                        // WIDGET: Information that sits on top of the post. Info about post...
                        PostInfo(post: posts[index], isVisible: _isVisible),
                        // WIDGET: The Three Dots Menu (Positioned Top Right)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: ArtPostOptions(
                            post: posts[index],
                            isVisible: _isVisible,
                            onUserInteracted: _startHideTimer, // Keeps UI visible if they click it
                          ),
                        ),
                      ],
                    );
                  },
                ),

                // WIDGET: Arrows that control navigation of PageView Widget + optional exit button
                MediaNavigator(isVisible: _isVisible, pageController: _pageController, callStartHideTimer: _startHideTimer, exitButton: widget.exitButton),
              ],
            );
          },
        ),
      ),
    );
  }
}
