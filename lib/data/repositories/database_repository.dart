import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/art_post.dart';

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
  /// The method requires a [title], [description] and [imageUrl] (all Strings) in order to be called.
  Future<void> uploadArt({
    required String title,
    required String description,
    required String imageUrl,
    required String category,
  }) async {
    final user = _auth.currentUser; // we fetch the current User, if any (can also be null)
    if (user == null) { // Exception Error. User is not logged in, therfore cannot upload
      throw Exception("You must be logged in to post art.");
    }

    try {
      final profile = await getUserProfileData(user.uid); // fetch data of the current user Map<String, dynamic>
      // profile? can return null if profile is null (we user ? cause otherwise it would crash)
      // if not null, we return value of the displayName key
      // if null, we return the String chunk of the user's email up to the '@' character
      final String authorName = profile?['displayName'] ?? user.email!.split('@')[0];
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
        'title': title, // received as method parameter
        'description': description, // received as method parameter
        'category': category,
        'imageUrl': imageUrl, // received as method parameter
        'userId': user.uid, // the user id of the authenticated user
        'authorName': authorName, // fetched from the authenticated user's document data on Firestore
        'authorAvatar': avatarUrl, // fetched from the authenticated user's document data on Firestore
        'createdAt': FieldValue.serverTimestamp(), // create a timestamp for when this document/post was added
        'likes': 0, //! number of likes currently hardcoded
      });
    } catch (e) { // Something went wrong while trying to upload to Firestore database
      print("DATABASE ERROR: $e");
      throw Exception("Failed to upload to database");
    }
  }

  /// The feed which contains the posts that appear on the HomeScreen
  ///
  /// Fetch a List of ArtPost objects [List<ArtPost>], where each ArtPost object is an instantiation
  /// containing the data of it's corresponding document from the 'artworks' collection on Firestore.
  Stream<List<ArtPost>> getHomeFeedPosts() {
    return _db
        .collection('artworks') // We select the 'artworks' collection from Firestore
        .orderBy('createdAt', descending: true) // we order the documents/posts within the collection by the time of upload, in descending order
        .snapshots() // Configure a Stream that returns the full list of documents (QuerySnapshot<Map<String, dymaic>>), anytime changes within the list of documents occur.
        .map((snapshot) { // Given the list of documents (snapshot.docs), make a new list, where each document is replaced with a ArtPost object containing the document's data
          //After that, return the Stream made out of this List
      return snapshot.docs.map((doc) => ArtPost.fromFirestore(doc)).toList();
    });
  }

  /// The feed which contains the posts that appear on the CategoryFeedScreen. Must provide [category]
  /// such that the app knows the category type of ArtPosts that is to be displayed.
  ///
  /// Fetch a List of ArtPost objects [List<ArtPost>], where each ArtPost object is an instantiation
  /// containing the data of it's corresponding document from the 'artworks' collection on Firestore.
  Stream<List<ArtPost>> getCategoryFeedPosts({required String category}) {
    return _db
        .collection('artworks') // Always target the main collection
        .where('category', isEqualTo: category) // Filter the documents by category
        .orderBy('createdAt', descending: true) // Order the filtered results
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ArtPost.fromFirestore(doc)).toList();
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
      if (displayName != null) updates['profileName'] = displayName;
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

  Future<int> fetchNumberOfUserPosts(String userId) async{
    // in case of argument userId == 'me', the targetID becomes the Current User's ID
    // otherwise, targetId becomes userId passed as argument
    final String? targetId = (userId == 'me') ? _auth.currentUser?.uid : userId;

    // Computing the number of posts based on how many posts with the given userId are present in the
    // artworks collection

    AggregateQuerySnapshot snapshot = await _db.collection('artworks').where('userId', isEqualTo: targetId).count().get();
    int numberOfPosts = snapshot.count!;

    return numberOfPosts;
    }
}