import 'dart:io';
import 'package:art_platform/core/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

/// Establishes specific methods through which you can communicate with the Firebase Storage SDK
class StorageRepository {
  // Establish connection with Firebase Storage SDK
  final FirebaseStorage _storage = FirebaseStorage.instance;



  /// Upload art to Firebase Storage.
  /// Requires the Post to be convert to binary code ([fileBytes] of type [Unit8List]).
  /// You also need to provide a unique name for the post ([fileName] of type [String]).
  /// The method will upload the post to Firebase Storage, and also return the link
  /// for download/access.
  ///
  /// Important to note, that we need different behaviour on wether we are uploading from phone
  /// or web browsers.
  ///
  /// If a user tries to upload a massive 500MB 4K video from their iPhone, readAsBytes() will try to
  /// load all 500MB into the phone's RAM all at once. The app will almost certainly crash
  /// with an "Out of Memory" error.
  ///
  /// So to prevent this, we will use [kIsWeb] to check wether we are on web or not.
  Future<String> uploadMedia(XFile? file, {required FolderPathEnum folderPath, void Function(double progress)? onProgress}) async {
    if(file == null) {
      throw Exception("'file' is null...");
    }

    // name of file
    String fileName = file.name;

    // A unique name for the Document on Firebase Storage must be provided
    // Because we need to differentiate between posts...
    final String uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';

    // get MIME file type
    final String? fileMIMEtype = lookupMimeType(fileName);
    if(fileMIMEtype==null) {
      throw Exception("ERROR | MIME type of file to upload is 'null'...");
    } else {
      debugPrint("SUCCESS: FILE TYPE IS: $fileMIMEtype");
    }

    // Reference to the documents within the artworks collection on Firebase Storage
    // It also creates a new document with the given name if one does not exist
    final Reference ref = _storage.ref().child('${folderPath.name}/$uniqueFileName');

    // We explicitly tell Firebase what the MIME type is, otherwise it might save as 'application/octet-stream'.
    // 'ownerUid' marks who uploaded the file. The Storage Security Rules require it on upload,
    // and use it to make sure only the uploader (or an admin) can delete the file.
    final metadata = SettableMetadata(
      contentType: fileMIMEtype,
      customMetadata: {'ownerUid': FirebaseAuth.instance.currentUser!.uid},
    );

    UploadTask task;
    try {
      // Branch the logic based on the platform
      if (kIsWeb) { // if we are on web
        // WEB: We must use bytes. Browsers handle memory differently, so this is safe.
        final Uint8List fileBytes = await file.readAsBytes();
        task = ref.putData(fileBytes, metadata);
      } else {
        // MOBILE: We use the physical File path.
        task = ref.putFile(File(file.path), metadata);
      }

      // LISTEN TO PROGRESS
      task.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (onProgress != null) {
          double progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        }
      });

      // WAIT UNTIL FINISHED
      final TaskSnapshot snapshot = await task;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint("Uploaded successfully to: $downloadUrl");
      // We return the downloadUrl
      return downloadUrl;
    } catch (e) {
      debugPrint("UPLOAD FAILED (See Network Tab for details)");
      throw Exception("Upload failed. Check the browser console.");
    }
  }

  Future<void> deleteMediaFromUrl(String url) async {
    final ref = FirebaseStorage.instance.refFromURL(url);
    await ref.delete();
  }
}