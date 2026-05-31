import 'package:cloud_firestore/cloud_firestore.dart';

// Define the types of posts
enum MediaType { image, audio, video, text }

/// A [Widget] that represents the data of an uploaded post on the platform.
///
/// !THIS IS NOT THE VISUAL REPRESENTATION OF THE POST!
/// !FOR THAT, CHECK art_post_card.dart
class ArtPost {
  final String additionalMediaUrl; // cover art for audio, or thumbnail for videos
  final String authorAvatar;
  final String authorName;
  final String authorUsername;
  final String category;
  final DateTime createdAt;
  final String description;
  final String id;
  final bool isDeactivated;
  final int likes;
  final MediaType mediaType;
  final String mediaUrl;
  final int reportCount;
  final String title;
  final String userId;

  /// Contructs the [ArtPost] object, based on required parameters...
  ArtPost({
    required this.additionalMediaUrl,
    required this.authorAvatar,
    required this.authorName,
    required this.authorUsername,
    required this.category,
    required this.createdAt,
    required this.description,
    required this.id,
    required this.isDeactivated,
    required this.likes,
    required this.mediaType,
    required this.mediaUrl,
    required this.reportCount,
    required this.title,
    required this.userId,
  });

  /// Creates an [ArtPost] object defined by the data of the document passed as an argument
  /// to this factory constructor.
  ///
  /// We made it a factory construtor such that we can execute custom logic
  /// within the scope of the constructor, and also return a object defined by that logic. The constructor
  /// still returns an ArtPost, but defined with data fetched from a document on Firestore that represents
  /// the post as file data...
  factory ArtPost.fromFirestore(DocumentSnapshot doc) {
    // Fetch document's data (with according format Map<String, dynamic>)
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Helper logic to convert the string from Firestore back into an Enum
    MediaType determineType(String? typeString) {
      switch (typeString) {
        case 'audio': return MediaType.audio;
        case 'video': return MediaType.video;
        case 'text': return MediaType.text;
        case 'image': return MediaType.image;
        default: return MediaType.image;
      }
    }

    // Note: Pro Tip: When you upload a post using FieldValue.serverTimestamp(), there is a split second where the local cache reads it as null before
    // the server responds with the real time. We add a safe fallback to DateTime.now() to prevent crashes during that microsecond

    //Safely convert Firebase Timestamp to Dart DateTime
    DateTime postDate = DateTime.now(); // Safe fallback
    if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
      postDate = (data['createdAt'] as Timestamp).toDate();
    }

    // Return a ArtPost object defined by data from the received document
    return ArtPost(
      additionalMediaUrl: data['additionalMediaUrl'], // if not provided, it has value: "default, by default
      authorAvatar: data['authorAvatar'] ?? 'default', // random avatar if none provided
      authorName: data['authorName'] ?? 'Unknown Artist', // "Unknown Artist" author name if none provided
      authorUsername: data['authorUsername'],
      category: data['category'],
      createdAt: postDate,
      description: data['description'] ?? '', // Empty description if non provided
      id: doc.id,
      isDeactivated: data['isDeactivated'] ?? false,
      likes: data['likes'] ?? 0, // 0 likes if number of likes not provided
      mediaType: determineType(data['mediaType']),
      mediaUrl: data['mediaUrl'] ?? '', // Image Url will be empty string if no imageUrl provided
      reportCount: data['reportCount'] ?? 0,
      title: data['title'] ?? 'Untitled', //  Title name will be "Untitled" if no title provided
      userId: data['userId'] ?? '' // nothing if userId is not there
    );
  }
}