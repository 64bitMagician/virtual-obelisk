import 'package:flutter/material.dart';
import '../../data/models/chain.dart';
import '../../data/repositories/mock_repository.dart';

class ChainDetailScreen extends StatefulWidget {
  final String chainId;

  const ChainDetailScreen({super.key, required this.chainId});

  @override
  State<ChainDetailScreen> createState() => _ChainDetailScreenState();
}

class _ChainDetailScreenState extends State<ChainDetailScreen> {
  final MockRepository _repository = MockRepository();
  late Future<Chain> _chainFuture;

  @override
  void initState() {
    super.initState();
    _chainFuture = _repository.getChainById(widget.chainId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Collaboration Details")),
      body: FutureBuilder<Chain>(
        future: _chainFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final chain = snapshot.data!;

          return SingleChildScrollView(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header Section
                    Text(
                        chain.title,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const CircleAvatar(radius: 12, child: Icon(Icons.person, size: 12)),
                        const SizedBox(width: 8),
                        Text("Initiated by ${chain.initiatorName}", style: Colors.grey.asTextStyle()),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: chain.status == 'Active' ? Colors.green : Colors.grey,
                              borderRadius: BorderRadius.circular(20)
                          ),
                          child: Text(chain.status.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        )
                      ],
                    ),
                    const Divider(height: 40),

                    // 2. The Art Steps (The Core Content)
                    ListView.separated(
                      shrinkWrap: true, // Important inside SingleChildScrollView
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: chain.steps.length,
                      separatorBuilder: (ctx, i) => _buildConnector(),
                      itemBuilder: (context, index) {
                        return _buildStepDisplay(chain.steps[index], index + 1);
                      },
                    ),

                    // 3. Footer / Action
                    const SizedBox(height: 40),
                    if (chain.status == 'Active')
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Participation Logic checks rank first..."))
                            );
                          },
                          icon: const Icon(Icons.brush),
                          label: const Text("Join this Chain"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
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

  Widget _buildStepDisplay(ChainStep step, int stepNumber) {
    bool isLocked = !step.isCompleted;

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
                color: isLocked ? Colors.grey.shade800 : Colors.purple,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white12, width: 2),
              ),
              child: Center(
                child: isLocked
                    ? const Icon(Icons.lock_outline, color: Colors.white54)
                    : Icon(_getIconForType(step.type), color: Colors.white),
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
                        "Step $stepNumber: ${step.type.toUpperCase()}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.purpleAccent),
                      ),
                      if(step.contributorName != null)
                        Text("by ${step.contributorName}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // The actual content render
                  isLocked
                      ? const Text("Waiting for an artist to fill this slot...", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
                      : _renderContent(step),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getIconForType(String type) {
    switch(type) {
      case 'image': return Icons.image;
      case 'audio': return Icons.music_note;
      case 'text': return Icons.article;
      default: return Icons.help;
    }
  }

  Widget _renderContent(ChainStep step) {
    if (step.type == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(step.contentUrl!, fit: BoxFit.cover),
      );
    } else if (step.type == 'text') {
      return Text(step.contentUrl!, style: const TextStyle(fontSize: 16, height: 1.5, fontFamily: 'serif'));
    } else {
      // Audio placeholder
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
        child: const Row(
          children: [
            Icon(Icons.play_circle_fill, size: 32, color: Colors.purple),
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

extension TextStyleExt on Color {
  TextStyle asTextStyle() => TextStyle(color: this);
}