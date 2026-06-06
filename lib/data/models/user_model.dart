import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String username;
  final String displayName;
  final String bio;
  final String avatarUrl;
  final DateTime createdAt;
  final String rank;
  final int following;
  final int followers;
  final int posts;
  final int artistPoints;
  final String role;

  UserModel({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.bio,
    required this.avatarUrl,
    required this.createdAt,
    required this.rank,
    required this.following,
    required this.followers,
    required this.posts,
    required this.artistPoints,
    required this.role,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Safely parse the Timestamp
    DateTime createdDate = DateTime.now();
    if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
      createdDate = (data['createdAt'] as Timestamp).toDate();
    }

    return UserModel(
      uid: data['uid'] ?? doc.id,
      username: data['username'] ?? 'Unknown User',
      displayName: data['displayName'] ?? 'Artist',
      bio: data['bio'] ?? 'No bio yet...',
      avatarUrl: data['avatarUrl'] ?? 'default',
      createdAt: createdDate,
      rank: data['rank'] ?? 'rankless',
      following: data['following'] ?? 0,
      followers: data['followers'] ?? 0,
      posts: data['posts'] ?? 0,
      artistPoints: data['artist_points'] ?? 0,
      role: data['role'] ?? 'user',
    );
  }

  // Optional: A helper to push updates back to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      "uid": uid,
      "username": username,
      "displayName": displayName,
      "bio": bio,
      "avatarUrl": avatarUrl,
      // We usually let the server handle timestamps, but you can pass it if needed
      "rank": rank,
      "following": following,
      "followers": followers,
      "posts": posts,
      "artist_points": artistPoints,
      "role": role,
    };
  }
}