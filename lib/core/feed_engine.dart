import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:art_platform/data/models/art_post.dart';
import 'package:art_platform/data/models/user_model.dart';

class FeedEngine {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // List for storing the fetched users:
  List<UserModel> _userPool = [];
  final Set<String> _exhaustedUserIds = {};
  // Keep track of post that the user has already seen:
  // We do this to prevent the user from seeing the same post again in the current
  // run of the application.
  final Set<String> _seenPostIds = {};
  // Used for randomness factor:
  final Random _random = Random();

  /// Initializes/Re-Initializes the "Pool" of potential creators/uploaders
  /// Since we will do the test to less than 100 users, there is no need for more advanced pick user algorithms yet
  Future<void> _refreshUserPool() async {
    try {
      // In the feature we might store a lastActive property to filter dead accounts:
      // ".where('lastActive', isGreaterThan: lastWeek)" or something like that

      // For now we grab the 100 most recently signed up users.
      final snapshotOfUsersGathered = await _db.collection('users')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      // Map data to user model object. Contain the users in a list '_userPool'
      _userPool = snapshotOfUsersGathered.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error fetching user pool and mapping it to list: $e");
    }
  }

  /// Spin the wheel to pick a User based on Artist Points Percentage Chance
  /// This will return the lucky UserModel
  UserModel? _pickWeightedUser() {
    List<UserModel> availableUsers = _userPool.where((u) => !_exhaustedUserIds.contains(u.uid)).toList();

    if (availableUsers.isEmpty) return null;

    // Calculate the total "weight" (Sum of all Artist Points)
    // We use fold to surf through all users and add their artist points to the sum
    // sum gets returned in the end
    // we use max(1, user.artistPoints); because of the implementation bellow, of finding our lucky user
    // cause if more users had 0, and 0 was used, then we would not be able to identify the user
    int totalWeight = availableUsers.fold(0, (sum, user) {
      return sum + max(1, user.artistPoints);
    });

    // get rendom int from totalWeight -> this is the spin the wheel step
    int randomVal = _random.nextInt(totalWeight);

    // now we need to find the lucky user.
    // So we have the lucky number associated with the lucky user
    // We iteratively (in order) added AP to totalWeight, so there is a AP range associated for each user
    // By substracting from randomVal (the lucky number), the AP of each user in the same iterative order,
    // we will eventually hit this range:
    // [lucky_user_start_AP_range=================randomVal-(First initialized)=================lucky_user_end_AP_range]
    // which because of substraction is actually:
    // [0=================randomVal=================lucky_user_AP]
    // And now we also substract the AP of the lucky_user, and we either hit randomVal=0, (if randomVal==lucky_user_AP)
    // or randomVal < 0
    // Which means that, when we hit randomVal <=0, we have just substracted the AP of the lucky_user, which means:
    // the 'user' variable is actually our lucky user | We have found our lucky user, and return it
    for (var user in availableUsers) {
      randomVal -= max(1, user.artistPoints);

      if (randomVal <= 0) {
        return user;
      }
    }

    // If something went wrong, we return null
    return null;
  }

  /// Spin the Wheel to pick a Post belonging to the Lucky User.
  /// The Greater the Number of Likes on a Post, the Higher the Chance of that Post
  /// to be Picked by the Wheel
  Future<ArtPost?> _pickWeightedPost(String userId) async {
    try {
      // Fetch all artworks Firestore Documents of the Lucky User
      final snapshotOfAllLuckyUserArtPosts = await _db.collection('artworks')
          .where('userId', isEqualTo: userId)
          .get();

      // Convert each artwork into an ArtPost model, and store them into a list, but:
      // - do not include already seen posts
      List<ArtPost> availablePosts = snapshotOfAllLuckyUserArtPosts.docs
          .map((doc) => ArtPost.fromFirestore(doc))
          .where((post) => !_seenPostIds.contains(post.id))
          .toList();

      if (availablePosts.isEmpty) return null;

      // Just as before, we calculate the total ammount of likes from all available posts of user
      int totalWeight = availablePosts.fold(0, (sum, post) => sum + max(1, post.likes));
      // Spin the wheel to find who will be the lucky post
      int randomVal = _random.nextInt(totalWeight);

      // actually get the instance of the lucky post
      for (var post in availablePosts) {
        randomVal -= max(1, post.likes);
        if (randomVal <= 0) {
          return post;
        }
      }

      // If anything wrong happens we return null
      return null;
    } catch (e) {
      print("Error fetching posts for user '$userId': $e");
      return null;
    }
  }

  /// Generate a batch of artworks for the feed
  Future<List<ArtPost>?> generateFeedBatch({int batchSize = 5}) async {
    // Initialize the Pool if it has not been initialized
    if (_userPool.isEmpty) {
      await _refreshUserPool();
    }

    List<ArtPost> newBatch = [];
    int safetyCounter = 0;

    while (newBatch.length < batchSize && safetyCounter < 20) {
      safetyCounter++;

      // pick a user based on his weight (his AP chance)
      final selectedUser = _pickWeightedUser();
      // If by any chance it returns null, we continue to next loop
      if (selectedUser == null) continue;

      // pick a post of the user, based on the weight of post (ammount of likes chance)
      final selectedPost = await _pickWeightedPost(selectedUser.uid);

      // if by any chance, the user has no post, we continue to next loop
      if (selectedPost == null) {
        _exhaustedUserIds.add(selectedUser.uid);
        continue;
      }

      // but if we picked a user and a post of his:
      // we mark the post as seened already by adding it to the list of seened posts
      // we do this to prevent seeing the post again for the current run of the application
      // there is a small bug with this:
      // the user may not actually end up surfing to this actual post in the batch
      // so in that case he won't see the post, but the post will get marked as seened anyway
      // and it won't appear again in his feed for the current run of the application
      _seenPostIds.add(selectedPost.id);
      // add the post to the batch of ArtPost instances that the user will see in his feed
      newBatch.add(selectedPost);
    }

    // if by the smallest chance, the batch has no ArtPost instances because there were no users
    // that had uploaded any post (or all posts have already been seen): then we return null
    if (newBatch.isEmpty) return null;

    // otherwise we can return the batch of ArtPost instances
    return newBatch;
  }
}