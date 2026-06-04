import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:art_platform/data/models/art_chain.dart';
import 'package:art_platform/data/models/art_post.dart';
import 'package:art_platform/data/repositories/database_repository.dart';
import 'package:art_platform/core/constants.dart';
import 'package:art_platform/ui/widgets/upload_dialog.dart';
import '../widgets/media_readers/media_reader.dart';
import '../widgets/profile_screen_widgets/gallery_art_post.dart';



class ChainDetailScreen extends StatelessWidget {
  final String chainId;

  const ChainDetailScreen({super.key, required this.chainId});

  @override
  Widget build(BuildContext context) {
    final DatabaseRepository repo = DatabaseRepository();

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // Dark background matching your theme
      appBar: AppBar(
        title: const Text("Collaboration Details"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      // Fetch the Chain Details
      body: StreamBuilder<ArtChain>(
        stream: repo.getChainById(chainId),
        builder: (context, chainSnapshot) {
          if (chainSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!chainSnapshot.hasData) {
            return const Center(child: Text("Chain not found.", style: TextStyle(color: Colors.white)));
          }

          final chain = chainSnapshot.data!;

          // Fetch the ArtPosts assigned to this chain
          return StreamBuilder<List<ArtPost>>(
            stream: repo.getPostsForChain(chainId),
            builder: (context, postSnapshot) {
              final posts = postSnapshot.data ?? [];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER
                    Text(
                      chain.title,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      chain.description,
                      style: TextStyle(fontSize: 16, color: Colors.grey[400], height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: chain.isClosed ? Colors.grey.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: chain.isClosed ? Colors.grey : Colors.green),
                          ),
                          child: Text(
                            chain.isClosed ? "CLOSED" : "ACTIVE",
                            style: TextStyle(
                              color: chain.isClosed ? Colors.grey : Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 24),

                    // TIMELINE
                    ...List.generate(chain.categoryNodes.length, (index) {
                      final categoryKey = chain.categoryNodes[index];
                      final categoryName = artCategoriesDisplayName[categoryKey] ?? categoryKey.toUpperCase();

                      // Filter the posts that belong to this specific node category
                      final nodePosts = posts.where((p) => p.category == categoryKey).toList();

                      return _buildTimelineNode(
                        context: context,
                        chainId: chain.id,
                        categoryKey: categoryKey,
                        categoryName: categoryName,
                        posts: nodePosts,
                        isLast: index == chain.categoryNodes.length - 1,
                        isClosed: chain.isClosed,
                      );
                    }),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Visual widget for each step/category in the chain
  Widget _buildTimelineNode({
    required BuildContext context,
    required String chainId,
    required String categoryKey,
    required String categoryName,
    required List<ArtPost> posts,
    required bool isLast,
    required bool isClosed,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: The timeline line and dynamic action dot
          Column(
            children: [
              _buildTimelineAvatar(context, chainId, categoryKey, isClosed, posts.isNotEmpty),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.white12,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                  ),
                )
            ],
          ),
          const SizedBox(width: 16),

          // Right side: The content box
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 32),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryName.toUpperCase(),
                    style: const TextStyle(color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Gallery of uploaded content or empty state
                  if (posts.isEmpty)
                    const Text("Waiting for artists to contribute...", style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic))
                  else
                    SizedBox(
                      height: 120,
                      // ScrollConfiguration enables Mouse Dragging on Desktop/Web
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad},
                        ),
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: posts.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, i) {
                            final post = posts[i];
                            return SizedBox(
                              width: 120,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: InkWell(
                                  // OPEN THE MEDIA READER
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MediaReader(
                                          mediaReaderConfiguration: MediaReaderConfiguration.CHAIN_NODE_FEED,
                                          chainId: chainId,
                                          category: categoryKey,
                                          profilePostIndex: i, // Starts the reader at the exact post they clicked
                                          exitButton: true,
                                        ),
                                      ),
                                    );
                                  },
                                  child: GalleryArtPost(post: post),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // TIMELINE AVATAR
  Widget _buildTimelineAvatar(BuildContext context, String chainId, String categoryKey, bool isClosed, bool hasPosts) {
    // If the chain is closed, show a checkmark (if filled) or a lock (if empty).
    if (isClosed) {
      return CircleAvatar(
        backgroundColor: hasPosts ? Colors.deepPurpleAccent : Colors.white12,
        child: Icon(
          hasPosts ? Icons.check : Icons.lock_outline,
          color: hasPosts ? Colors.white : Colors.white54,
        ),
      );
    }
    // If the chain is open, always show a clickable Plus button
    else {
      return InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => UploadDialog(
              chainId: chainId,
              allowedCategories: [categoryKey], //RESTRICTS UPLOAD TO EXACTLY THIS CATEGORY
            ),
          );
        },
        child: const CircleAvatar(
          backgroundColor: Colors.deepPurpleAccent,
          child: Icon(Icons.add, color: Colors.white),
        ),
      );
    }
  }
}