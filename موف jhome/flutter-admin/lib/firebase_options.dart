// lib/firebase_options.dart
// إعدادات Firebase - يجب ملؤها بـ flutterfire configure
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSy_YOUR_API_KEY',
    authDomain: 'jhome-sudanfree.firebaseapp.com',
    projectId: 'jhome-sudanfree',
    storageBucket: 'jhome-sudanfree.appspot.com',
    messagingSenderId: '1234567890',
    appId: '1:1234567890:web:abcdef123456',
  );
}