import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:art_platform/data/models/art_post.dart';
import 'package:art_platform/data/models/user_model.dart';

/// The core of the Home Feed and Category Feed.
/// This is a algorithm that rewards user involvement on the platform.
/// The more you are involved on the platform, the more chances of
/// being seen.
///
/// It is very important to understand that [_ineligibleUsersMap] and [_seenPostIds] do not ever reset for the current
/// running process of the [FeedEngine] instance.
/// What this means is that, until the this object ([FeedEngine]) will be distroyed, it will keep adding data to the two mentioned lists.
/// But this is good because they function for the entirety of a screen page, such as the Home Screen, or the Category Screen, which both contain a feed.
/// And we do not want that feed (specifically the data in [_ineligibleUsersMap] and [_seenPostIds]) to reset until we exit from that screen.
class FeedEngine {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // List for storing the fetched users:
  List<UserModel> _userPool = [];

  final Map<String, Set<String>> _ineligibleUsersMap = {};
  // Keep track of post that the user has already seen:
  // We do this to prevent the user from seeing the same post again in the current
  // run of the application.
  final Set<String> _seenPostIds = {};
  // Used for randomness factor:
  final Random _random = Random();

  /// Initializes/Re-Initializes the "Pool" of potential users ([UserModel] instances).
  /// Since we will do the test to less than 100 users, there is no need for more advanced pick user algorithms yet
  Future<void> _refreshUserPool() async {
    try {
      // In the feature we might store a lastActive property to filter dead accounts:
      // ".where('lastActive', isGreaterThan: lastWeek)" or something like that

      // We will get 100 different users, which have at least one active post,
      // and in the order of the users that have most recently uploaded.
      // And also, if there is a user that has uploaded recently, and had
      // posts (including the one uploaded), but they all got deactivated, it won't include that user.
      final snapshotOfUsersGathered = await _db.collection('users')
          .where('hasActivePosts', isEqualTo: true)
          .orderBy('lastUploadAt', descending: true)
          .limit(100)
          .get();

      // Map data to user model object. Contain the users in a list '_userPool'
      _userPool = snapshotOfUsersGathered.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
      // We shuffle the pool anyway (further randomness),
      // even tough we have randomness in picking a lucky user
      _userPool.shuffle(_random);
    } catch (e) {
      print("Error fetching user pool and mapping it to list: $e");
    }
  }

  /// Spin the wheel to pick a User based on Artist Points Percentage Chance
  /// This will return the lucky UserModel.
  ///
  UserModel? _pickWeightedUser(String? category) {
    String contextKey = category ?? 'HOME'; // if no category provided, we will consider the HOME FEED to filter the ineligible users
    // we get the set of all ineligible users that are excluded to futher be displayed by the algorithm for the given [category/or HOME FEED]
    Set<String> currentlyIneligible = _ineligibleUsersMap[contextKey] ?? {};

    // Make a list of available users. Available users are users that are not part of the currentlyIneligible list.
    // An ineligible user means a user that in a previous try, he was not able to return any post because either:
    //  - he did not upload any posts
    //  - he did not upload any post for a required category
    //  - all his available post have already been consumed/processed/displayed (they exist in _seenPostIds)
    List<UserModel> availableUsers = _userPool.where((user) => !currentlyIneligible.contains(user.uid)).toList();

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
    // So we have sum of all AP of all Users
    // totalWeight = [USER_1_AP]+[USER_2_AP]+ ... +[USER_N_AP]
    // Because we used the max() method earlier, each user is considered to have at least 1 AP (even tough in the actual reality data it has 0 AP)
    // So we we need to get a random value to select a user from this range: [1, totalWeight]
    int randomVal = 0;
    while(randomVal==0) // make sure we do not get value 0, because the range is [1, totalWeight]
      randomVal = _random.nextInt(totalWeight+1); // nextInt is right-exclusive, so to get totalWeight we need to pass totgalWeight + 1

    // now we need to find the lucky user.
    // So we have the lucky number associated with the lucky user
    // We iteratively (in order) added AP to totalWeight, so there is a AP range associated for each user
    // By substracting from randomVal (the lucky number) the AP of each user in the same iterative order,
    // we will eventually hit this range:
    // [lucky_user_start_AP_range=================randomVal-(First initialized)=================lucky_user_end_AP_range]
    // which because of substraction is actually:
    // [1=================randomVal=================lucky_user_AP]
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
  /// to be Picked by the Wheel.
  /// Any posts that have already been selected won't be selected again.
  Future<ArtPost?> _pickWeightedPost(String userId, [String? category]) async {
    try {
      // Create a query that points to all artworks of the given user
      Query query = _db.collection('artworks').where('userId', isEqualTo: userId);

      // If 'category' parameter has been provided (just the query changes, the further logic does not):
      //  Update the query to pont to all artworks of the given user that belong to the given category
      // If he does not have any artposts in that category ... then: query.get().docs == [] (empty list), or query.get().docs.isEmpty == true
      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      final snapshotOfAllLuckyUserArtPosts = await query.get();

      // if user has no artposts for a given category (if category has been provided),
      // or if the user has no artposts at all:
      if (snapshotOfAllLuckyUserArtPosts.docs.isEmpty==true)
        return null;

      // if the user has the corresponding artposts (of a given category or not):

      // Convert each artwork into an ArtPost model, and store them into a list, but:
      // - do not include already seen posts
      List<ArtPost> availablePosts = snapshotOfAllLuckyUserArtPosts.docs
          .map((doc) => ArtPost.fromFirestore(doc))
          .where((post) => !_seenPostIds.contains(post.id)) // the post must not exist in the list of already seen posts
          .toList();

      // If there are available posts, but they've already been processed/displayed/seen (they belong to the seenedPosts list):
      if (availablePosts.isEmpty)
        return null;

      // Just as before, we calculate the total ammount of likes from all available posts of user
      int totalWeight = availablePosts.fold(0, (sum, post) => sum + max(1, post.likes));
      // Spin the wheel to find who will be the lucky post | Also make sure the range is [1, totalWeight]
      int randomVal = 0;
      while(randomVal==0)
        randomVal = _random.nextInt(totalWeight+1);

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

  /// Generate a batch ([List] if [ArtPost] instances) of artworks for the feed
  Future<List<ArtPost>?> generateFeedBatch({int batchSize = 5, String? category}) async {
    // Initialize the Pool if it has not been initialized.
    if (_userPool.isEmpty) {
      await _refreshUserPool();
    }

    List<ArtPost> newBatch = [];
    String contextKey = category ?? 'HOME';

    while (newBatch.length < batchSize) {
      // pick a user based on his weight (his AP chance)
      final selectedUser = _pickWeightedUser(category);

      // If selectedUser is null, it means EVERY user in _userPool is now inside _ineligibleUsersMap for this context.
      // There is mathematically no unseen art left to fetch. We must break the loop.
      if (selectedUser == null) {
        break;
      }

      // pick a post of user's, based on the weight of post (ammount of likes chance)
      final selectedPost = await _pickWeightedPost(selectedUser.uid, category);

      // if by any chance, the user has no posts (or no posts for a specififc category), we continue to next loop
      // here is where most loops may trigger the 'continue' of the loop
      if (selectedPost == null) {
        _ineligibleUsersMap.putIfAbsent(contextKey, () => {}).add(selectedUser.uid); // if user has not met the requirements to return a post, add it to ineligible list mapping
        continue; // go to next loop
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


    if (newBatch.isEmpty) return null;

    // otherwise we can return the batch of ArtPost instances
    return newBatch;
  }
}