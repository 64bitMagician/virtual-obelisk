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
      // 1. Fetch the latest profile data to get the custom Display Name
      final profile = await getUserProfile(user.uid);
      final String authorName = profile?['displayName'] ?? user.email!.split('@')[0];

      // 3. Create a reference to the 'artworks' collection
      final CollectionReference artworksRef = _db.collection('artworks');

      // 4. Add the data with REAL User ID
      await artworksRef.add({
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'userId': user.uid,
        'authorName': authorName,
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

  // 1. Fetch user profile data
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      print("Error fetching profile: $e");
      return null;
    }
  }

  Future<void> updateUserProfile({
    required String uid,
    required String displayName,
    required String bio,
  }) async {
    try {
      // 1. Update the User Profile Document
      await _db.collection('users').doc(uid).set({
        'displayName': displayName,
        'bio': bio,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Sync: Find all artworks posted by this user
      final userPostsQuery = await _db.collection('artworks')
          .where('userId', isEqualTo: uid)
          .get();

      // 3. Use a WriteBatch to update all posts efficiently
      WriteBatch batch = _db.batch();

      for (var doc in userPostsQuery.docs) {
        batch.update(doc.reference, {
          'authorName': displayName,
        });
      }

      // 4. Commit the batch to Firestore
      await batch.commit();

      print("Profile and ${userPostsQuery.docs.length} posts updated successfully.");

    } catch (e) {
      print("Error during profile update/sync: $e");
      throw Exception("Failed to update profile and synchronize posts.");
    }
  }

  /// Listens to a specific user's profile document in real-time.
  /// This ensures changes persist and update instantly across the app.
  Stream<Map<String, dynamic>?> getProfileStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) => doc.data());
  }
}