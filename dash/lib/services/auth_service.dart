import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Current User Reference
  User? get currentUser => _auth.currentUser;

  // 1. CREATE ACCOUNT (Firebase Auth + Firestore User Profile)
  Future<UserCredential> signUpWithEmail({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    // Firebase Auth account creation
    UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    String uid = credential.user!.uid;

    // Save User Document to Firestore
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'name': name.trim(),
      'phone': phone.trim(),
      'email': email.trim().toLowerCase(),
      'photoUrl': '', // Profile picture URL goes here after Storage upload
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'Online',
    });

    return credential;
  }

  // 2. SIGN IN WITH EMAIL
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // 3. SIGN IN WITH PHONE NUMBER & PASSWORD
  Future<UserCredential> signInWithPhone(String phone, String password) async {
    // Phone number එකට අදාළ email එක Firestore එකෙන් හොයා ගැනීම
    QuerySnapshot userQuery = await _db
        .collection('users')
        .where('phone', isEqualTo: phone.trim())
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) {
      throw Exception('No account found with this phone number.');
    }

    String associatedEmail = userQuery.docs.first.get('email');

    // Email/Password මගින් Auth සිදුවීම
    return await _auth.signInWithEmailAndPassword(
      email: associatedEmail,
      password: password,
    );
  }

  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }
}