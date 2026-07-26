import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String email;
  final String photoUrl;
  final String status;

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.email,
    required this.photoUrl,
    required this.status,
  });

  // 1. Firestore Map එකක් UserModel object එකකට හරවන්න (Data කියවද්දී)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      status: map['status'] ?? 'Offline',
    );
  }

  // DocumentSnapshot එකකින් direkt Model එකක් හදන්න
  factory UserModel.fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;
    return UserModel.fromMap(snapshot);
  }

  // 2. UserModel Object එකක් Firestore Map එකකට හරවන්න (Data save කරද්දී)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'email': email,
      'photoUrl': photoUrl,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}