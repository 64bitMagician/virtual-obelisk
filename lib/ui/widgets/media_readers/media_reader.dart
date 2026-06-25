import 'dart:async';
import 'package:art_platform/core/constants.dart';
import 'package:art_platform/ui/widgets/media_readers/media_navigator.dart';
import 'package:art_platform/ui/widgets/media_readers/post_info.dart';
import 'package:flutter/material.dart';
import 'package:art_platform/data/models/art_post.dart';
import 'package:art_platform/data/repositories/database_repository.dart';
import 'package:art_platform/ui/widgets/media/art_post_representation.dart';
import 'admin_report_overlay.dart';
import 'art_post_like_button.dart';
import 'artpost_options_widget.dart';
import 'package:art_platform/core/feed_engine.dart';

/// [MediaReader] is required to have one of the five configurations available:
/// [MediaReaderConfiguration.HOME_FEED],[MediaReaderConfiguration.PROFILE_FEED], [MediaReaderConfiguration.CATEGORY_FEED]
/// , [MediaReaderConfiguration.CHAIN_NODE_FEED] or [MediaReaderConfiguration.REPORTED_ARTPOSTS_FEED].
/// They are passed to the required [mediaReaderConfiguration] parameter...
///
/// Since it is an enum, only one configuration is possible at a time.
/// Depending on which Configuration you choose, there are additional parameters you need to fill.
/// Here is a list with each Configuration and what additional parameters in requires.
/// HOME_FEED: no additional parameters required.
/// PROFILE_FEED: [profilePostIndex] - determines the art asset that will be initially displayed. Very useful
/// when used in conjunction with a GridView, that can detect the index of objects interacted with user gestures.
/// This combination creates the behaviour of "you see what you clicked on..."
/// CATEGORY_FEED: [category] - it will configure [MediaReader] to fetch only ArtPost of the passed category.
/// CHAIN_NODE_FEED: ...
/// REPORTED_ARTPOSTS_FEED: ...
///
/// There is also an optional parameter [exitButton]. If set to true, it will add an exit button that will redirect
/// the user to the previous page. If set to false or not set at all, the button simply won't show up.
class MediaReader extends StatefulWidget {
  final MediaReaderConfiguration mediaReaderConfiguration;
  /// the first post in the streamed list. Special case for Profile Screen, where you select the index through
  /// tapping on a post from the Gallery of the Profile
  final int profilePostIndex;
  final String? category;
  final bool? exitButton;
  /// required to not be null if mediaReaderConfiguration == PROFILE_FEED
  final String? profileUid;
  final String? chainId;

  const MediaReader({
    super.key,
    required this.mediaReaderConfiguration,
    this.exitButton,
    this.profilePostIndex = 0,
    this.category,
    this.profileUid,
    this.chainId,
  });

  @override
  State<MediaReader> createState() => _MediaReaderState();
}

class _MediaReaderState extends State<MediaReader> {
  final DatabaseRepository _repository = DatabaseRepository();

  /// Manages the content visible in PageView. Manages transition animations, etc...
  late final PageController _pageController;

  /// list of [ArtPost] instances that are loaded for diplay in [MediaReader]
  List<ArtPost> _posts = [];

  /// variable to mark if we are currently loading artworks for displaying. Used for all MediaReader Configurations, not just the Stream ones.
  bool _isLoading = true;
  /// variable to mark that we are currently, in this moment, fetching artposts through the feed algorithm (only for HOME/CATEGORY FEED CONFIGURATION)
  bool _currentlyFetchingMore = false;
  /// variable to mark if we ran out of artworks to display (only for HOME/CATEGORY FEED CONFIGURATION)
  bool _hasReachedEnd = false;
  /// If any errors happen, we store them in this _error variable
  String? _error;
  /// The stream we have subscribed to listen to. Any data changes or errors in the stream will fire back and can be catched with the .listen() method
  StreamSubscription<List<ArtPost>>? _streamSubscription;
  /// in case HOME/CATEGORY FEED CONFIGURATION is active, we rely on the feed algorithm, thus need to have [FeedEngine] instantiated to fetch artposts
  FeedEngine? _feedEngine;

  // determines visibility for widgets on top of the post (Post Info, Navigation)
  bool _isVisible = true;
  // timer for when to hide the widgets on top of the post
  Timer? _hideTimer;

