import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/art_post.dart';
import '../widgets/art_post_card.dart';

class UserGalleryScreen extends StatefulWidget {
  final List<ArtPost> posts;
  final int initialIndex;

  const UserGalleryScreen({
    super.key,
    required this.posts,
    required this.initialIndex,
  });

  @override
  State<UserGalleryScreen> createState() => _UserGalleryScreenState();
}

class _UserGalleryScreenState extends State<UserGalleryScreen> {
  late final PageController _pageController;
  bool _isUiVisible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
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

  void _handleInteraction() {
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
        onHover: (_) => _handleInteraction(),
        child: GestureDetector(
          onTap: _handleInteraction,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: widget.posts.length,
                itemBuilder: (context, index) {
                  return ArtPostCard(
                    post: widget.posts[index],
                    isUiVisible: _isUiVisible,
                  );
                },
              ),

              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                top: _isUiVisible ? 40 : -60,
                left: 20,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 500),
                  opacity: _isUiVisible ? 1.0 : 0.0,
                  child: CircleAvatar(
                    backgroundColor: Colors.black45,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),

              _buildArrow(
                isLeft: true,
                onTap: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                ),
              ),
              _buildArrow(
                isLeft: false,
                onTap: () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArrow({required bool isLeft, required VoidCallback onTap}) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      left: isLeft ? (_isUiVisible ? 20 : -100) : null,
      right: !isLeft ? (_isUiVisible ? 20 : -100) : null,
      top: 0,
      bottom: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: _isUiVisible ? 0.5 : 0.0,
        child: Center(
          child: CircleAvatar(
            radius: 30,
            backgroundColor: Colors.black26,
            child: IconButton(
              icon: Icon(
                isLeft ? Icons.chevron_left : Icons.chevron_right,
                color: Colors.white,
                size: 40,
              ),
              onPressed: onTap,
            ),
          ),
        ),
      ),
    );
  }
}