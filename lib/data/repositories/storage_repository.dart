import 'dart:io';
import 'dart:typed_data';
import 'package:art_platform/core/constants.dart';
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
  Future<String> uploadMedia(XFile? file, {required FolderPathEnum folderPath}) async {
    if(file == null)
      throw Exception("'file' is null...");

    // name of file
    String fileName = file.name;

    // A unique name for the Document on Firebase Storage must be provided
    // Because we need to differentiate between posts...
    final String uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';

    // get MIME file type
    final String? fileMIMEtype = lookupMimeType(fileName);
    if(fileMIMEtype==null)
        throw Exception("ERROR | MIME type of file to upload is 'null'...");
    else
        print("SUCCESS: FILE TYPE IS: $fileMIMEtype");


    try {
      // Reference to the documents within the artworks collection on Firebase Storage
      // It also creates a new document with the given name if one does not exist
      final Reference ref = _storage.ref().child('${folderPath.name}/$uniqueFileName');

      TaskSnapshot snapshot;
      // Branch the logic based on the platform!
        if (kIsWeb) { // if we are on web
          // WEB: We MUST use bytes. Browsers handle memory differently, so this is safe.
          final Uint8List fileBytes = await file.readAsBytes();
          // We also need to explicitly tell Firebase what the MIME type is on Web,
          // otherwise it might save as 'application/octet-stream'
          final metadata = SettableMetadata(contentType: fileMIMEtype);

          // upload the actual data content to the file reference
          // ongoing upload task
          // .putData will overwrite data at the given reference
          // the reference may be an empty or non-empty document
          // if non-empty, it does not change the document, but the content of it
          // A [TaskSnapshot] is returned as the result of a Task [UploadTask] in our case...
          // That's why we use await.
          snapshot = await ref.putData(fileBytes, metadata);
        } else {
          // MOBILE: We use the physical File path.
          // This streams the file from the hard drive to Firebase, saving RAM!
          snapshot = await ref.putFile(File(file.path));
        }

      // we fetch the reference from that snapshot, and get the downloadURL
      // I assume it is the same 'ref' from above. The reference to the new Post Document...
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      print("Uploaded successfully to: $downloadUrl");
      // We return the downloadUrl
      return downloadUrl;
    } catch (e) {
      print("UPLOAD FAILED (See Network Tab for details)");
      throw Exception("Upload failed. Check the browser console.");
    }
  }

  Future<void> deleteMediaFromUrl(String url) async {
    final ref = FirebaseStorage.instance.refFromURL(url);
    await ref.delete();
  }
}