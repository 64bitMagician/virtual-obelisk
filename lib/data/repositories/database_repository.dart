import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/art_post.dart';

class DatabaseRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Saves the art metadata to the 'artworks' collection
  Future<void> saveArt({
    required String title,
    required String description,
    required String imageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("You must be logged in to post art.");
    }

    try {
      final profile = await getUserProfile(user.uid);
      final String authorName = profile?['displayName'] ?? user.email!.split('@')[0];
      final String avatarUrl = profile?['avatarUrl'] ?? 'https://robohash.org/${user.uid}?set=set4';

      final CollectionReference artworksRef = _db.collection('artworks');

      await artworksRef.add({
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'userId': user.uid,
        'authorName': authorName,
        'authorAvatar': avatarUrl, // Uses the real avatar URL if it exists
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
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ArtPost.fromFirestore(doc)).toList();
    });
  }

  /// Listen to ONLY a specific user's posts (For Profile)
  Stream<List<ArtPost>> getUserPosts(String userId) {
    final String? targetId = (userId == 'me') ? _auth.currentUser?.uid : userId;

    if (targetId == null) return const Stream.empty();

    return _db
        .collection('artworks')
        .where('userId', isEqualTo: targetId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ArtPost.fromFirestore(doc)).toList();
    });
  }

  /// Fetch user profile data
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      print("Error fetching profile: $e");
      return null;
    }
  }

  /// Updated: Flexible profile update that handles name, bio, and avatar.
  /// It also syncs the name and avatar to all previous posts.
  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      // 1. Prepare map of updates
      final Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (displayName != null) updates['displayName'] = displayName;
      if (bio != null) updates['bio'] = bio;
      if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;

      // 2. Update the User Profile Document
      await _db.collection('users').doc(uid).set(updates, SetOptions(merge: true));

      // 3. Sync: Find all artworks posted by this user to update their "snapshot" data
      // Only sync if name or avatar changed
      if (displayName != null || avatarUrl != null) {
        final userPostsQuery = await _db
            .collection('artworks')
            .where('userId', isEqualTo: uid)
            .get();

        WriteBatch batch = _db.batch();

        for (var doc in userPostsQuery.docs) {
          final Map<String, dynamic> postUpdates = {};
          if (displayName != null) postUpdates['authorName'] = displayName;
          if (avatarUrl != null) postUpdates['authorAvatar'] = avatarUrl;

          batch.update(doc.reference, postUpdates);
        }

        await batch.commit();
      }

      print("Profile updated successfully.");
    } catch (e) {
      print("Error during profile update/sync: $e");
      throw Exception("Failed to update profile and synchronize posts.");
    }
  }

  /// Listens to a specific user's profile document in real-time.
  Stream<Map<String, dynamic>?> getProfileStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) => doc.data());
  }
}