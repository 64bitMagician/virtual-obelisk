import 'package:art_platform/data/models/art_post.dart';
import 'package:mime/mime.dart';

// Assuming you have your enum defined somewhere:
// enum MediaType { image, audio, video, text }

/// This method returns the [MediaType] corresponding to a file. You simply give it the name of the file.
MediaType determineMediaTypeFromFile(String? fileName) {
  if(fileName == null)
    throw Exception("fileName provided is 'null");

  print("ATTEMPTING TO GET THE MIME TYPE OF FILE...");
  // lookupMimeType returns a string like 'image/png' or 'audio/mp3'
  final String? mimeType = lookupMimeType(fileName);

  // If it can't figure it out, throw exception
  if (mimeType == null) {
    throw Exception('Unsupported file format');
  }

  // Return the correct enum based on the prefix
  if (mimeType.startsWith('image/')) {
    return MediaType.image;
  } else if (mimeType.startsWith('video/')) {
    return MediaType.video;
  } else if (mimeType.startsWith('audio/')) {
    return MediaType.audio;
  } else {
    throw Exception('File type not allowed for art posts.');
  }
}