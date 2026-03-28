import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with [Firebase.initializeApp].
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAcniuITjkjqiNrosGniZ169Pnno68xuBg',
    appId: '1:88548335176:web:2b80c0f7376363109a427d',
    messagingSenderId: '88548335176',
    projectId: 'gocampus01-e0437',
    authDomain: 'gocampus01-e0437.firebaseapp.com',
    storageBucket: 'gocampus01-e0437.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAcniuITjkjqiNrosGniZ169Pnno68xuBg',
    appId: '1:88548335176:android:8e444696ea67a6a59a427d',
    messagingSenderId: '88548335176',
    projectId: 'gocampus01-e0437',
    storageBucket: 'gocampus01-e0437.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAcniuITjkjqiNrosGniZ169Pnno68xuBg',
    appId: '1:88548335176:ios:generate-this-on-firebase-console', // Placeholder until user provides iOS App ID
    messagingSenderId: '88548335176',
    projectId: 'gocampus01-e0437',
    storageBucket: 'gocampus01-e0437.firebasestorage.app',
    iosBundleId: 'com.gocampus.go_campus',
  );
}
