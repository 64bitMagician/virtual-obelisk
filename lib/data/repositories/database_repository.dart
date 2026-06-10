import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:art_platform/data/models/art_post.dart';
import 'package:art_platform/core/constants.dart';

import '../models/art_chain.dart';

/// Responsible for all communication with Firestore Database
///
/// Contains methods for uploading art, fetching the feed, fetching user posts, fetching user profile data,
/// updating user profile data, and stream notification and return of user collection documents whenever
/// changes to that documents occur.
class DatabaseRepository {
  // Instantiation of Firebase Authentication and Firestore SDK connections
  final FirebaseFirestore _db = FirebaseFirestore.instance; // manages info about stored data (Ex: User Data, Artworks (Posts) Data)
  final FirebaseAuth _auth = FirebaseAuth.instance; // manages authentication

  /// This method is responsible for saving the uploaded content (the posts) unto the Firestore
  /// It is not the content itself, rather the information related to the post (document).
  /// The method requires a [title], [description] and [mediaUrl] (all Strings) in order to be called.
  Future<void> uploadMedia({
    required String mediaType,
    required String title,
    required String description,
    required String mediaUrl,
    required String category,
    String? additionalMediaUrl,
    String? chainId,
  }) async {
    final user = _auth.currentUser; // we fetch the current User, if any (can also be null)
    if (user == null) { // Exception Error. User is not logged in, therfore cannot upload
      throw Exception("You must be logged in to post art.");
    }

    try {
      print("IT TRIES TO UPLOAD!!!!!!!");
      final profile = await getUserProfileData(user.uid); // fetch data of the current user Map<String, dynamic>
      // profile? can return null if profile is null (we user ? cause otherwise it would crash)
      // if not null, we return value of the displayName key
      // if null, we return the String chunk of the user's email up to the '@' character
      final String authorName = profile?['displayName'];
      final String authorUsername = profile?['username'];
      // if not null, we return value of the avatarUrl key
      // if null, we return the uri bellow, with the uid of our user inserted within the uri
      // Since our 'uid's are hashed, every uid is unique, therefore, every link/uri will be unique
      // the link points to a website that generates unique PNGs based on
      // the text used after "https://robohash.org/"
      // Each text is a unique PNG
      // the set=set4 query parameter points the website to generate a cat image
      // so this is used to generate unique random images for users that do not have a
      // profile avatar on their profile set
      final String avatarUrl = profile?['avatarUrl'];

      // Initialize a variable to reference the artworks collection on Firestore
      final CollectionReference artworksRef = _db.collection('artworks');

      // we add a new document to the artworks collection | Data type: Map<String, dynamic>
      // this document represents the post we are uploading
      await artworksRef.add({
        'additionalMediaUrl': additionalMediaUrl ?? "default",
        'authorAvatar': avatarUrl, // fetched from the authenticated user's document data on Firestore
        'authorName': authorName, // fetched from the authenticated user's document data on Firestore
        'authorUsername': authorUsername,
        'category': category,
        'chainId': chainId,
        'createdAt': FieldValue.serverTimestamp(), // create a timestamp for when this document/post was added
        'description': description, // received as method parameter
        'isDeactivated': false,
        'likes': 0, //! number of likes currently hardcoded
        'mediaType': mediaType,
        'mediaUrl': mediaUrl, // received as method parameter
        'reportCount': 0,
        'title': title, // received as method parameter
        'userId': user.uid, // the user id of the authenticated user
      });
      // Increase Posts count at user document
      incrementUserPostCounter(user.uid);
      // Gain Artist Points (AP) as reward for uploading
      addArtistPointsForUploading(user.uid);
      // SIGNAL SUCCESS
      print("UPLOAD TO FIRESTORE 'ARTWORKS' DOCUMENT SUCCESFUL!");
    } on FirebaseException catch (e) { // Something went wrong while trying to upload to Firestore database
      // Catch the specific bouncer rejection (for time traveling exploit in chains <=> Uploading even tough chain is closed)
      if (e.code == 'permission-denied') {
        throw Exception("Upload rejected: This chain is closed or has expired.");
      }
      throw Exception("Database error: ${e.message}");
    } catch (e) {
      throw Exception("Failed to upload post: $e");
    }
  }

