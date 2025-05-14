import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AuthPro {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  CollectionReference users = FirebaseFirestore.instance.collection('pro');

  Future<void> addUserToFirestore(String id, String name, String email) async {
    try {
      await users.doc(id).set({
        'uid': id,
        'fullname': name,
        'email': email,
      });
      print('User added to Firestore successfully!');
    } catch (error) {
      print('Error adding user to Firestore: $error');
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? users = result.user;
      if (users != null) {
        Fluttertoast.showToast(
            msg: "Login successfully",
            toastLength: Toast.LENGTH_LONG,
            fontSize: 13.0);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
      return false;
    }
  }

  Future<bool> createUserWithEmail(
      String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? users = result.user;
      if (users != null) {
        Fluttertoast.showToast(
            msg: "Signup successfully",
            toastLength: Toast.LENGTH_LONG,
            fontSize: 13.0);

        addUserToFirestore(users.uid, name, email);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
      return false;
    }
  }
}
