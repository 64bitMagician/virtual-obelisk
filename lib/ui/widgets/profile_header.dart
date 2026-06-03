import 'package:art_platform/data/repositories/database_repository.dart';
import 'package:art_platform/ui/widgets/profile_screen_widgets/connections_dialog.dart';
import 'package:flutter/material.dart';
import 'package:art_platform/ui/widgets/profile_screen_widgets/rank_progress_bar.dart';

/// The [ProfileHeader] represents a visual representation of the user that displays:
/// - The rank
/// - The avatar
/// - The username
class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> userData;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onEditProfile;
  final String profileUid;

  /// You need to pass the [userData] that defines the header, as well as callback functions for when you
  /// tap on the avatar picture, and when you press on edit profile button.
  const ProfileHeader({
    super.key,
    required this.profileUid,
    required this.userData,
    required this.onAvatarTap,
    required this.onEditProfile,
  });

  // Visual Part of the Profile Header
  @override
  Widget build(BuildContext context) {
    // Fetch points to drive both the Progress Bar and the Avatar Border!
    final int userPoints = userData['artist_points'] ?? -1;
    // store the rank of user in a variable, otherwise the rank will be automatically set to "No rank"
    final String rank = userData['rank'] ?? 'rankless';
    // store the avatarUrl of user in a variable, otherwise get a unique avatar url from robohash.org
    final String avatarUrl = userData['avatarUrl'] ?? "default";

    return Column(
      children: [
        // We want to detect if the user taps/clicks on the avatar, such that we trigger a behaviour
        // In our case, we pass a [VoidCallback] function that will prompt the user to change the Avatar
        // picture with an image from his local machine
        GestureDetector(
          onTap: onAvatarTap, // the behaviour to replace avatar picture
          child: Stack( // Stack is used only at the Avatar Area
            children: [
              Container( // The visual Avatar Picture
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration( //
                  shape: BoxShape.circle,
                  // border color determined by rank
                  border: Border.all(color: _getDynamicAvatarColor(userPoints), width: 3),
                ),
                child: CircleAvatar( // the circle with usser's avatar image
                  radius: 100,
                  backgroundImage: avatarUrl=="default" ?
                  AssetImage('assets/icons/user-profile-icon.png') : NetworkImage(avatarUrl), // fetch image form URL
                ),
              ),
              // Positioned() will control where it's child Widget (Camera Icon) will be positioned
              // within it's available area
              if(onAvatarTap!=null)
                Positioned(
                  // The position is relative to the property
                  // Ex: bottom: 0 is at the botton while bottom: 100 means 100 pixels above the bottom
                  bottom: 0, // at the far bottom
                  right: 0, // at the far right
                  child: CircleAvatar(
                    radius: 15, // camera icon size
                    backgroundColor: Theme.of(context).primaryColor, // fetch theme color
                    child: const Icon(Icons.camera_alt, size: 18, color: Colors.white), // camera icon
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Display the name of User. If user does not have a name, display the word "Arist"
        Text(
          userData['displayName'] ?? 'Artist',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // If user does not have a bio, display "No bio yet..."
        Text(userData['bio'] ?? "No bio yet...", style: const TextStyle(color: Colors.grey)),

        const SizedBox(height: 12),

        // Button to edit user profile
        if(onEditProfile!=null)
          OutlinedButton.icon(
            onPressed: onEditProfile, // Use member callback function
            icon: const Icon(Icons.edit, size: 16),
            label: const Text("Edit Profile"),
          ),

        const SizedBox(height: 24),

        // THE PROGRESS BAR
        // Constrain its width so it doesn't stretch infinitely on wide screens
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: RankProgressBar(artistPoints: userPoints),
        ),

        const SizedBox(height: 24),

        // Display number of Posts, Followers and Following
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStat("Posts", userData['posts'] ?? -1),
            _buildDivider(),
            _buildStat(
                "Followers",
                userData['followers'] ?? -1,
                onTap: () => _showConnectionsDialog(context, "Followers", "followers", userData['uid'])
            ),
            _buildDivider(),
            _buildStat(
                "Following",
                userData['following'] ?? -1,
                onTap: () => _showConnectionsDialog(context, "Following", "following", userData['uid'])
            ),
          ],
        ),
      ],
    );
  }

  // Helper method to sync the Avatar border color with the RankProgressBar logic!
  Color _getDynamicAvatarColor(int points) {
    // iterate through the ranks
    for (int i = 0; i < RankProgressBar.ranks.length; i++) {
      // if the last rank's max points have been exceeded
      if (i == RankProgressBar.ranks.length - 1 && points >= RankProgressBar.ranks[i]['max']) {
        return RankProgressBar.ranks.last['color']; // return the color of last rank
      }
      // if we fit in the range of the rank
      if (points >= RankProgressBar.ranks[i]['min'] && points < RankProgressBar.ranks[i]['max']) {
        return RankProgressBar.ranks[i]['color']; // return the color of the rank
      }
    }

    // In any other case, we fall back to Novice Rank Color
    return RankProgressBar.ranks.first['color'];
  }

  // returns a widget that displays the value of something (the passed label)
  Widget _buildStat(String label, int value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap, // If onTap is null, InkWell automatically disables the ripple effect
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            Text(value.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  void _showConnectionsDialog(BuildContext context, String title, String collectionName, String profileUid) {
    showDialog(
      context: context,
      builder: (context) => ConnectionsDialog(
        title: title,
        collectionName: collectionName,
        profileUid: profileUid,
      ),
    );
  }

  // returns a Widget. A vertical line meant to indicate separation. It has fixed size. And it's thin.
  // It is also grey. And also has fixed margin, to make sure to establish separation on all directions
  Widget _buildDivider() => Container(
      height: 30, width: 1, color: Colors.grey.shade700, margin: const EdgeInsets.symmetric(horizontal: 24)
  );
}