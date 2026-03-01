import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

/// Establishes specific methods through which you can communicate with the Firebase Storage SDK
class StorageRepository {
  // Establish connection with Firebase Storage SDK
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload art to Firebase Storage.
  /// Requires the Post to be convert to binary code ([fileBytes] of type [Unit8List]).
  /// You also need to provide a unique name for the post ([fileName] of type [String]).
  /// The method will upload the post to Firebase Storage, and also return the link
  /// for download/access.
  Future<String> uploadArt(Uint8List fileBytes, String fileName) async {
    try {
      // Reference to the documents within the artworks collection on Firebase Storage
      // It also creates a new document with the given name if one does not exist
      final Reference ref = _storage.ref().child('artworks/$fileName');

      // ? the metadata cause it's required but idk why
      final SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg');

      // ongoing upload task
      // .putData will overwrite data at the given reference
      // the reference may be an empty or non-empty document
      // if non-empty, it does not change the document, but the content of it
      final UploadTask task = ref.putData(fileBytes, metadata);

      // A [TaskSnapshot] is returned as the result of a Task [UploadTask] in our case...
      // That's why we use await.
      final TaskSnapshot snapshot = await task;

      // we fetch the reference from that snapshot, and get the downloadURL
      // I assume it is the same 'ref' from above. The reference to the new Post Document...
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // We return the downloadUrl
      return downloadUrl;
    } catch (e) {
      print("UPLOAD FAILED (See Network Tab for details)");

      throw Exception("Upload failed. Check the browser console.");
    }
  }
}