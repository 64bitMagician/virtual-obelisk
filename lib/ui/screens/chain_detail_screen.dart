import 'package:flutter/material.dart';

class ChainDetailScreen extends StatelessWidget {
  final String chainId;

  const ChainDetailScreen({super.key, required this.chainId});

  @override
  Widget build(BuildContext context) {
    // 1. Static Data Setup (Since backend isn't ready)
    final String title = chainId == '1' ? "The Red Planet" : "Chain #$chainId";
    final String status = "Active";
    final String initiator = "Vlad (Alpha)";

    return Scaffold(
      appBar: AppBar(title: const Text("Collaboration Details")),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Header Section
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const CircleAvatar(radius: 12, child: Icon(Icons.person, size: 12)),
                    const SizedBox(width: 8),
                    Text("Initiated by $initiator", style: const TextStyle(color: Colors.grey)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    )
                  ],
                ),
                const Divider(height: 40),

                // 3. The Art Steps (Static List)
                ListView(
                  shrinkWrap: true, // Important inside SingleChildScrollView
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStepDisplay(
                      stepNumber: 1,
                      type: "text",
                      author: "Vlad",
                      content: "The year is 2042. The dust storms on Mars never seem to end...",
                      isCompleted: true,
                    ),
                    _buildConnector(),
                    _buildStepDisplay(
                      stepNumber: 2,
                      type: "image",
                      author: "Elena",
                      content: "https://images.unsplash.com/photo-1614728853970-c8f2b42332b0?q=80&w=1000&auto=format&fit=crop",
                      isCompleted: true,
                    ),
                    _buildConnector(),
                    _buildStepDisplay(
                      stepNumber: 3,
                      type: "audio",
                      author: null,
                      content: "",
                      isCompleted: false, // Locked step
                    ),
                  ],
                ),

                // 4. Footer / Action
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Participation is coming soon!")),
                      );
                    },
                    icon: const Icon(Icons.brush),
                    label: const Text("Join this Chain"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Visual line connecting the art pieces
  Widget _buildConnector() {
    return Container(
      height: 40,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 24), // Align with the circle
      child: Container(
        width: 2,
        color: Colors.grey.withOpacity(0.5),
      ),
    );
  }

  Widget _buildStepDisplay({
    required int stepNumber,
    required String type,
    required String? author,
    required String content,
    required bool isCompleted,
  }) {
    bool isLocked = !isCompleted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A. Number Badge
        Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isLocked ? Colors.grey.shade800 : Colors.deepPurple,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white12, width: 2),
              ),
              child: Center(
                child: isLocked
                    ? const Icon(Icons.lock_outline, color: Colors.white54)
                    : Icon(_getIconForType(type), color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(width: 20),

        // B. Content Card
        Expanded(
          child: Card(
            elevation: isLocked ? 0 : 4,
            color: isLocked ? Colors.grey.withOpacity(0.1) : null,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Step $stepNumber: ${type.toUpperCase()}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.purpleAccent),
                      ),
                      if (author != null)
                        Text("by $author", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // The actual content render
                  isLocked
                      ? const Text("Waiting for an artist to fill this slot...", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
                      : _renderContent(type, content),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'image': return Icons.image;
      case 'audio': return Icons.music_note;
      case 'text': return Icons.article;
      default: return Icons.help;
    }
  }

  Widget _renderContent(String type, String content) {
    if (type == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(content, fit: BoxFit.cover),
      );
    } else if (type == 'text') {
      return Text(content, style: const TextStyle(fontSize: 16, height: 1.5, fontFamily: 'serif'));
    } else {
      // Audio placeholder
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
        child: const Row(
          children: [
            Icon(Icons.play_circle_fill, size: 32, color: Colors.deepPurple),
            SizedBox(width: 12),
            Expanded(child: LinearProgressIndicator(value: 0.3)),
            SizedBox(width: 12),
            Text("0:45 / 3:20"),
          ],
        ),
      );
    }
  }
}