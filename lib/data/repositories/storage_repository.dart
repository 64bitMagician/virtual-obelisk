import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageRepository {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadArt(Uint8List fileBytes, String fileName) async {
    try {
      final Reference ref = _storage.ref().child('artworks/$fileName');

      final SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg');

      final UploadTask task = ref.putData(fileBytes, metadata);

      final TaskSnapshot snapshot = await task;

      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print("UPLOAD FAILED (See Network Tab for details)");

      throw Exception("Upload failed. Check the browser console.");
    }
  }
}