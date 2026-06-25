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

  // Keep a marker to the current last user document in the user pool
  // Because the query is sorted by lastUploadAt, _lastUserDoc knows exactly what its lastUploadAt timestamp is,
  // and it knows its unique Document ID.
  // So it's like the query fetches the documents, but since we configured it to start after the last document, it will only take in consideration 100
  // documents from that point of fetching (the last document) forward.
  DocumentSnapshot? _lastUserDoc;

  // keep track of weather in the last fetch we were able to fetch users for the pool
  // if in the last fetch we were not able to fetch any users, this changes to false
  // This mean that we can fetch the last users, and this variable will still hold true
  // But the next fetch, the variable will turn to false, because we were not able to fetch userss
  bool _wasAbleToFetchUsersForPool = true;

  // Keep track of users that can no longer provide posts for a given category/home_feed.
  // The key is the category and the value is the set of UserIDs that are excluded from further displaying on the feed
  final Map<String, Set<String>> _ineligibleUsersMap = {};
  // Keep track of post that the user has already seen:
  // We do this to prevent the user from seeing the same post again in the current
  // run of the application.
  final Set<String> _seenPostIds = {};
  // Used for randomness factor:
  final Random _random = Random();

  /// Initializes/Append_to the "Pool" of potential users ([UserModel] instances).
  Future<void> _refreshUserPool() async {
    // ! This method can be improved in the future to directly select the user that have posts for a
    // given category. But for that we need to keep track in User Documents what categories they have posted.
    // This requires changes in User Documents format. And also be careful a user might have one single post
    // in a category, and the post might get disabled/deleted, and then the category should dissapear frmo the User
    // Document, such that that user does not get included, because he no longer has posts for that category. Cause
    // the post has been deleted/disabled!


    // just directly return if there are no more users to be fetched
    if (!_wasAbleToFetchUsersForPool) return;

    try {
      // We will get 100 different users, which have at least one active post,
      // and in the order of the users that have most recently uploaded (this means an very good post
      // won't be seen if the user has not been recently active with uploading on the platform).
      // And also, if there is a user that has uploaded recently, and had
      // posts (including the one uploaded), but they all got deactivated, it won't include that user.
      Query query = _db.collection('users')
          .where('hasActivePosts', isEqualTo: true)
          .orderBy('lastUploadAt', descending: true)
          .limit(100);

      // if _lastUserDoc is not null, it means that we had previously initialized the pool
      // so now that the _refreshUserPool() has been called again, we are now appending to
      // the pool, not re-initializing
      // thus, we will get the next 100 users that meet the conditions of the query
      // this makes the feed infinite, the pool appends to itself
      if (_lastUserDoc != null) {
        query = query.startAfterDocument(_lastUserDoc!);
      }

      // get the users
      final snapshotOfUsersGathered = await query.get();

      // check if there are no more users we can fetch and mark
      if (snapshotOfUsersGathered.docs.isEmpty) {
        _wasAbleToFetchUsersForPool = false;
        return;
      }

      // get last doc of the last user in the snapshot
      // query will continue from this one to query next
      _lastUserDoc = snapshotOfUsersGathered.docs.last;

      // Map data to user model object. Contain the users in a list '_userPool'
      List<UserModel> fetchedUsers = snapshotOfUsersGathered.docs.map((doc) => UserModel.fromFirestore(doc)).toList();

      // We shuffle the pool anyway (further randomness),
      // even tough we have randomness in picking a lucky user
      fetchedUsers.shuffle(_random);

      // append to pool of users
      _userPool.addAll(fetchedUsers);
    } catch (e) {
      print("Error fetching user pool and mapping it to list: $e");
    }
  }

  /// Spin the wheel to pick a User based on Artist Points Percentage Chance
  /// This will return the lucky UserModel.
  /// If providing a [category], will not pick excluded users in that category.
  /// If a user is picked, but has no post in that category, he will get marked in the exluded list for that category
  /// for future filtering...
  /// If category not provided, will not pick excluded users for home feed
  UserModel? _pickWeightedUser(String? category) {
    String contextKey = category ?? 'HOME'; // if no category provided, we will consider the HOME FEED to filter the ineligible users
    // we get the set of all ineligible users that are excluded from being displayed by the algorithm for the given [category/HOME_FEED]
    Set<String> currentlyIneligible = _ineligibleUsersMap[contextKey] ?? {};

    // Make a list of available users. Available users are users that are not part of the currentlyIneligible list.
    // An ineligible user means a user that in a previous try was not able to return a post for the required category/home_feed (or had no posts at all) because:
    //  - he does not have any active posts at all
    //  - he does not have any active posts for the required category
    //  - all his available posts have already been consumed/processed/displayed/seen (they exist in _seenPostIds)
    List<UserModel> availableUsers = _userPool.where((user) => !currentlyIneligible.contains(user.uid)).toList();

    // if availableUsers is empty, it means that there are no more avaiable users for the given category/home_feed
    // so we need new users to the pool, if there are any
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
      // Create a query that points to all active artposts of the given user
      Query query = _db.collection('artworks').where('userId', isEqualTo: userId).where('isDeactivated', isEqualTo: false);

      // If 'category' parameter has been provided (just the query changes, the further logic does not):
      //  Update the query to pont to all artworks of the given user that belong to the given category
      // If he does not have any artposts in that category ... then: query.get().docs == [] (empty list), or query.get().docs.isEmpty == true
      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      final snapshotOfAllLuckyUserArtPosts = await query.get();

      // if user has no artposts for a given category (if category has been provided),
      // or if the user has no active artposts at all:
      if (snapshotOfAllLuckyUserArtPosts.docs.isEmpty==true)
        // we return null to signal the future exclusion of the user, mark user ineligible
        return null;

      // if the user has the corresponding active artposts (of a given category or not):

      // Convert each artwork into an ArtPost model, and store them into a list, but:
      // - do not include already seen posts
      List<ArtPost> availablePosts = snapshotOfAllLuckyUserArtPosts.docs
          .map((doc) => ArtPost.fromFirestore(doc))
          .where((post) => !_seenPostIds.contains(post.id)) // the post must not exist in the list of already seen posts
          .toList();

      // If there are available active posts, but they've already been processed/displayed/seen
      // (they belong to the seenedPosts list):
      if (availablePosts.isEmpty)
        // we return null to signal the future exclusion of the users, mark user ineligible
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

  /// Generate a batch ([List] of [ArtPost] instances) of artworks for the feed.
  /// Returns [Null] when no more posts are available to return a Batch from...
  Future<List<ArtPost>?> generateFeedBatch({int batchSize = 5, String? category}) async {
    // Initialize the Pool if it has not been initialized.
    if (_userPool.isEmpty) {
      await _refreshUserPool();
    }

    List<ArtPost> newBatch = [];
    String contextKey = category ?? 'HOME';

    while (newBatch.length < batchSize) {
      // pick a user based on his weight (his AP chance)
      UserModel? selectedUser = _pickWeightedUser(category);

      // If selectedUser is null, it means every user in _userPool is now inside _ineligibleUsersMap for this context.
      // There is no unseen/available art left to fetch. We must break the loop.
      if (selectedUser == null) {
        if (_wasAbleToFetchUsersForPool) { // if we can further query users
          await _refreshUserPool(); // we append to the pool of users
          selectedUser = _pickWeightedUser(category); // and try selecting a user again
        }
        // if even now, we still have no available users, it means that have already extracted all possible users from the pool
        // now _hasMoreUsersInDB is false
        // So this means we have nothing left to display to the user
        // We break from while loop
        if (selectedUser == null) {
          break;
        }
      }

      // pick a post of user's, based on the weight of post (ammount of likes chance)
      final selectedPost = await _pickWeightedPost(selectedUser.uid, category);

      // if the user has no posts at all or no posts for a specififc category, we continue to next loop but also:
      if (selectedPost == null) {
        // the user was not able to return a post for the given category/home_feed
        // so we mark him ineligible
        _ineligibleUsersMap.putIfAbsent(contextKey, () => {}).add(selectedUser.uid);
        continue; // go to next loop
      }

      // but if we picked a user and a post of his:
      // we mark the post as seened already by adding it to the list of seened posts
      // we do this to prevent seeing the post again for the current run of the feed
      _seenPostIds.add(selectedPost.id);
      // add the post to the batch of ArtPost instances that the user will see in his feed
      newBatch.add(selectedPost);
    }

    // When the batch is empty it means there were no more available users with available content to display
    // we return null to signal the end of the feed for the given category/home_feed
    if (newBatch.isEmpty) return null;

    // otherwise we can return the batch of ArtPost instances
    return newBatch;
  }
}