import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/role_selection_page.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Check if Firebase is already initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          databaseURL: 'https://moniter-66b79-default-rtdb.firebaseio.com/',
          apiKey: 'AIzaSyBWNQZU8qCvIV0o04MKjarA45_oQjYrQfY',
          appId: '1:176979030042:android:531d2d1f884cc82835e1a3',
          messagingSenderId: '176979030042',
          projectId: 'moniter-66b79',
          storageBucket: 'moniter-66b79.firebasestorage.app',
        ),
      );
    } else {
      // If Firebase is already initialized, get the default app
      Firebase.app();
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  runApp(const HeartHealthApp());
}

class HeartHealthApp extends StatelessWidget {
  const HeartHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Heart Health Monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const RoleSelectionPage(),
    );
  }
}