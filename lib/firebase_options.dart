import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
  }

  static const FirebaseOptions web = FirebaseOptions(
    // COPY THESE VALUES FROM YOUR BROWSER TAB:
    apiKey: 'AIzaSyDPeyntRftDs3CZw-ZD6FbqJHYojaW-pLs',
    authDomain: 'art-platform-878d0.firebaseapp.com',
    projectId: 'art-platform-878d0',
    storageBucket: 'art-platform-878d0.firebasestorage.app',
    messagingSenderId: '435347637026',
    appId: '1:435347637026:web:61f7acd0f2def26faa1b7b',
  );
}