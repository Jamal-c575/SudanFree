import 'package:cloud_firestore/cloud_firestore.dart';

enum AdMediaType { image, video, gif }

class AdModel {
  final String id;
  final String title;
  final String description;
  final String mediaUrl;
  final AdMediaType mediaType;
  final String? actionUrl;
  final String targetRegion; // 'all' for everyone
  final String targetProfession; // 'all' for everyone
  final int priority; // Higher number = higher priority
  final DateTime expiryDate;
  final DateTime createdAt;
  final bool isActive;

  AdModel({
    required this.id,
    required this.title,
    required this.description,
    required this.mediaUrl,
    this.mediaType = AdMediaType.image,
    this.actionUrl,
    this.targetRegion = 'all',
    this.targetProfession = 'all',
    this.priority = 0,
    required this.expiryDate,
    required this.createdAt,
    this.isActive = true,
  });

  factory AdModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      mediaUrl: data['mediaUrl'] ?? '',
      mediaType: AdMediaType.values.firstWhere(
        (e) => e.name == data['mediaType'],
        orElse: () => AdMediaType.image,
      ),
      actionUrl: data['actionUrl'],
      targetRegion: data['targetRegion'] ?? 'all',
      targetProfession: data['targetProfession'] ?? 'all',
      priority: data['priority'] ?? 0,
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 1)),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType.name,
      'actionUrl': actionUrl,
      'targetRegion': targetRegion,
      'targetProfession': targetProfession,
      'priority': priority,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  bool get isValid => isActive && expiryDate.isAfter(DateTime.now());
}
