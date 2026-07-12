import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/payment_method_model.dart';
import '../models/subscription_model.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<PaymentMethodModel>> getPaymentMethods() async {
    try {
      final doc = await _firestore.collection('admin_settings').doc('payment_methods').get();
      if (doc.exists && doc.data() != null) {
        final methodsList = doc.data()!['methods'] as List<dynamic>? ?? [];
        return methodsList.map((m) => PaymentMethodModel.fromMap(m as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching payment methods: $e');
      return [];
    }
  }

  Future<String> uploadReceipt(File imageFile, String userId) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_receipt.jpg';
    final ref = _storage.ref().child('receipts').child(userId).child(fileName);
    
    final uploadTask = await ref.putFile(imageFile);
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<void> submitSubscriptionRequest({
    required String plan,
    required String receiptUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final sub = SubscriptionModel(
      id: '',
      userId: user.uid,
      plan: plan,
      status: 'pending',
      receiptUrl: receiptUrl,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('subscriptions').add(sub.toMap());
  }

  Future<SubscriptionModel?> getCurrentPendingRequest() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final query = await _firestore
        .collection('subscriptions')
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return SubscriptionModel.fromMap(query.docs.first.id, query.docs.first.data());
    }
    return null;
  }
}
