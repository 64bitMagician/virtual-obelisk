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
  final String? chainId;

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
    this.chainId,
  });

  @override
  State<MediaReader> createState() => _MediaReaderState();
}

class _MediaReaderState extends State<MediaReader> {
  final DatabaseRepository _repository = DatabaseRepository();

  // Manages the content visible in PageView. Manages transition animations, etc...
  late final PageController _pageController;

  List<ArtPost> _posts = [];
  bool _isLoading = true;
  bool _isFetchingMore = false; // Tracks if we are fetching the next batch
  bool _hasReachedEnd = false;  // Tracks if the Feed Engine ran out of unseen posts
  String? _error;
  StreamSubscription<List<ArtPost>>? _streamSubscription;
  FeedEngine? _feedEngine;

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
    if (widget.mediaReaderConfiguration == MediaReaderConfiguration.HOME_FEED) {
      _feedEngine = FeedEngine();
      _loadMoreHomeFeed();
    } else {
      Stream<List<ArtPost>> stream;

      if (widget.mediaReaderConfiguration == MediaReaderConfiguration.CATEGORY_FEED) {
        if (widget.category == null) throw Exception("MediaReader is configured for Category Feed. But at construction of MediaReader no value has been passed for category parameter...");
        stream = _repository.getCategoryFeedPosts(category: widget.category!);
      } else if (widget.mediaReaderConfiguration == MediaReaderConfiguration.PROFILE_FEED) {
        if (widget.profileUid == null) throw Exception("ERROR: COULD NOT FETCH THE USER ID OF THE PROFILE YOU ARE TRYING TO ACCESS");
        stream = _repository.getUserPosts(widget.profileUid!);
      } else if (widget.mediaReaderConfiguration == MediaReaderConfiguration.REPORTED_ARTPOSTS_FEED) {
        stream = _repository.getDeactivatedPosts();
      } else if (widget.mediaReaderConfiguration == MediaReaderConfiguration.CHAIN_NODE_FEED) {
        if (widget.chainId == null || widget.category == null) throw Exception("Chain ID or Category is missing.");
        stream = _repository.getChainNodePosts(chainId: widget.chainId!, category: widget.category!);
      } else {
        throw Exception("Unknown MediaReaderConfiguration");
      }

      _streamSubscription = stream.listen((data) {
        if (mounted) {
          setState(() {
            _posts = data;
            _isLoading = false;
          });
        }
      }, onError: (err) {
        if (mounted) {
          setState(() {
            _error = err.toString();
            _isLoading = false;
          });
        }
      });
    }

    _startHideTimer();
  }

  Future<void> _loadMoreHomeFeed() async {
    // Prevent fetching if already fetching or if we know we hit the end
    if (_feedEngine == null || _isFetchingMore || _hasReachedEnd) return;

    if (mounted) {
      setState(() => _isFetchingMore = true);
    }

    try {
      // Add a small artificial delay so the UI doesn't flash too quickly if the DB is fast
      final newPosts = await Future.delayed(
          const Duration(seconds: 1),
              () => _feedEngine!.generateFeedBatch()
      );

      if (mounted) {
        setState(() {
          // If the engine returns null or empty, we've seen everything!
          if (newPosts == null || newPosts.isEmpty) {
            _hasReachedEnd = true;
          } else {
            _posts.addAll(newPosts);
          }
          _isFetchingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isFetchingMore = false;
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

  // The visibal part of the widget
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

    if (_posts.isEmpty && _hasReachedEnd) {
      return const Center(
          child: Text(
              "You've seen all the artworks that have been uploaded! 🎉",
              style: TextStyle(color: Colors.white, fontSize: 16)
          )
      );
    }

    if (_posts.isEmpty) {
      // if we have a list containing null, or empty list
      return const Center(child: Text("No art found.", style: TextStyle(color: Colors.white)));
    }

    // Now we return (rebuild) with the new post fetched
    return Stack(
      children: [
        PageView.builder(
          // the tool that acts as a viewable collection of Widgets (ArtPostRepresentation Widgets in our case)
          controller: _pageController, // the controller which controls the PageView Widget. Responsible for Page Navigation
          // ammount of posts (does not build all of them, only the current one and maybe previous and next pages to prevent loading times)
          // it also keeps previously loaded pages built (maybe there is a limit...)

          // Determine the size. Add 1 extra slot if we are fetching OR if we reached the end
          itemCount: _posts.length + ((_isFetchingMore || _hasReachedEnd) ? 1 : 0),

          onPageChanged: (index) {
            // User interacted. Make sure UI is visible and reset the timer.
            if (!_isVisible) {
              setState(() => _isVisible = true);
            }
            _startHideTimer();

            // Your existing infinite scroll logic
            if (widget.mediaReaderConfiguration == MediaReaderConfiguration.HOME_FEED) {
              if (index >= _posts.length - 2) {
                _loadMoreHomeFeed();
              }
            }
          },
          // itemBuilder rebuilds itself when the controller calls the methods to go back or forth from the current Page
          // it only does this for pages that have not already been built
          itemBuilder: (context, index) {
            // ? index sure is passed by the controller...?

            // Check if this is the "Extra Slot" at the end of the feed
            if (index == _posts.length) {
              if (_hasReachedEnd) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        "You've seen all the artworks that have been uploaded!",
                        style: TextStyle(color: Colors.white70, fontSize: 16, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                );
              } else if (_isFetchingMore) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.deepPurpleAccent),
                      SizedBox(height: 16),
                      Text(
                        "Curating your next masterpieces...",
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

                // The Admin Report Panel (Positioned on the Right)
                // It ONLY renders if we are in the Moderation Queue (ADMIN DASHBOARD -> REPORT FEED SECTION)
                if (widget.mediaReaderConfiguration == MediaReaderConfiguration.REPORTED_ARTPOSTS_FEED)
                  Positioned(
                    top: 80, // Placed below the top UI buttons
                    right: 16, // Snug against the right edge
                    bottom: 100, // Leaves room so it doesn't cover PostInfo
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