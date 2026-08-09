import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// FILL THIS IN with your own Firebase project's values - see README.md
/// "Step 2: Connect Firebase" for exactly where to find each one.
/// The quickest way: open the google-services.json you downloaded from
/// Firebase Console and copy the matching fields listed in the comments
/// below into the strings here.
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
    // google-services.json -> client[0].api_key[0].current_key
    apiKey: 'YOUR_ANDROID_API_KEY',
    // google-services.json -> client[0].client_info.mobilesdk_app_id
    appId: 'YOUR_ANDROID_APP_ID',
    // google-services.json -> project_info.project_number
    messagingSenderId: 'YOUR_SENDER_ID',
    // google-services.json -> project_info.project_id
    projectId: 'YOUR_PROJECT_ID',
    // google-services.json -> project_info.storage_bucket
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );
}
