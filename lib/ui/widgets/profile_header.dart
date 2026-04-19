import 'package:art_platform/data/repositories/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:art_platform/data/repositories/auth_repository.dart';

/// The [ProfileHeader] represents a visual representation of the user that displays:
/// - The rank
/// - The avatar
/// - The username
class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> userData;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onEditProfile;
  DatabaseRepository _db = DatabaseRepository();
  AuthRepository _authRepository = AuthRepository();

  /// You need to pass the [userData] that defines the header, as well as callback functions for when you
  /// tap on the avatar picture, and when you press on edit profile button.
  ProfileHeader({
    super.key,
    required this.userData,
    required this.onAvatarTap,
    required this.onEditProfile,
  });

  // Visual Part of the Profile Header
  @override
  Widget build(BuildContext context) {
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
                  border: Border.all(color: _getRankColor(rank), width: 3),
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

        // Display number of Posts, Followers and Following
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Posts Stats
            FutureBuilder<int>(
              future: _fetchNumberOfPosts(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return _buildStat("Posts", 0);
                }
                return _buildStat("Posts", snapshot.data!);
              },
            ),
            _buildDivider(),
            // Followers Stats
            _buildStat("Followers", userData['followers'] ?? 0),
            _buildDivider(),
            // Following Stats
            _buildStat("Following", userData['following'] ?? 0),
          ],
        ),
      ],
    );
  }

  // method to get a specific color based on rank
  Color _getRankColor(String rank) {
    switch (rank) {
      case 'legend': return Colors.amber;
      case 'virtuoso': return Colors.purpleAccent;
      case 'scholar': return Colors.blue;
      case 'beginner': return Colors.grey;
      default: return Colors.transparent;
    }
  }

  // returns a widget that displays the value of something (the passed label)
  Widget _buildStat(String label, int value) {
    return Column(
      children: [
        // we convert value to string to show it as a Text widget
        Text(value.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  // returns a Widget. A vertical line meant to indicate separation. It has fixed size. And it's thin.
  // It is also grey. And also has fixed margin, to make sure to establish separation on all directions
  Widget _buildDivider() => Container(
      height: 30, width: 1, color: Colors.grey.shade700, margin: const EdgeInsets.symmetric(horizontal: 24)
  );

  // fetch number of user profile posts
  Future<int> _fetchNumberOfPosts() async{
    int? numberOfPosts = 0;
    final user = _authRepository.currentUser;
    if (user != null) {
      numberOfPosts = await _db.fetchNumberOfUserPosts(user.uid);
    }
    else {
      throw Exception("ERROR: User is not authenticated!!!");
    }

    return numberOfPosts;
  }

}