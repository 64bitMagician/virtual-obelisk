import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:art_platform/data/models/art_chain.dart';
import 'package:art_platform/data/repositories/database_repository.dart';
import 'package:art_platform/core/constants.dart';

class ChainsScreen extends StatelessWidget {
  const ChainsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseRepository repo = DatabaseRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Community Chains"),
        backgroundColor: Colors.deepPurple[900],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<ArtChain>>(
        stream: repo.getAllChains(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final chains = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chains.length,
            itemBuilder: (context, index) {
              final chain = chains[index];
              return _buildChainCard(context, chain);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.link_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "No active chains right now.",
            style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text("Check back later for new community prompts", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildChainCard(BuildContext context, ArtChain chain) {
    final int daysLeft = chain.expiresAt.difference(DateTime.now()).inDays;
    final String timeText = chain.isClosed
        ? "Closed"
        : (daysLeft > 0 ? "$daysLeft days left" : "Ends today!");

    final Color badgeColor = chain.isClosed ? Colors.grey : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/chains/${chain.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      chain.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: badgeColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(chain.isClosed ? Icons.lock : Icons.timer, size: 14, color: badgeColor),
                        const SizedBox(width: 4),
                        Text(
                          timeText,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: badgeColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Text(
                chain.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[700], height: 1.4),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              const Text("Required Sequence:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: _buildSequenceChips(chain.categoryNodes),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSequenceChips(List<String> nodes) {
    List<Widget> widgets = [];
    for (int i = 0; i < nodes.length; i++) {
      final categoryKey = nodes[i];
      final displayName = artCategoriesDisplayName[categoryKey] ?? categoryKey;

      widgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.deepPurple.shade200),
          ),
          child: Text(
            displayName,
            style: TextStyle(fontSize: 12, color: Colors.deepPurple.shade900, fontWeight: FontWeight.w600),
          ),
        ),
      );

      if (i < nodes.length - 1) {
        widgets.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.0),
          child: Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
        ));
      }
    }
    return widgets;
  }
}