  // the initial state of the HomeScreen Widget
  // We use it to configure stuff...
  void initState() {
    super.initState();
    // Configure it to start at received index from constructor
    _pageController = PageController(initialPage: widget.profilePostIndex);

    // Assign the right feed depending on MediaReader Configuration
    if (widget.mediaReaderConfiguration == MediaReaderConfiguration.HOME_FEED ||
        widget.mediaReaderConfiguration == MediaReaderConfiguration.CATEGORY_FEED) {
      // These two configurations worh with the Feed Algorithm, in Batches of Future objects. It does not work on Streams

      // If CATEGORY_FEED configuration is selected, the category must also be provided
      if (widget.mediaReaderConfiguration == MediaReaderConfiguration.CATEGORY_FEED && widget.category == null) {
        throw Exception("MediaReader is configured for Category Feed. But at construction of MediaReader, no value has been passed for category parameter...");
      }

      // Otherwise, if HOME_FEED configuration is selected, category must be null
      if (widget.mediaReaderConfiguration == MediaReaderConfiguration.HOME_FEED && widget.category != null) {
        throw Exception("MediaReader is configured for Home Feed. But at construction of MediaReader, a category has been provided, which is not allowed for Home Feed Configuration");
      }

      // If everything is good, instiantiate the feed engine
      _feedEngine = FeedEngine();
      // and initiate the loading of the next batch of artposts
      _loadMoreFeed();
    } else { // these feeds do not work based on the Algorithm and do not use Batches of Future objects, rather Streams
      Stream<List<ArtPost>> stream; // declare stream

      // IF PROFILE_FEED CONFIGURATION => Configure stream to return posts of given [widget.profileUid] user
      if (widget.mediaReaderConfiguration == MediaReaderConfiguration.PROFILE_FEED) {
        if (widget.profileUid == null) throw Exception("ERROR: COULD NOT FETCH THE USER ID OF THE PROFILE YOU ARE TRYING TO ACCESS");
        stream = _repository.getUserPosts(widget.profileUid!);
      }
      // IF REPORTED_ARTPOSTS_FEED CONFIGURATION => Configure stream to return all deactivated artworks
      else if (widget.mediaReaderConfiguration == MediaReaderConfiguration.REPORTED_ARTPOSTS_FEED){
        stream = _repository.getDeactivatedPosts();
      }
      // // IF CHAIN_NODE_FEED CONFIGURATION => Configure stream to return all artposts for the given node (category), in the given chain
      else if (widget.mediaReaderConfiguration == MediaReaderConfiguration.CHAIN_NODE_FEED) {
        // [chainId] and [category] must be provided
        if (widget.chainId == null || widget.category == null) throw Exception("Chain ID or Category is missing.");
        stream = _repository.getChainNodePosts(chainId: widget.chainId!, category: widget.category!);
      } else {
        throw Exception("Unknown MediaReaderConfiguration");
      }

      // we fetch the data from the configured stream (fetch List<ArtPost> data)
      _streamSubscription = stream.listen((data) {
        // if MediaReader is in the Widget Tree
        if (mounted) {
          setState(() {
            _posts = data; // store the fetched artposts into our local list we use to display the posts
            _isLoading = false; // the posts have been loaded
          });
        }
      }, onError: (err) { // if an error has occured while listening to the stream
        // if MediaReader is in the Widget Tree
        if (mounted) {
          setState(() {
            // store the received error in our local variable
            _error = err.toString();
            _isLoading = false; // we are no more trying to load
          });
        }
      });
    }

    // we can start the hide timer once the MediaReader hits the scene
    _startHideTimer();
  }


  Future<void> _loadMoreFeed() async {
    // of _feedEngine has not been instantiated
    // or if we are are already _currentlyFetchingMore artposts (the process is already undergoing) (or something wrong is happening)
    // or if _hasReachedEnd => we can no longer fetch any artposts for the given category (may be null for HOME_FEED CONFIGURATION)
    if (_feedEngine == null || _currentlyFetchingMore || _hasReachedEnd) return;

    // if media reader is still in widget tree => we mark that we are currently fetching more
    if (mounted) {
      setState(() => _currentlyFetchingMore = true);
    }

    try {
      // fetch a generated feed batch for the given category
      // if category is null, it fetches from all existing artposts (for HOME_FEED CONFIGURATION)
      final newPosts = await Future.delayed(
          const Duration(seconds: 0),
              () => _feedEngine!.generateFeedBatch(category: widget.category)
      );

      // if meadia reader still in the widget tree
      if (mounted) {
        setState(() {
          // if no more posts were provided, it means we ran out of artposts to display
          if (newPosts == null || newPosts.isEmpty) {
            _hasReachedEnd = true; // mark that we reached end
          } else { // but if we can still display stuff
            _posts.addAll(newPosts); // add the fetched posts to the _posts that are to be displayed
          }
          // finished adding the posts (or received no posts)
          // so we mark that we are not fetching anymore
          _currentlyFetchingMore = false;
          // also mark we are no longer loading artposts
          _isLoading = false;
        });
      }
    } catch (e) { // if any errors occur
      // If MediaReader still in the widget tree
      if (mounted) {
        setState(() {
          // store the error in our local variable
          _error = e.toString();
          // we are not longer currentlyFetchingMore artposts from the algorithm
          _currentlyFetchingMore = false;
          // we are not longer loading, we stopped
          _isLoading = false;
        });
      }
    }
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
    _streamSubscription?.cancel();
    super.dispose();
  }

