import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUserData;
  UserModel? get currentUserData => _currentUserData;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<String?> loginWithMobilePassword(String mobile, String password) async {
    try {
      _setLoading(true);
      // Construct pseudo-email for Firebase Auth email/password login
      String pseudoEmail = '$mobile@gocampus.com';
      
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: pseudoEmail,
        password: password,
      );

      if (credential.user != null) {
        await fetchUserData(credential.user!.uid);
        _setLoading(false);
        return null; // Success (no error message)
      }
      _setLoading(false);
      return "Unknown error occurred";
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return e.message ?? "Authentication failed. Check your mobile and password.";
    } catch (e) {
      _setLoading(false);
      return e.toString();
    }
  }

  Future<void> fetchUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUserData = UserModel.fromMap(doc.data() as Map<String, dynamic>, uid);
        notifyListeners();
      } else {
        // user document empty
      }
    } catch (e) {
      // error fetching user data
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUserData = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
