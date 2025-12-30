import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/art_post.dart';

class DatabaseRepository {

  // Get the database instance
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Saves the art metadata to the 'artworks' collection
  Future<void> saveArt({
    required String title,
    required String description,
    required String imageUrl,
  }) async {
    try {
      // 1. Create a reference to the 'artworks' collection
      final CollectionReference artworksRef = _db.collection('artworks');

      // 2. Add the data (Firestore automatically creates a unique ID)
      await artworksRef.add({
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'userId': 'test-user-id', // Hardcoded for now (until we build Login)
        'authorName': 'Vlad (Alpha)', // Hardcoded for now
        'createdAt': FieldValue.serverTimestamp(), // Use server time
        'likes': 0,
      });

    } catch (e) {
      print("DATABASE ERROR: $e");
      throw Exception("Failed to save to database");
    }
  }

  /// Listen to the Real-Time Feed
  Stream<List<ArtPost>> getFeedPosts() {
    return _db
        .collection('artworks')
        .orderBy('createdAt', descending: true) // Show newest first
        .snapshots()
        .map((snapshot) {
      // Convert every document into an ArtPost
      return snapshot.docs.map((doc) => ArtPost.fromFirestore(doc)).toList();
    });
  }
}