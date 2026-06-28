import 'package:flutter/material.dart';

class RankProgressBar extends StatelessWidget {
  final int artistPoints;

  const RankProgressBar({super.key, required this.artistPoints});

  static const List<Map<String, dynamic>> ranks = [
    {'name': 'Novice', 'min': 0, 'max': 500, 'color': Colors.grey},
    {'name': 'Apprentice', 'min': 500, 'max': 1500, 'color': Colors.green},
    {'name': 'Artisan', 'min': 1500, 'max': 3000, 'color': Colors.blue},
    {'name': 'Master', 'min': 3000, 'max': 5000, 'color': Colors.purple},
    {'name': 'Virtuoso', 'min': 5000, 'max': 7500, 'color': Colors.orange},
    {'name': 'Visionary', 'min': 7500, 'max': 10500, 'color': Colors.red},
    {'name': 'Legend', 'min': 10500, 'max': 11000, 'color': Colors.amber},
  ];

  Map<String, dynamic> _getCurrentRankInfo() {
    for (int i = 0; i < ranks.length; i++) {
      if (i == ranks.length - 1 && artistPoints >= ranks[i]['max']) {
        return ranks.last;
      }

      if (artistPoints >= ranks[i]['min'] && artistPoints < ranks[i]['max']) {
        return ranks[i];
      }
    }
    return ranks.first;
  }

  @override
  Widget build(BuildContext context) {
    final rankInfo = _getCurrentRankInfo();
    final String rankName = rankInfo['name'];
    final int minPoints = rankInfo['min'];
    final int maxPoints = rankInfo['max'];
    final Color rankColor = rankInfo['color'];

    double progress = 1.0;
    if (maxPoints > minPoints && artistPoints < maxPoints) {
      progress = (artistPoints - minPoints) / (maxPoints - minPoints);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                rankName.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: rankColor,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                "$artistPoints / $maxPoints AP",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey[800],
              color: rankColor,
            ),
          ),
        ],
      ),
    );
  }
}