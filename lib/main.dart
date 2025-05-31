import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/role_selection_page.dart';
import 'screens/patient_login_page.dart';
import 'screens/guardian_login_page.dart';
import 'screens/home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const HeartHealthApp());
}

class HeartHealthApp extends StatelessWidget {
  const HeartHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Heart Health Monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.red),
      initialRoute: '/',
      routes: {
        '/': (context) => const RoleSelectionPage(),
        '/patient-login': (context) => const PatientLoginPage(),
        '/guardian-login': (context) => const GuardianLoginPage(),
        // '/home' route will be accessed with arguments
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => HomePage(
              userId: args['userId'],
              isPatient: args['isPatient'],
            ),
          );
        }
        return null;
      },
    );
  }
}