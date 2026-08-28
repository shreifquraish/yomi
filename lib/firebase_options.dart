import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return android;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not configured for platforms other than Android.',
    );
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCLOG_y76cnfjVceEhfxB-lqNfUv2o0mjk',
    appId: '1:39806619922:android:6006a7babf2df3d9cc23cb',
    messagingSenderId: '39806619922',
    projectId: 'doto-188df',
    storageBucket: 'doto-188df.firebasestorage.app',
  );
}
