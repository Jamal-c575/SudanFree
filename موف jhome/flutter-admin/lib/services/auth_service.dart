// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// تسجيل الدخول
  Future<User?> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // تحقق من الصلاحية في مجموعة admins
    final adminDoc = await _db.collection('admins').doc(credential.user!.uid).get();
    if (!adminDoc.exists || !adminDoc.data()!.containsKey('isActive') || !adminDoc.data()!['isActive']) {
      await _auth.signOut();
      throw Exception('هذا الحساب ليس لديه صلاحية الوصول للوحة التحكم');
    }

    // تحديث آخر دخول
    await _db.collection('admins').doc(credential.user!.uid).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
    });

    return credential.user;
  }

  /// تسجيل الخروج
  Future<void> signOut() => _auth.signOut();

  /// هل المستخدم الحالي أدمن؟
  Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final doc = await _db.collection('admins').doc(user.uid).get();
    return doc.exists && doc.data()?['isActive'] == true;
  }

  /// الحصول على بيانات الأدمن
  Future<Map<String, dynamic>?> getCurrentAdminData() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('admins').doc(user.uid).get();
    return doc.data();
  }
}