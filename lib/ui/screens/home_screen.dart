import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../data/models/art_post.dart';
import '../../data/repositories/database_repository.dart';
import '../widgets/art_post_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseRepository _repository = DatabaseRepository();

  late final PageController _pageController;

  // This variable holds the stream so it stays "alive" during rebuilds
  late final Stream<List<ArtPost>> _postsStream;

  bool _isUiVisible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Initialize the stream here once.
    // Calling this in 'build' is what caused the reset.
    _postsStream = _repository.getFeedPosts();

    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isUiVisible) {
        setState(() => _isUiVisible = false);
      }
    });
  }

  void _handleMouseMove(PointerEvent details) {
    if (!_isUiVisible) {
      setState(() => _isUiVisible = true);
    }
    _startHideTimer();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: MouseRegion(
        onHover: _handleMouseMove,
        onEnter: (_) => _handleMouseMove(const PointerHoverEvent()),
        child: StreamBuilder<List<ArtPost>>(
          // Use the stable stream variable
          stream: _postsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  "No art found.",
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            final posts = snapshot.data!;

            return Stack(
              children: [
                // 1. THE ARTWORK LAYER
                PageView.builder(
                  controller: _pageController,
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    return ArtPostCard(
                      post: posts[index],
                      isUiVisible: _isUiVisible,
                    );
                  },
                ),

                // 2. LEFT NAVIGATION ARROW
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 600),
                  left: _isUiVisible ? 20 : -100, // Slides out of view
                  top: 0,
                  bottom: 0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 600),
                    opacity: _isUiVisible ? 0.6 : 0.0,
                    child: Center(
                      child: _buildNavButton(
                        Icons.chevron_left,
                            () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. RIGHT NAVIGATION ARROW
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 600),
                  right: _isUiVisible ? 20 : -100, // Slides out of view
                  top: 0,
                  bottom: 0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 600),
                    opacity: _isUiVisible ? 0.6 : 0.0,
                    child: Center(
                      child: _buildNavButton(
                        Icons.chevron_right,
                            () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black45,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 48),
        onPressed: onTap,
      ),
    );
  }
}