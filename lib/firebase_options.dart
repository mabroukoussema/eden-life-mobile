import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAlPOCHioQb57BXRpgD_0f8i7r1WcHuN7A',
    appId: '1:916092550411:web:0ed11cb7208525faae360e',
    messagingSenderId: '916092550411',
    projectId: 'final-base-99d49',
    authDomain: 'final-base-99d49.firebaseapp.com',
    databaseURL: 'https://final-base-99d49-default-rtdb.firebaseio.com',
    storageBucket: 'final-base-99d49.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDGCdfUFXXX3MZ1Ep61Vp8n40Kxg_WIwjw',
    appId: '1:916092550411:android:c1926d71cf5c37e2ae360e',
    messagingSenderId: '916092550411',
    projectId: 'final-base-99d49',
    databaseURL: 'https://final-base-99d49-default-rtdb.firebaseio.com',
    storageBucket: 'final-base-99d49.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAOTAsF6TzM7DQonzaKX6u3OH1IolCcdEg',
    appId: '1:916092550411:ios:e7255307fa36e052ae360e',
    messagingSenderId: '916092550411',
    projectId: 'final-base-99d49',
    databaseURL: 'https://final-base-99d49-default-rtdb.firebaseio.com',
    storageBucket: 'final-base-99d49.firebasestorage.app',
    iosBundleId: 'com.edenlife.edenLife',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAOTAsF6TzM7DQonzaKX6u3OH1IolCcdEg',
    appId: '1:916092550411:ios:e7255307fa36e052ae360e',
    messagingSenderId: '916092550411',
    projectId: 'final-base-99d49',
    databaseURL: 'https://final-base-99d49-default-rtdb.firebaseio.com',
    storageBucket: 'final-base-99d49.firebasestorage.app',
    iosBundleId: 'com.edenlife.edenLife',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAlPOCHioQb57BXRpgD_0f8i7r1WcHuN7A',
    appId: '1:916092550411:web:48beb522a5096268ae360e',
    messagingSenderId: '916092550411',
    projectId: 'final-base-99d49',
    authDomain: 'final-base-99d49.firebaseapp.com',
    databaseURL: 'https://final-base-99d49-default-rtdb.firebaseio.com',
    storageBucket: 'final-base-99d49.firebasestorage.app',
  );

}