import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

import 'DataContainers/User.dart';

abstract class Auth {
  Future<User> getLoggedInUser();
  Future<String> signInWithEmailPassword(String email, String password);
  Future<String> createAccWithEmailPassword(String name, String email, String password);
  Future<void> updatePhoto(String photoUrl);
  Future<void> signOut();
  Future<String> currentUser();
  Stream<User> get onAuthStateChanged;
}

class FirebaseAuthentication implements Auth {

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<User> getLoggedInUser() async {
    FirebaseUser user = await _firebaseAuth.currentUser();
    if(user == null) {
      return Future.error(null);
    } else {
      return User(id: user.uid, name: user.displayName, email: user.email, photoUrl: user.photoUrl);
    }
  }

  Future<void> updatePhoto(String photoUrl) async {
    FirebaseUser user = await _firebaseAuth.currentUser();
    UserUpdateInfo updateProfile = UserUpdateInfo();
    updateProfile.photoUrl = photoUrl;
    await user.updateProfile(updateProfile);
  }

  @override
  Stream<User> get onAuthStateChanged {
    return _firebaseAuth.onAuthStateChanged.map((user) {
      return User(id: user.uid, name: user.displayName, email: user.email, photoUrl: user.photoUrl);
    });
  }

  @override
  Future<String> signInWithEmailPassword(String email, String password) async {
    try {
      FirebaseUser user = await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password)
          .then((result) => result.user);
      return user.uid;
    } catch (error) {
      print(error);
      return null;
    }
  }

  @override
  Future<String> createAccWithEmailPassword(String name, String email, String password) async {
    try {
      FirebaseUser user = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password)
          .then((result) => result.user);
      UserUpdateInfo updateProfile = UserUpdateInfo();
      updateProfile.displayName = name;
      await user.updateProfile(updateProfile);
      return user.uid;
    } catch (error) {
      print(error);
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<String> currentUser() async {
    FirebaseUser user = await _firebaseAuth.currentUser();
    return user.uid;
  }

}