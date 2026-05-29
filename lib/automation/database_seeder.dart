import 'dart:math';
import 'package:art_platform/core/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faker/faker.dart';
import 'package:uuid/uuid.dart';

class DatabaseSeeder {
  // connection with Firestore Database to create users, usernames, and artposts
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // Create Random First/Last Names and Sentences
  final Faker _faker = Faker();
  // Can generate fake v4 user IDs
  final Uuid _uuid = const Uuid();
  // Used for random number generators
  final Random _random = Random();

  // The categories defined in constants.dart
  final List<String> _categories = artCategories;

  Future<void> runSeed() async {
    print("STARTING DATABASE SEED...");

    try {
      List<Map<String, dynamic>> generatedUsers = await _seedUsers(5);
      await _seedPosts(10, generatedUsers);
      // Optional: You can write a _seedFollows() method here later!

      print("SEED COMPLETE! Your database is now full of fake data.");
    } catch (e) {
      print("SEED FAILED: $e");
    }
  }


  Future<List<Map<String, dynamic>>> _seedUsers(int count) async {
    print("Generating $count fake users...");
    // store users data in 'users' list.
    List<Map<String, dynamic>> users = [];
    // WriteBatch - can accumulate a series of write operations to be performed on Firestore Database
    // Once you set all the commands you want to execute into the batch, you can commit the batch
    // which will make the commands run. After this, the batch will be no longer available. It's one time use.
    WriteBatch batch = _db.batch();

    // Create 'count' users:
    for (int i = 0; i < count; i++) {
      // Generate a fake Firebase Auth UID
      String uid = _uuid.v4();
      // Generate Random Username
      String username = _faker.person.firstName().toLowerCase() + _random.nextInt(999).toString();

      // Random number of points between 0 and 11,500 to test all ranks
      int randomPoints = _random.nextInt(11500);

      // Define user data
      Map<String, dynamic> userData = {
        "uid": uid,
        "username": username,
        "displayName": _faker.person.name(),
        "bio": _faker.lorem.sentence(),
        // Robohash generates a unique robot/monster avatar based on the text you pass it within link
        "avatarUrl": "https://robohash.org/$uid?set=set4",
        "createdAt": FieldValue.serverTimestamp(),
        "rank": 'rankless',
        "following": 0,
        "followers": 0,
        "posts": 0,
        "artist_points": randomPoints,
      };

      // Add the user to the list of created users
      users.add(userData);

      // Queue up the writes:
      // Set the batch to write the newly created user data into the user's newly created document
      DocumentReference userRef = _db.collection('users').doc(uid); // create a Document with the given 'uid' and also get the reference to it as 'userRef'
      batch.set(userRef, userData); // write the userData into the Created Document Reference

      // Also Set the batch to write the uid of the newly created user, within the username collection, in the document named after the user's username
      DocumentReference usernameRef = _db.collection('usernames').doc(username);
      batch.set(usernameRef, {"uid": uid});
    }

    // Commit all users to Firestore at once
    await batch.commit();

    print("Users seeded.");

    return users;
  }


  Future<void> _seedPosts(int count, List<Map<String, dynamic>> users) async {
    print("Generating $count fake art posts...");
    // Initialise WriteBatch
    WriteBatch batch = _db.batch();

    // Create 'count' posts
    for (int i = 0; i < count; i++) {
      // Pick a random user to be the author
      Map<String, dynamic> randomAuthor = users[_random.nextInt(users.length)];

      // We generate the DocumentReference first so we can use its auto-generated ID for the image URL
      DocumentReference postRef = _db.collection('artworks').doc();

      Map<String, dynamic> postData = {
        'mediaType': 'image',
        'title': _faker.lorem.words(3).join(' '),
        'description': _faker.lorem.sentences(3).join(' '),
        'category': _categories[_random.nextInt(_categories.length)],
        'mediaUrl': "https://picsum.photos/seed/${postRef.id}/800/800",
        'additionalMediaUrl': "default",
        'userId': randomAuthor['uid'],
        'authorName': randomAuthor['displayName'],
        'authorUsername': randomAuthor['username'],
        'authorAvatar': randomAuthor['avatarUrl'],
        'createdAt': FieldValue.serverTimestamp(), // Fixed field name
        'likes': _random.nextInt(500), // Kept random so you can test popular posts!
      };

      // Set batch to write postData to postRef
      batch.set(postRef, postData);

      // Update the author's post count and reward him artist points for uploading
      DocumentReference userRef = _db.collection('users').doc(randomAuthor['uid']);
      batch.update(userRef, {
        'posts': FieldValue.increment(1),
        'artist_points': FieldValue.increment(upload_artpost_artist_points_reward),
      });
    }

    // commit requests
    await batch.commit();
    print("Posts seeded.");
  }
}