import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AdminRoleStatus {
  const AdminRoleStatus({
    required this.uid,
    required this.exists,
    required this.role,
    required this.isAdmin,
    this.error,
  });

  final String uid;
  final bool exists;
  final String? role;
  final bool isAdmin;
  final String? error;
}

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<AdminRoleStatus> adminRoleState(User user) {
    final uid = user.uid;
    debugPrint('Admin role listener: UID=$uid');
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      final exists = snapshot.exists;
      final roleValue = snapshot.data()?['role'];
      final role = roleValue is String ? roleValue : null;
      final isAdmin = exists && role == 'admin';
      debugPrint(
        'Admin role listener: UID=$uid, users/$uid exists=$exists, '
        'role=$role, roleRaw=$roleValue, roleType=${roleValue.runtimeType}, '
        'isAdmin=$isAdmin',
      );
      return AdminRoleStatus(
        uid: uid,
        exists: exists,
        role: role,
        isAdmin: isAdmin,
      );
    });
  }

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }

    await user.updateDisplayName(name.trim());
    await ensureUserProfile(user: user, name: name.trim());
    return credential;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user != null) {
      await ensureUserProfile(user: user, name: user.displayName);
    }
    return credential;
  }

  Future<void> ensureCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await ensureUserProfile(user: user, name: user.displayName);
  }

  Future<void> ensureUserProfile({required User user, String? name}) async {
    final reference = _firestore.collection('users').doc(user.uid);
    try {
      final existing = await reference.get();
      if (existing.exists) return;

      await reference.set({
        'uid': user.uid,
        'name': (name == null || name.trim().isEmpty)
            ? 'CommuteAlert User'
            : name.trim(),
        'email': user.email ?? '',
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      debugPrint(
        'User profile creation failed [${error.code}]: '
        '${error.message ?? 'unknown Firestore error'}',
      );
      rethrow;
    }
  }

  Future<void> signOut() => _auth.signOut();

  Stream<bool> adminStateChanges() {
    final user = _auth.currentUser;
    if (user == null) return Stream<bool>.value(false);
    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) => snapshot.data()?['role'] == 'admin');
  }

  Future<bool> isAdmin([User? user]) async {
    final account = user ?? _auth.currentUser;
    if (account == null) return false;
    final snapshot = await _firestore
        .collection('users')
        .doc(account.uid)
        .get();
    return snapshot.data()?['role'] == 'admin';
  }

  String friendlyError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Enter a valid email address.';
        case 'email-already-in-use':
          return 'An account already exists for this email.';
        case 'weak-password':
          return 'Use a stronger password with at least 6 characters.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email or password is incorrect.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'network-request-failed':
          return 'Check your internet connection and try again.';
        default:
          return error.message ?? 'Authentication failed. Please try again.';
      }
    }
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'Your account is not authorized to perform this action.';
      }
      return error.message ?? 'A Firestore error occurred.';
    }
    return 'Authentication failed. Please try again.';
  }
}
