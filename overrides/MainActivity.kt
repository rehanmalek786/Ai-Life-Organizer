package com.ailifeorganizer.ai_life_organizer

import io.flutter.embedding.android.FlutterFragmentActivity

// local_auth (used by the Vault's device-authentication lock) requires the
// host Activity to be a FlutterFragmentActivity rather than the default
// FlutterActivity, so this replaces the one flutter create generates.
class MainActivity : FlutterFragmentActivity()