  // The visual part of the widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: MouseRegion(
        // used to detect mouse activity within the region of it's child
        // The region is the whole region where the post is visible
        onHover: _handleMouseMove, // when mouse is moved within the region (not counted if stationary)
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    // If no artposts have been loaded so far, and we also have to marker to load
    if (_isLoading && _posts.isEmpty) {
      // Loading Animation while fetching post list
      return const Center(child: CircularProgressIndicator());
    }

    // Reveal the hidden Firebase error if there are any
    if (_error != null) {
      print("STREAM/FUTURE ERROR: $_error");
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text("Error: $_error", style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    // _hasReachedEnd only is true for HOME/CATEGORY FEEDS:
    // if there are no loaded posts and we were not able to fetch any
    if (_posts.isEmpty && _hasReachedEnd) {
      // If the MediaReader was configured for CATEGORY_FEED => Display Custom Message
      if (widget.mediaReaderConfiguration == MediaReaderConfiguration.CATEGORY_FEED) {
        return const Center(
          child: Text(
            "No artpost of this category exists yet",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        );
      } else {
        // For any other MediaReader Configurations that rely on the Feed Algorithm
        return const Center(
          child: Text(
            "No art found yet. Be the first to upload.",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        );
      }
    }

    // For Streams: if no posts were loaded
    if (_posts.isEmpty) {
      // if we have a list containing null, or empty list
      return const Center(child: Text("No art found.", style: TextStyle(color: Colors.white)));
    }

    // But if we have loaded _posts, we can return them:
    return Stack(
      children: [
        PageView.builder(
          // the tool that acts as a viewable collection of Widgets (ArtPostRepresentation Widgets in our case)
          controller: _pageController, // the controller which controls the PageView Widget. Responsible for Page Navigation
          // ammount of posts (does not build all of them, only the current one and maybe previous and next pages to prevent loading times)
          // it also keeps previously loaded pages built (maybe there is a limit...)

          // Determine the size. Add 1 extra slot if we are fetching or if we reached the end (only applies for configurations that rely on feed algorithm)
          itemCount: _posts.length + ((_currentlyFetchingMore || _hasReachedEnd) ? 1 : 0),

          onPageChanged: (index) {
            // if page changed, reset the hide timer, mark that the ui should stay visible
            if (!_isVisible) {
              setState(() => _isVisible = true);
            }
            _startHideTimer();

            // If we on HOME/CATEGORY FEED, when we are 2 artposts away from end of loaded posts, start loading the next batch to save time
            if (widget.mediaReaderConfiguration == MediaReaderConfiguration.HOME_FEED ||
                widget.mediaReaderConfiguration == MediaReaderConfiguration.CATEGORY_FEED) {
              if (index >= _posts.length - 2) {
                _loadMoreFeed();
              }
            }
          },
          // itemBuilder rebuilds itself when the controller calls the methods to go back or forth from the current Page
          // it only does this for pages that have not already been built
          itemBuilder: (context, index) {
            // ? index sure is passed by the controller...?

            // Check if this is the "Extra Slot" at the end of the feed => Display that we are either fetching for more artposts/ or we reached the end of loaded artposts
            if (index == _posts.length) {
              if (_hasReachedEnd) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        "You've seen all latest active artists",
                        style: TextStyle(color: Colors.white70, fontSize: 16, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                );
              } else if (_currentlyFetchingMore) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.deepPurpleAccent),
                      SizedBox(height: 16),
                      Text(
                        "Fetching more artworks...",
                        style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                );
              }
            }

            return Stack(
              children: [
                // WIDGET: The actual Media Content
                ArtPostRepresentation(
                  post: _posts[index], // shows the post at the determined index
                  postInformationVisible: _isVisible, // ArtPostRepresentation also has it's own implementation with _isUiVisible for animating the Post information Overlay
                  callStartHideTimer: _startHideTimer,
                ),
                // WIDGET: Information that sits on top of the post. Info about post...
                PostInfo(post: _posts[index], isVisible: _isVisible),
                // WIDGET: The Three Dots Menu (Positioned Top Right)
                Positioned(
                  top: 16,
                  left: 16,
                  child: ArtPostOptions(
                    post: _posts[index],
                    isVisible: _isVisible,
                    onUserInteracted: _startHideTimer, // Keeps UI visible if they click it
                  ),
                ),

                // The Like Button (Positioned Below Options)
                Positioned(
                  bottom: 16, // Sits comfortably below the three dots
                  right: 16,
                  child: ArtPostLikeButton(
                    post: _posts[index],
                    isVisible: _isVisible,
                    onUserInteracted: _startHideTimer,
                  ),
                ),

                // The Admin Report Panel
                // It only renders if we are in the Moderation Queue (ADMIN DASHBOARD -> REPORT FEED SECTION)
                if (widget.mediaReaderConfiguration == MediaReaderConfiguration.REPORTED_ARTPOSTS_FEED)
                  Positioned(
                    top: 80,
                    right: 16,
                    bottom: 100,
                    child: AdminReportOverlay(
                      artworkId: _posts[index].id,
                      isVisible: _isVisible,
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
  }
}