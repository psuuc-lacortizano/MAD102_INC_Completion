import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthServices {
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  Future<String?> signUp(String email, String password, String name) async {
    try {
      final cred = await auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final user = cred.user;
      if (user != null) {
        await firestore.collection('users').doc(user.uid).set({
          'email': email,
          'name': name,
          'friends': [],
          'locationSharing': false,
          'friendRequests': {'sent': [], 'received': []},
        });
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'The email is already in use. Please try another email address.';
      } else if (e.code == 'weak-password') {
        return 'The password is too weak. Please choose a stronger password.';
      } else if (e.code == 'invalid-email') {
        return 'Please enter a valid email address.';
      }
      return 'An error occurred during signup. Please try again later.';
    } catch (e) {
      return 'Unexpected error occurred: $e';
    }
  }

  Future<User?> login(String email, String password) async {
    try {
      final cred = await auth.signInWithEmailAndPassword(
          email: email, password: password);
      return cred.user;
    } on FirebaseAuthException catch (e) {
      print("Error Code: ${e.code}");
      if (e.code == 'invalid-credential') {
        throw 'The provided credentials are invalid. Please check your email and password.';
      } else if (e.code == 'invalid-email') {
        throw 'Please enter a valid email address.';
      } else {
        throw 'An error occurred during login. Please try again later.';
      }
    } catch (e) {
      throw 'Unexpected error occurred: $e';
    }
  }

  Future<void> signout() async {
    try {
      await auth.signOut();
    } catch (e) {
      throw 'An error occurred while signing out. Please try again later.';
    }
  }

  String? getCurrentUserId() {
    try {
      return auth.currentUser?.uid;
    } catch (e) {
      throw 'Unable to retrieve user ID. Please try again later.';
    }
  }
}
