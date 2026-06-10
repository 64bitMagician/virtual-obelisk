import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final int artistPoints;
  final String avatarUrl;
  final String bio;
  final DateTime createdAt;
  final String displayName;
  final int followers;
  final int following;
  final bool hasActivePosts;
  final DateTime lastUploadAt;
  final int posts;
  final String rank;
  final String role;
  final String uid;
  final String username;

  UserModel({
    required this.artistPoints,
    required this.avatarUrl,
    required this.bio,
    required this.createdAt,
    required this.displayName,
    required this.followers,
    required this.following,
    required this.hasActivePosts,
    required this.lastUploadAt,
    required this.posts,
    required this.rank,
    required this.role,
    required this.uid,
    required this.username,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Store Firestore Timestamps to DateTime Dart Format:

    DateTime createdAtDate = DateTime(9999); // If something wrong, createdAtDate will be year 9999
    if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
      createdAtDate = (data['createdAt'] as Timestamp).toDate();
    }

    DateTime lastUploadAtDate = DateTime(9999); // If something wrong, lastUploadAtDate will be year 9999
    if (data['lastUploadAt'] != null && data['lastUploadAt'] is Timestamp) {
      lastUploadAtDate = (data['lastUploadAt'] as Timestamp).toDate();
    }

    return UserModel(
      artistPoints: data['artist_points'] ?? 0,
      avatarUrl: data['avatarUrl'] ?? 'default',
      bio: data['bio'] ?? 'No bio yet...',
      createdAt: createdAtDate,
      displayName: data['displayName'] ?? 'Artist',
      followers: data['followers'] ?? 0,
      following: data['following'] ?? 0,
      hasActivePosts: data['hasActivePosts'],
      lastUploadAt: lastUploadAtDate,
      posts: data['posts'] ?? 0,
      rank: data['rank'] ?? 'rankless',
      role: data['role'] ?? 'user',
      uid: data['uid'] ?? doc.id,
      username: data['username'] ?? 'Unknown User',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "artist_points": artistPoints,
      "avatarUrl": avatarUrl,
      "bio": bio,
      "createdAt": Timestamp.fromDate(createdAt),
      "displayName": displayName,
      "followers": followers,
      "following": following,
      "hasActivePosts": hasActivePosts,
      "lastUploadAt": Timestamp.fromDate(lastUploadAt),
      "posts": posts,
      "rank": rank,
      "role": role,
      "uid": uid,
      "username": username,
    };
  }
}