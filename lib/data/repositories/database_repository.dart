import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <--- Import Auth
import '../models/art_post.dart';

class DatabaseRepository {
  // Get the instances
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Saves the art metadata to the 'artworks' collection
  Future<void> saveArt({
    required String title,
    required String description,
    required String imageUrl,
  }) async {
    // 1. Get the current logged-in user
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("You must be logged in to post art.");
    }

    try {
      // 2. Generate a temporary display name from email (since we don't have usernames yet)
      // e.g., "vlad@test.com" -> "vlad"
      final String tempName = user.email != null
          ? user.email!.split('@')[0]
          : "Anonymous Artist";

      // 3. Create a reference to the 'artworks' collection
      final CollectionReference artworksRef = _db.collection('artworks');

      // 4. Add the data with REAL User ID
      await artworksRef.add({
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'userId': user.uid,        // <--- REAL ID from Auth
        'authorName': tempName,    // <--- REAL Name derived from Email
        // Generate a consistent avatar based on their ID
        'authorAvatar': 'https://robohash.org/${user.uid}?set=set4',
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
      });

    } catch (e) {
      print("DATABASE ERROR: $e");
      throw Exception("Failed to save to database");
    }
  }

  /// Listen to the Real-Time Feed (All Users)
  Stream<List<ArtPost>> getFeedPosts() {
    return _db
        .collection('artworks')
        .orderBy('createdAt', descending: true) // Show newest first
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ArtPost.fromFirestore(doc)).toList();
    });
  }

  /// Listen to ONLY a specific user's posts (For Profile)
  Stream<List<ArtPost>> getUserPosts(String userId) {
    // If we pass 'me', automatically use the current user's ID
    final String? targetId = (userId == 'me') ? _auth.currentUser?.uid : userId;

    if (targetId == null) {
      // If not logged in, return empty list
      return const Stream.empty();
    }

    return _db
        .collection('artworks')
        .where('userId', isEqualTo: targetId) // <--- FILTER by ID
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ArtPost.fromFirestore(doc)).toList();
    });
  }
}