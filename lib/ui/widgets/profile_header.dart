import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onAvatarTap;
  final VoidCallback onEditProfile;

  const ProfileHeader({
    super.key,
    required this.userData,
    required this.onAvatarTap,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    final String rank = userData['rank'] ?? 'Beginner';
    final String avatarUrl = userData['avatarUrl'] ?? "https://robohash.org/${userData['uid']}?set=set4";

    return Column(
      children: [
        GestureDetector(
          onTap: onAvatarTap,
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _getRankColor(rank), width: 3),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(avatarUrl),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text(
          userData['displayName'] ?? 'Artist',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(userData['bio'] ?? "No bio yet...", style: const TextStyle(color: Colors.grey)),

        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onEditProfile,
          icon: const Icon(Icons.edit, size: 16),
          label: const Text("Edit Profile"),
        ),

        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStat("Followers", userData['followers'] ?? 0),
            _buildDivider(),
            _buildStat("Following", userData['following'] ?? 0),
          ],
        ),
      ],
    );
  }

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
      height: 30, width: 1, color: Colors.grey.shade700, margin: const EdgeInsets.symmetric(horizontal: 24)
  );
}