  /// Fetches a user's profile stream using their username instead of their UID
  Stream<Map<String, dynamic>?> getProfileStreamByUsername(String username) {
    return _db.collection('users')
        .where('username', isEqualTo: username)
        .limit(1) // Usernames are unique, so we only need the first match
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        // We inject the hidden UID into the map so we can use it to fetch posts later
        data['uid'] = snapshot.docs.first.id;
        return data;
      }
      return null; // Username not found
    });
  }

  /// Get a list of all the art posts [List<ArtPost>] of a specific user, by passing
  /// it's [userID] to the method.
  ///
  /// You can also pass 'me' as argument, to get the list of art posts of the current user
  Stream<List<ArtPost>> getUserPosts(String userId) {
    // in case of argument userId == 'me', the targetID becomes the Current User's ID
    // otherwise, targetId becomes userId passed as argument
    final String? targetId = (userId == 'me') ? _auth.currentUser?.uid : userId;

    // return Empty Stream if passed String Argument is null
    if (targetId == null) return const Stream.empty();

    // From the artworks collection
    // We select only the documents where the userId of the document matches the targetId
    // And those documents we order by order of their upload, in descending order
    // ??? We make a stream out of the document list, that returns that document list everytime
    // ??? changes to list occur (not changes within documents themselves)
    // Finally we create a new list, that converts the documents from the list, into ArtPost objects
    return _db
        .collection('artworks')
        .where('userId', isEqualTo: targetId)
        .where('isDeactivated', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ArtPost.fromFirestore(doc)).toList();
    });
  }

  /// Fetch the document containing all data related to the User with the corresponding 'uid',
  /// passed as an argument.
  /// After fetching the document, we only return the data (info about User) within that document.
  /// The data is returned under a [Map<String, dynamic>] type
  /// In case we cannot fetch the User document, or extract the data from it,
  /// the method will return [Null]
  Future<Map<String, dynamic>?> getUserProfileData(String uid) async {
    try {
      // On Firestore, from the 'users' (path) collection, the document corresponding to the received
      // 'uid' parameter, we get all that data in that document
      // In short: We fetch (also wait) the document corresponding to the user with the given 'uid' parameter
      // This document contains all data related to the user. We will call it "User Document".
      // The type of this document is: DocumentSnapshot<Map<String, dynamic>>
      final doc = await _db.collection('users').doc(uid).get();
      // we return just only the data of the document: Map<String, dynamic>
      return doc.data();
    } catch (e) { // Something went wrong while trying to fetch User Profile. We return null in that case.
      print("Error fetching profile: $e");
      return null; // we return null in this case
    }
  }

  /// This method updates a specific user's data (pass the [uid] String), with newly given
  /// [displayName], [bio] and [avatarUrl] (All Strings).
  ///
  /// Since the user's data has changed, so has to happen to the posts uploaded by the user.
  /// The posts/documents connected to the user (uid) have to be updated with the user's new data.
  Future<void> updateUserData({
    required String uid,
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      // We create the new data for the User Document
      // A timestamp of the moment this method is called
      final Map<String, dynamic> updates = {'updatedAt': FieldValue.serverTimestamp()};
      // set displayName
      if (displayName != null) updates['displayName'] = displayName;
      // set bio
      if (bio != null) updates['bio'] = bio;
      // set avatarUrl
      if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;

      // From users Firebase Collection, we get the document of the passed uid (User ID)
      // and merge the newly created data in 'updates' with the already existing document of the user
      await _db.collection('users').doc(uid).set(updates, SetOptions(merge: true));

      //* By this point, the user document should be updated with the new data
      //* Only problem is, that we also need to change the data of all posts uploaded by this user
      //* The posts have the old user data displaying, and we need to replace it with the new user data

      // if displayName or avatarUrl are not null:
      // within the artworks collection in Firestore, we get the list (QuerySnapshot<>) of all the Documents/Posts of our User (uid)
      if (displayName != null || avatarUrl != null) {
        final userPostsQuery = await _db
            .collection('artworks')
            .where('userId', isEqualTo: uid)
            .get();

        WriteBatch batch = _db.batch(); // some sort of writing tool for documents

        for (var doc in userPostsQuery.docs) { // iterate each post from the list of all posts of user
          // Initialize a variable with according document data format (Map<String, dynamic>)
          final Map<String, dynamic> postUpdates = {};
          // configure key-values for the new variable with the new data of the user that is to be overwritten
          // within the post documents of the user
          if (displayName != null) postUpdates['authorName'] = displayName;
          if (avatarUrl != null) postUpdates['authorAvatar'] = avatarUrl;
          // We overwrite the old values of the authorName and authorAvatar keys within the user's post document
          // with the new data of the user that is to be displayed with the post
          batch.update(doc.reference, postUpdates);
        }

        await batch.commit(); // We commit the changes within all of the updated/changed docs
      }

      print("Profile updated successfully.");
    } catch (e) {
      print("Error during profile update/sync: $e");
      throw Exception("Failed to update profile and synchronize posts.");
    }
  }

  /// This method selects a specific document from the user collection on Firestore, by feeding
  /// the method with the specific user id (String).
  /// But, instead of getting the data of the document only once, we are configuring a real-time stream.
  /// We will get notified about any changes within the document everytime changes occur, and also receive
  /// the data of the full, newly updated document.
  /// !This method returns only the data ([Map<String, dynamic>?]), and not the document itself!
  Stream<Map<String, dynamic>?> getProfileStream(String uid) {
    // We access the users collection within Firestore: _db.collection('users')
    // Select the document with the given user id: .doc(uid)
    // Configure a Stream that passes us the respective document everytime changes to it occur: .snapshots()
    // We get rid of the Document Object, and only extract the data from the document: .map((doc) => doc.data())
    // The document data is returned...
    return _db.collection('users').doc(uid).snapshots().map((doc) => doc.data());
  }

  /// This method simply checks if the user has it's profile set up.
  /// We use this method to decide wether to redirect the user to ProfileSetupScreen,
  /// or, if his profile is already configured, let him enter the app
  Future<bool> hasProfile(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    return doc.exists;
  }

  /// Checks if a user is following another user
  Future<bool> isFollowing(String currentUid, String targetUid) async {
    final doc = await _db.collection('users').doc(currentUid)
        .collection('following').doc(targetUid).get();
    return doc.exists;
  }

  /// Follows a user (creates a document in a subcollection)
  Future<void> followUser(String currentUid, String targetUid) async {
    // Add to current user's "following"
    await _db.collection('users').doc(currentUid)
    // now going into the 'following' subfolder of the authenticated user's document
        .collection('following').doc(targetUid).set({'timestamp': FieldValue.serverTimestamp()});

    // Add to target user's "followers"
    await _db.collection('users').doc(targetUid)
    // now going into the 'following' subfolder of the targeted user's document
        .collection('followers').doc(currentUid).set({'timestamp': FieldValue.serverTimestamp()});

    // SECURELY INCREMENT COUNTERS (queues the requests to follow such that there won't be two users
    // calling the follow function at the same time, which would result to unexpected behaviour)

    // Increase the current user's "following" count by 1
    await _db.collection('users').doc(currentUid).update({
      'following': FieldValue.increment(1)
    });

    // Increase the target user's "followers" count by 1
    // Also reward him artist points (AP) as reward for gaining one follower
    await _db.collection('users').doc(targetUid).update({
      'followers': FieldValue.increment(1),
      'artist_points': FieldValue.increment(gain_follower_artist_points_reward),
    });
  }

  /// Unfollows a user
  Future<void> unfollowUser(String currentUid, String targetUid) async {
    await _db.collection('users').doc(currentUid).collection('following').doc(targetUid).delete();
    await _db.collection('users').doc(targetUid).collection('followers').doc(currentUid).delete();

    // SECURELY DECREMENT COUNTERS
    // Decrease the current user's "following" count by 1 (using -1)
    await _db.collection('users').doc(currentUid).update({
      'following': FieldValue.increment(-1)
    });

    // Decrease the target user's "followers" count and deduct the points
    await _db.collection('users').doc(targetUid).update({
      'followers': FieldValue.increment(-1),
      'artist_points': FieldValue.increment(-gain_follower_artist_points_reward), // Deducting the exact reward amount
    });
  }

  /// Increment the user's 'posts' field. Also update the 'lastUploadAt' and 'hasActivePosts' fields
  Future<void> incrementUserPostCounter(String targetUid) async {
    await _db.collection('users').doc(targetUid).update({
      'posts': FieldValue.increment(1),
      // Save last time the user has uploaded
      'lastUploadAt': FieldValue.serverTimestamp(),
      // He just uploaded, so this guarantees the he has at least one active post:
      'hasActivePosts': true,
    });
  }

  Future<void> addArtistPointsForUploading(String targetUid) async {
    await _db.collection('users').doc(targetUid).update({
      'artist_points': FieldValue.increment(upload_artpost_artist_points_reward)
    });
  }

  // ============================================================================
  // REPORTING SYSTEM
  // ============================================================================

  /// Submit a report, as an authenticated user, for a specific artpost. Required [artworkId] and [reason] selection.
  Future<void> submitReport({
    required String artworkId,
    required String reason,
    String? additionalNotes,
  }) async {
    // get instance of current user
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception("You must be logged in to report.");

    // reference to reported artpost document in 'artworks' collection
    final DocumentReference artworkRef = _db.collection('artworks').doc(artworkId);
    // reference to generated report document associated to the artpost. ID is autogenerated.
    final DocumentReference reportRef = _db.collection('reports').doc();

    try {
      await _db.runTransaction((transaction) async {
        // Read the current state of the artpost document
        final DocumentSnapshot artworkDocumentSnapshot = await transaction.get(artworkRef);

        if (!artworkDocumentSnapshot.exists) {
          throw Exception("Artwork no longer exists.");
        }

        // extract data from artpost document snapshot as Map<String, dynamic>
        final data = artworkDocumentSnapshot.data() as Map<String, dynamic>;

        // Get reports count of the artpost and increment it
        final int currentReports = data['reportCount'] ?? 0;
        final int newReportCount = currentReports + 1;

        // THE THRESHOLD: If it hits 5 reports, auto-deactivate
        final bool shouldDeactivate = newReportCount >= 5;

        DocumentSnapshot? userSnapshot;
        DocumentReference? userRef;

        if (shouldDeactivate) {
          // get User Document of Reported User
          userRef = _db.collection('users').doc(data['userId']);
          // read the document
          userSnapshot = await transaction.get(userRef);
        }

        // Build the Report Document
        final Map<String, dynamic> reportData = {
          "reportId": reportRef.id,
          "artworkId": artworkId,
          "reporterUid": currentUser.uid,
          "reason": reason,
          "additionalNotes": additionalNotes ?? "",
          "timestamp": FieldValue.serverTimestamp(),
          "status": "pending", // Admins have to change this to 'resolved' or 'dismissed' later
          // THE ARTPOST DOCUMENT SNAPSHOT DATA
          "snapshot": {
            "mediaUrl": data['mediaUrl'] ?? "",
            "title": data['title'] ?? "Unknown Title",
            "authorUsername": data['authorUsername'] ?? "Unknown",
            "authorUid": data['userId'] ?? "",
          }
        };

        // Execute transaction | Write 'reportData' in 'reportRef' document
        transaction.set(reportRef, reportData);

        // Update the artwork document with the new report count and activation status
        transaction.update(artworkRef, {
          'reportCount': newReportCount,
          'isDeactivated': shouldDeactivate,
        });

        // If the post is about to get deactivated, and we have the User Document of the Reported User
        // And we have also have the read data from the document in 'userSnapshot':
        // We store the userData, and store the current number of active posts of user
        if (shouldDeactivate && userRef != null && userSnapshot != null) {
          final userData = userSnapshot.data() as Map<String, dynamic>?;
          final int currentPosts = userData?['posts'] ?? 0;

          // decrease from user's 'posts' count and update 'hasActivePosts' if
          // he has no more available active posts
          transaction.update(userRef, {
            'posts': FieldValue.increment(-1),
            'hasActivePosts': (currentPosts - 1) > 0,
          });
        }
      });

      print("Report successfully submitted!");

    } catch (e) {
      print("REPORT ERROR: $e");
      throw Exception("Failed to submit report.");
    }
  }

  /// ADMIN ONLY: Fetch all deactivated (because of reports) posts for the moderation queue
  Stream<List<ArtPost>> getDeactivatedPosts() {
    return _db
        .collection('artworks')
        .where('isDeactivated', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ArtPost.fromFirestore(doc)).toList();
    });
  }

  // ============================================================================
  // POST MANAGEMENT & MODERATION
  // ============================================================================

  /// Deletes a post entirely from the database, deducts the upload points, decrements from number of posts of user.
  /// [currentPostCount] is passed directly from the UI state to save a database read.
  Future<void> deletePost(String artworkId, String ownerUid, int currentPostCount) async {
    try {
      // Delete the actual post
      await _db.collection('artworks').doc(artworkId).delete();

      // Deduct the points from the user who uploaded it and decrement from 'posts' and update 'hasActivePosts'
      await _db.collection('users').doc(ownerUid).update({
        'artist_points': FieldValue.increment(-upload_artpost_artist_points_reward),
        'posts': FieldValue.increment(-1), // Safe atomic decrement
        'hasActivePosts': (currentPostCount - 1) > 0, // Automatically flips to false if user hits 0 active posts
      });
    } catch (e) {
      throw Exception("Failed to delete post: $e");
    }
  }

  /// ADMIN: Forces a post to be deactivated and hidden from the public feed
  Future<void> adminDeactivatePost(String artworkId, String ownerUid, int currentPostCount) async {
    try {
      // mark artwork as deactivated
      await _db.collection('artworks').doc(artworkId).update({
        'isDeactivated': true,
      });

      await _db.collection('users').doc(ownerUid).update({
        'posts': FieldValue.increment(-1),
        'hasActivePosts': (currentPostCount - 1) > 0, // mark if he has any active posts left
      });
    } catch (e) {
      throw Exception("Failed to deactivate post: $e");
    }
  }

  /// ADMIN: Reactivates a post and resets its report counter to 0
  Future<void> adminReactivatePost(String artworkId, String ownerUid) async {
    try {
      await _db.collection('artworks').doc(artworkId).update({
        'isDeactivated': false,
        'reportCount': 0,
      });

      await _db.collection('users').doc(ownerUid).update({
        'posts': FieldValue.increment(1), // get his incrementation of posts back
        'hasActivePosts': true, // we just reactivated post, so he has active posts for sure
      });
    } catch (e) {
      throw Exception("Failed to reactivate post: $e");
    }
  }

  /// Updates the text and category data of an existing art post
  Future<void> editPost(String artworkId, String newTitle, String newDescription, String newCategory) async {
    try {
      await _db.collection('artworks').doc(artworkId).update({
        'title': newTitle,
        'description': newDescription,
        'category': newCategory,
      });
    } catch (e) {
      throw Exception("Failed to edit post: $e");
    }
  }

  /// ADMIN ONLY: Fetches all reports submitted against a specific artwork
  Stream<List<Map<String, dynamic>>> getReportsForPost(String artworkId) {
    return _db.collection('reports')
        .where('artworkId', isEqualTo: artworkId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // ============================================================================
  // LIKES SYSTEM
  // ============================================================================

  /// Stream to check if the current user has liked this specific post
  Stream<bool> hasUserLikedPost(String artworkId, String userId) {
    return _db
        .collection('artworks')
        .doc(artworkId)
        .collection('likes')
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  /// Toggles the like status and rewards/deducts artist points
  Future<void> toggleLike(String artworkId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("Must be logged in to like.");

    final artworkRef = _db.collection('artworks').doc(artworkId);
    final likeRef = artworkRef.collection('likes').doc(uid);

    try {
      await _db.runTransaction((transaction) async {
        final likeSnapshot = await transaction.get(likeRef);
        final artworkSnapshot = await transaction.get(artworkRef);

        if (!artworkSnapshot.exists) throw Exception("Artwork not found.");

        final data = artworkSnapshot.data() as Map<String, dynamic>;
        final currentLikes = data['likes'] ?? 0;
        final String postOwnerId = data['userId']; // Get the creator's ID

        // Reference to the creator's user document
        final ownerRef = _db.collection('users').doc(postOwnerId);

        if (likeSnapshot.exists) {
          // UNLIKE SCENARIO
          transaction.delete(likeRef);
          transaction.update(artworkRef, {'likes': currentLikes - 1});
          // Deduct the point(s) from the owner
          transaction.update(ownerRef, {
            'artist_points': FieldValue.increment(-get_like_artist_points_reward)
          });
        } else {
          // LIKE SCENARIO
          transaction.set(likeRef, {'timestamp': FieldValue.serverTimestamp()});
          transaction.update(artworkRef, {'likes': currentLikes + 1});
          // Reward the point(s) to the owner
          transaction.update(ownerRef, {
            'artist_points': FieldValue.increment(get_like_artist_points_reward)
          });
        }
      });
    } catch (e) {
      throw Exception("Failed to toggle like: $e");
    }
  }

  // ============================================================================
  // CHAINS SYSTEM
  // ============================================================================

  /// ADMIN ONLY: Creates a new ArtChain prompt
  Future<void> createChain({
    required String title,
    required String description,
    required int lifespanDays,
    required List<String> categoryNodes,
  }) async {
    try {
      final expiresAt = DateTime.now().add(Duration(days: lifespanDays));

      await _db.collection('chains').add({
        'title': title,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'isClosed': false,
        'categoryNodes': categoryNodes,
      });
    } catch (e) {
      throw Exception("Failed to create chain: $e");
    }
  }

  /// ADMIN ONLY: Manually closes a chain early
  Future<void> closeChainEarly(String chainId) async {
    try {
      await _db.collection('chains').doc(chainId).update({
        'isClosed': true,
      });
    } catch (e) {
      throw Exception("Failed to close chain: $e");
    }
  }

  /// Fetches all Chains (Ordered by newest first)
  /// Client-side ArtChain model will handle the "is it expired?" logic
  Stream<List<ArtChain>> getAllChains() {
    return _db.collection('chains')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ArtChain.fromFirestore(doc)).toList());
  }

  /// Fetches all ArtPosts that belong to a specific Chain
  Stream<List<ArtPost>> getPostsForChain(String chainId) {
    // We use this for getting the post for the chain

    return _db.collection('artworks')
        .where('chainId', isEqualTo: chainId)
        .where('isDeactivated', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ArtPost.fromFirestore(doc)).toList());
  }

  /// Fetches a single ArtChain by its ID
  Stream<ArtChain> getChainById(String chainId) {
    return _db.collection('chains')
        .doc(chainId)
        .snapshots()
        .map((doc) => ArtChain.fromFirestore(doc));
  }

  /// Fetches ArtPosts for a specific node in a Chain
  Stream<List<ArtPost>> getChainNodePosts({required String chainId, required String category}) {
    // We use this such that when we open an artpost from a category on the chain, we get a
    // stream in MediaReader of artpost belonging only to that category of the selected artpost

    return _db.collection('artworks')
        .where('chainId', isEqualTo: chainId)
        .where('category', isEqualTo: category)
        .where('isDeactivated', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ArtPost.fromFirestore(doc)).toList());
  }

  /// Checks if the user has reached their daily upload limit
  Future<bool> canUserUploadToday(String uid, {int dailyLimit = 2}) async {
    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day); // today, but midnight, because no further data provided at construction

      // Query the database for posts by this user created after midnight
      final querySnapshot = await _db.collection('artworks')
          .where('userId', isEqualTo: uid)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(midnight))
          .get();

      // Return true if they haven't hit the limit yet
      return querySnapshot.docs.length < dailyLimit;
    } catch (e) {
      print("Error checking upload limit: $e");
      return false;
    }
  }
}