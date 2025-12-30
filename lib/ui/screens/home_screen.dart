import 'package:flutter/material.dart';
import '../../data/models/art_post.dart';
import '../../data/repositories/database_repository.dart'; // <--- Use Real Repo
import '../widgets/art_post_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 1. Initialize the Real Database Repository
  final DatabaseRepository _repository = DatabaseRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Discovery"),
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
        ],
      ),
      // 2. Switch to StreamBuilder for Real-Time updates
      body: StreamBuilder<List<ArtPost>>(
        stream: _repository.getFeedPosts(), // Listen to the stream
        builder: (context, snapshot) {
          // A. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // B. Error State
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // C. Empty State
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No art yet. Be the first to post!"),
                ],
              ),
            );
          }

          // D. Data Loaded
          final posts = snapshot.data!;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: ArtPostCard(post: posts[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}