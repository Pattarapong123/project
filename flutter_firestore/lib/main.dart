import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'Login.dart';
import 'FirstPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
        apiKey: "AIzaSyDGIn_tdrEbAPHFx2JZ6dhrmRq_-2f0lfo",
        authDomain: "flutterfirestore-433f3.firebaseapp.com",
        projectId: "flutterfirestore-433f3",
        storageBucket: "flutterfirestore-433f3.appspot.com",
        messagingSenderId: "768975476942",
        appId: "1:768975476942:web:a313724173e979e99fd89f"),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ระบบบริหารจัดการอพาร์ตเมนต์',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthCheck(), // เช็คว่าควรไปหน้า Login หรือ Dashboard
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          return const FirstPage(); // ไปหน้า Dashboard ถ้าล็อกอินแล้ว
        } else {
          return const Login(); // ไปหน้า Login ถ้ายังไม่ได้ล็อกอิน
        }
      },
    );
  }
}