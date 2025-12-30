import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageRepository {
  // Get the instance of your bucket
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads raw data (bytes) and returns the public Download URL
  Future<String> uploadArt(Uint8List fileBytes, String fileName) async {
    try {
      // 1. Create a reference to where the file will live
      // We categorize by 'artworks' folder to keep things tidy
      final Reference ref = _storage.ref().child('artworks/$fileName');

      // 2. Upload the raw bytes
      // Set metadata so the browser knows it's an image (optional but good practice)
      final SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg');

      final UploadTask task = ref.putData(fileBytes, metadata);

      // 3. Wait for the upload to complete
      final TaskSnapshot snapshot = await task;

      // 4. Get the public link (URL)
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      // FIX: Do not print 'e' directly. It causes the crash on Web.
      print("⚠️ UPLOAD FAILED (See Network Tab for details)");

      // Throw a simple string exception, don't pass 'e' along
      throw Exception("Upload failed. Check the browser console.");
    }
  }
}