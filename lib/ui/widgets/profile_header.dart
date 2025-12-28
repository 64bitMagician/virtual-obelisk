import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> user;

  const ProfileHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar with Rank Border
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: _getRankColor(user['rank']),
                width: 3
            ),
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(user['avatarUrl']),
          ),
        ),
        const SizedBox(height: 16),

        // Name and Rank Badge
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              user['name'],
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getRankColor(user['rank']),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user['rank'].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),
        Text(user['bio'], style: Colors.grey.shade400.asTextStyle()),
        const SizedBox(height: 24),

        // Stats Row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStat("Followers", user['followers']),
            _buildDivider(),
            _buildStat("Following", user['following']),
            _buildDivider(),
            _buildStat("Likes", user['likes']),
          ],
        ),
      ],
    );
  }

  // Helper to color-code ranks
  Color _getRankColor(String rank) {
    switch (rank) {
      case 'Legend': return Colors.amber;
      case 'Virtuoso': return Colors.purpleAccent;
      case 'Scholar': return Colors.blue;
      default: return Colors.grey;
    }
  }

  Widget _buildStat(String label, int value) {
    return Column(
      children: [
        Text(value.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildDivider() => Container(
      height: 30,
      width: 1,
      color: Colors.grey.shade700,
      margin: const EdgeInsets.symmetric(horizontal: 24)
  );
}

// Extension to safely use text styles
extension TextStyleExt on Color {
  TextStyle asTextStyle() => TextStyle(color: this);
}