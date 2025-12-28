import 'package:flutter/material.dart';
import '../../data/models/art_post.dart';
import '../../data/repositories/mock_repository.dart';
import '../widgets/art_post_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MockRepository _repository = MockRepository();
  late Future<List<ArtPost>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = _repository.getFeedPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // We remove the AppBar here if you want the content to flow under a transparent header,
      // but keeping it is fine.
      appBar: AppBar(
        title: const Text("Discovery"),
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
        ],
      ),
      body: FutureBuilder<List<ArtPost>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final posts = snapshot.data!;

          // FIX: The ListView now takes up the FULL width of the screen.
          // This ensures that scrolling works no matter where your mouse is.
          return ListView.builder(
            // physics: AlwaysScrollableScrollPhysics(), // Optional: ensures scroll works even if list is short
            itemCount: posts.length,
            itemBuilder: (context, index) {
              // We constrain the width HERE, item by item.
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