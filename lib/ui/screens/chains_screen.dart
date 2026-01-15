import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChainsScreen extends StatelessWidget {
  const ChainsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Collaborative Chains"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildChainCard(
            context,
            id: '1',
            title: "The Red Planet",
            description: "Add your vision of Mars colonization.",
            contributors: 12,
          ),
          _buildChainCard(
            context,
            id: '2',
            title: "Cyberpunk 2099",
            description: "High tech, low life. Neon lights only.",
            contributors: 8,
          ),
          _buildChainCard(
            context,
            id: '3',
            title: "Abstract Dreams",
            description: "Colors, shapes, and feelings.",
            contributors: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildChainCard(
      BuildContext context, {
        required String id,
        required String title,
        required String description,
        required int contributors,
      }) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        margin: const EdgeInsets.only(bottom: 16),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.link, color: Colors.deepPurple),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(description),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.people, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text("$contributors contributors", style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              context.push('/chain/$id');
            },
          ),
        ),
      ),
    );
  }
}