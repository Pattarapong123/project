import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Login.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();

  // ฟังก์ชันสำหรับตรวจสอบรูปแบบของอีเมล
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
        r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"); // ตรวจสอบรูปแบบอีเมล
    return emailRegex.hasMatch(email);
  }

  void _resetPassword() async {
    final email = _emailController.text.trim();

    // เช็คว่าอีเมลว่างหรือไม่
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกอีเมล'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // ตรวจสอบรูปแบบของอีเมล
    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกอีเมลที่ถูกต้อง'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      // ตรวจสอบว่าอีเมลมีอยู่ใน Firestore หรือไม่
      final userSnapshot = await FirebaseFirestore.instance
          .collection('pro') // ใช้ collection 'pro'
          .where('email', isEqualTo: email) // ตรวจสอบว่าอีเมลตรงกันไหม
          .get();

      print("Number of documents found: ${userSnapshot.docs.length}"); // เพิ่มบรรทัดนี้เพื่อดีบัก

      // ถ้าไม่พบอีเมลใน Firestore
      if (userSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่พบอีเมลนี้ในระบบ กรุณาตรวจสอบอีเมลอีกครั้ง'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      // ถ้าอีเมลมีในระบบ Firebase, ส่งลิงก์รีเซ็ตรหัสผ่าน
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ระบบดำเนินการส่งลิ้งก์รีเซ็ตรหัสผ่านไปยังอีเมลเรียบร้อย'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      // จัดการข้อผิดพลาดจาก FirebaseAuthException
      String errorMessage = e.message ?? 'เกิดข้อผิดพลาดจาก Firebase Auth';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $errorMessage'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      // ข้อผิดพลาดทั่วไป
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "ลืมรหัสผ่าน",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "กรอกอีเมลที่ลงทะเบียนไว้เพื่อรับลิงก์รีเซ็ตรหัสผ่าน",
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: "อีเมล",
                      prefixIcon: const Icon(Icons.email),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "ส่งลิงก์รีเซ็ตรหัสผ่าน",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const Login()),
                      );
                    },
                    child: const Text(
                      "กลับไปหน้าเข้าสู่ระบบ",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
