import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/chain.dart';

class ChainCard extends StatelessWidget {
  final Chain chain;

  const ChainCard({super.key, required this.chain});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      elevation: 3,
      // We clip the card so the InkWell ripple effect doesn't overflow corners
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // This is the navigation trigger
        onTap: () {
          context.go('/chains/${chain.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(chain.title, style: Theme.of(context).textTheme.titleLarge),
                  Chip(
                    label: Text(chain.status),
                    backgroundColor: chain.status == 'Completed'
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                  )
                ],
              ),
              Text("Started by ${chain.initiatorName}", style: Theme.of(context).textTheme.bodySmall),
              const Divider(height: 20),

              // The Chain Steps (Timeline)
              ...chain.steps.asMap().entries.map((entry) {
                final int index = entry.key;
                final ChainStep step = entry.value;
                final bool isLast = index == chain.steps.length - 1;

                return _buildStepRow(context, step, isLast);
              }),

              // "Join" Button (Only if active)
              // Note: We wrap this in a IgnorePointer or handle logic carefully
              // if you want the button to do something different than the card click.
              // For now, clicking the button or card both go to details, which is fine.
              if (chain.status == 'Active')
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to detail view to join
                        context.go('/chains/${chain.id}');
                      },
                      icon: const Icon(Icons.add_link),
                      label: const Text("Contribute to Chain"),
                    ),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow(BuildContext context, ChainStep step, bool isLast) {
    // Icons based on type
    IconData icon;
    if (step.type == 'image') {
      icon = Icons.image;
    } else if (step.type == 'audio') {
      icon = Icons.music_note;
    } else {
      icon = Icons.text_fields;
    }

    Color color = step.isCompleted ? Colors.purple : Colors.grey;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The Timeline Column
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: Colors.grey.shade300)),
            ],
          ),
          const SizedBox(width: 16),

          // The Content Column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      step.type.toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)
                  ),
                  if (step.isCompleted) ...[
                    Text("By ${step.contributorName}", style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    _buildPreview(step), // Helper to show a mini-preview
                  ] else
                    const Text("Waiting for contribution...", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Simple preview based on type
  Widget _buildPreview(ChainStep step) {
    if (step.type == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
            step.contentUrl!,
            height: 100,
            width: double.infinity,
            fit: BoxFit.cover
        ),
      );
    } else if (step.type == 'text') {
      return Container(
        padding: const EdgeInsets.all(8),
        color: Colors.black12,
        child: Text(
          step.contentUrl!,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontFamily: 'serif'),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(8)
        ),
        child: const Row(
          children: [
            Icon(Icons.play_circle_fill),
            SizedBox(width: 8),
            Text("Audio Track attached")
          ],
        ),
      );
    }
  }
}