import 'package:cloud_firestore/cloud_firestore.dart';

class ArtPost {
  final String id;
  final String imageUrl;
  final String title;
  final String description;
  final String authorName;
  final String authorAvatar;
  final int likes;

  ArtPost({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.authorName,
    required this.authorAvatar,
    required this.likes,
  });

  factory ArtPost.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return ArtPost(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      title: data['title'] ?? 'Untitled',
      description: data['description'] ?? '',
      authorName: data['authorName'] ?? 'Unknown Artist',
      authorAvatar: data['authorAvatar'] ?? 'https://i.pravatar.cc/150?u=${doc.id}',
      likes: data['likes'] ?? 0,
    );
  }
}