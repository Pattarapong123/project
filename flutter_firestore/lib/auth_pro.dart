import 'package:firebase_auth/firebase_auth.dart';

class AuthPro {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      // สามารถ log ได้ถ้าจำเป็น เช่น print(e.code);
      return false;
    } catch (e) {
      // กรณี error อื่น ๆ
      return false;
    }
  }
}

