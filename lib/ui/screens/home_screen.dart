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
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background makes art pop
      body: StreamBuilder<List<ArtPost>>(
        stream: _repository.getFeedPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No art found.", style: TextStyle(color: Colors.white)));
          }

          final posts = snapshot.data!;

          return Stack(
            children: [
              // 1. The Main Content: Full Screen PageView
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.horizontal, // Swipe gesture for mobile
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  return ArtPostCard(post: posts[index]);
                },
              ),

              // 2. Left Arrow (Web Only)
              Positioned(
                left: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _buildNavArrow(
                    icon: Icons.chevron_left,
                    onPressed: () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                  ),
                ),
              ),

              // 3. Right Arrow (Web Only)
              Positioned(
                right: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _buildNavArrow(
                    icon: Icons.chevron_right,
                    onPressed: () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavArrow({required IconData icon, required VoidCallback onPressed}) {
    // Only show arrows on larger screens (Web/Desktop)
    return LayoutBuilder(builder: (context, constraints) {
      return Opacity(
        opacity: 0.5, // Semi-transparent as requested
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black26,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 40),
            onPressed: onPressed,
          ),
        ),
      );
    });
  }
}