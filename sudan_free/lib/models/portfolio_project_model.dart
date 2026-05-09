import 'package:cloud_firestore/cloud_firestore.dart';

class PortfolioProjectModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final List<String> imageUrls;
  final List<String> videoUrls;
  final String? category;
  final DateTime createdAt;

  PortfolioProjectModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    this.imageUrls = const [],
    this.videoUrls = const [],
    this.category,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'imageUrls': imageUrls,
      'videoUrls': videoUrls,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PortfolioProjectModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PortfolioProjectModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      videoUrls: List<String>.from(data['videoUrls'] ?? []),
      category: data['category'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
