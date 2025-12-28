import 'package:flutter/material.dart';
import '../../data/models/art_post.dart';

class ArtPostCard extends StatelessWidget {
  final ArtPost post;

  const ArtPostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      elevation: 4, // Adds a subtle shadow
      clipBehavior: Clip.antiAlias, // Ensures image doesn't bleed outside corners
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Artist Info
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(post.artistAvatarUrl),
            ),
            title: Text(post.artistName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(post.artistRank, style: TextStyle(color: Colors.purple.shade300)),
            trailing: post.isChain
                ? const Chip(label: Text("Chain"), backgroundColor: Colors.teal, labelStyle: TextStyle(fontSize: 10))
                : const Icon(Icons.more_vert),
          ),

          // 2. The Art (Image)
          // We use a constrained box to ensure images don't get too tall on web
          Container(
            constraints: const BoxConstraints(maxHeight: 500),
            width: double.infinity,
            child: Image.network(
              post.contentUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 300,
                  color: Colors.black12,
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ),

          // 3. Action Buttons (Like, Comment)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
                Text('${post.likes}'),
                const SizedBox(width: 16),
                IconButton(icon: const Icon(Icons.comment_outlined), onPressed: () {}),
                const Spacer(),
                IconButton(icon: const Icon(Icons.share), onPressed: () {}),
              ],
            ),
          ),

          // 4. Description
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(post.description, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}