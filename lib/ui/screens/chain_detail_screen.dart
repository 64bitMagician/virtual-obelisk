import 'package:flutter/material.dart';
import 'package:art_platform/data/models/art_chain.dart';
import 'package:art_platform/data/models/art_post.dart';
import 'package:art_platform/data/repositories/database_repository.dart';
import 'package:art_platform/core/constants.dart';
import 'package:art_platform/ui/widgets/upload_dialog.dart';

class ChainDetailScreen extends StatelessWidget {
  final String chainId;

  const ChainDetailScreen({super.key, required this.chainId});

  @override
  Widget build(BuildContext context) {
    final DatabaseRepository repo = DatabaseRepository();

    return Scaffold(
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

              return Stack(
                children: [
                  SingleChildScrollView(
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
                            stepNumber: index + 1,
                            categoryName: categoryName,
                            posts: nodePosts,
                            isLast: index == chain.categoryNodes.length - 1,
                          );
                        }),

                        const SizedBox(height: 100), // Spacing for the floating button
                      ],
                    ),
                  ),

                  // FLOATING JOIN BUTTON
                  if (!chain.isClosed)
                    Positioned(
                      bottom: 24,
                      left: 24,
                      right: 24,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          // Open the Upload Dialog and pass the chainId and the allowed categories
                          showDialog(
                            context: context,
                            builder: (context) => UploadDialog(
                              chainId: chain.id,
                              allowedCategories: chain.categoryNodes,
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text("Join this Chain", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    )
                ],
              );
            },
          );
        },
      ),
    );
  }

  // Visual widget for each step in the chain
  Widget _buildTimelineNode({
    required int stepNumber,
    required String categoryName,
    required List<ArtPost> posts,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: The timeline line and dot
          Column(
            children: [
              CircleAvatar(
                backgroundColor: posts.isNotEmpty ? Colors.deepPurpleAccent : Colors.white12,
                child: Icon(
                  posts.isNotEmpty ? Icons.check : Icons.lock_outline,
                  color: posts.isNotEmpty ? Colors.white : Colors.white54,
                ),
              ),
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
                    "Step $stepNumber: ${categoryName.toUpperCase()}",
                    style: const TextStyle(color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Gallery of uploaded content or empty state
                  if (posts.isEmpty)
                    const Text("Waiting for an artist to fill this slot...", style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic))
                  else
                    SizedBox(
                      height: 120, // Height for the horizontal scrolling gallery
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: posts.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final post = posts[i];
                          return Container(
                            width: 120,
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(8),
                              image: post.mediaType.name == 'image' && post.mediaUrl.isNotEmpty
                                  ? DecorationImage(image: NetworkImage(post.mediaUrl), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: post.mediaType.name != 'image'
                                ? Center(child: Text(post.title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12)))
                                : null,
                          );
                        },
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
}