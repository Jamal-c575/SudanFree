import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionModel {
  final String id;
  final String userId;
  final String plan; // e.g. "Pro"
  final String status; // "pending", "active", "rejected"
  final String? receiptUrl;
  final DateTime createdAt;
  final DateTime? validUntil;

  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.plan,
    required this.status,
    this.receiptUrl,
    required this.createdAt,
    this.validUntil,
  });

  factory SubscriptionModel.fromMap(String id, Map<String, dynamic> map) {
    return SubscriptionModel(
      id: id,
      userId: map['userId'] ?? '',
      plan: map['plan'] ?? 'Pro',
      status: map['status'] ?? 'pending',
      receiptUrl: map['receiptUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      validUntil: (map['validUntil'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'plan': plan,
      'status': status,
      'receiptUrl': receiptUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      if (validUntil != null) 'validUntil': Timestamp.fromDate(validUntil!),
    };
  }
}
