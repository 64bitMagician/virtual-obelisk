import 'package:cloud_firestore/cloud_firestore.dart';

/// A [Widget] that represents the data of an uploaded post on the platform.
///
/// !THIS IS NOT THE VISUAL REPRESENTATION OF THE POST!
/// !FOR THAT, CHECK art_post_card.dart
class ArtPost {
  final String id;
  final String imageUrl;
  final String title;
  final String description;
  final String authorName;
  final String authorAvatar;
  final int likes;

  /// Contructs the [ArtPost] object, based on required parameters...
  ArtPost({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.authorName,
    required this.authorAvatar,
    required this.likes,
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

    // Return a ArtPost object defined by data from the received document
    return ArtPost(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '', // Image Url will be empty string if no imageUrl provided
      title: data['title'] ?? 'Untitled', //  Title name will be "Untitled" if no title provided
      description: data['description'] ?? '', // Empty description if non provided
      authorName: data['authorName'] ?? 'Unknown Artist', // "Unknown Artist" author name if none provided
      authorAvatar: data['authorAvatar'] ?? 'https://i.pravatar.cc/150?u=${doc.id}', // random avatar if none provided
      likes: data['likes'] ?? 0, // 0 likes if number of likes not provided
    );
  }
}