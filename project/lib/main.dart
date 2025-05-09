import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:project/screens/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "AIzaSyB1M_SiKO6ESYwt3OqHPOQ3C12UoONyDJ8",
          authDomain: "itcs444-90329.firebaseapp.com",
          projectId: "itcs444-90329",
          storageBucket: "itcs444-90329.firebasestorage.app",
          messagingSenderId: "1038504579453",
          appId: "1:1038504579453:web:d5c6db608b07e63f067c14",
          measurementId: "G-P30QQP25EY"));

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen());
  }
}
