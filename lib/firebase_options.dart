import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('This app is configured for Android only.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          '${defaultTargetPlatform.name} is not configured - only Android is set up in this project.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAxGnZgJyPJw9v7nc54t3MX__Ifs7u65Dg',
    appId: '1:725370601201:android:2cbe004f1cc6bb5be57350',
    messagingSenderId: '725370601201',
    projectId: 'ai-life-organizer-5f0ab',
    storageBucket: 'ai-life-organizer-5f0ab.firebasestorage.app',
  );
}
