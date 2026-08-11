#!/bin/bash
set -e

API_KEY=$(jq -r '.client[0].api_key[0].current_key' google-services.json)
APP_ID=$(jq -r '.client[0].client_info.mobilesdk_app_id' google-services.json)
SENDER_ID=$(jq -r '.project_info.project_number' google-services.json)
PROJECT_ID=$(jq -r '.project_info.project_id' google-services.json)
STORAGE_BUCKET=$(jq -r '.project_info.storage_bucket' google-services.json)

mkdir -p lib
cat > lib/firebase_options.dart << EOF
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
        throw UnsupportedError('Only Android is configured in this project.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '$API_KEY',
    appId: '$APP_ID',
    messagingSenderId: '$SENDER_ID',
    projectId: '$PROJECT_ID',
    storageBucket: '$STORAGE_BUCKET',
  );
}
EOF

echo "Generated lib/firebase_options.dart from google-services.json"
