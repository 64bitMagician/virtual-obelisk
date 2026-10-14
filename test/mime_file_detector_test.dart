import 'package:art_platform/core/mime_file_detector.dart';
import 'package:art_platform/data/models/art_post.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for [determineMediaTypeFromFile], which decides the media type of an uploaded file.
void main() {
  group('determineMediaTypeFromFile', () {
    test('detects images', () {
      expect(determineMediaTypeFromFile('painting.png', []), MediaType.image);
      expect(determineMediaTypeFromFile('photo.jpg', []), MediaType.image);
    });

    test('detects videos', () {
      expect(determineMediaTypeFromFile('dance.mp4', []), MediaType.video);
    });

    test('detects audio', () {
      expect(determineMediaTypeFromFile('song.mp3', []), MediaType.audio);
      expect(determineMediaTypeFromFile('track.wav', []), MediaType.audio);
    });

    test('detects text', () {
      expect(determineMediaTypeFromFile('poem.txt', []), MediaType.text);
    });

    test('rejects file types that are not allowed for art posts', () {
      expect(() => determineMediaTypeFromFile('document.pdf', []), throwsException);
    });

    test('rejects files without a recognizable format', () {
      expect(() => determineMediaTypeFromFile('no_extension', []), throwsException);
    });

    test('rejects a missing file name', () {
      expect(() => determineMediaTypeFromFile(null, []), throwsException);
    });
  });
}
