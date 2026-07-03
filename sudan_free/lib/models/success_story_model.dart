import 'package:cloud_firestore/cloud_firestore.dart';

class SuccessStoryModel {
  final String id;
  final String userId;
  final String userName;
  final String userImage;
  final String title;
  final String content;
  final String? imageUrl;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;

  SuccessStoryModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.title,
    required this.content,
    this.imageUrl,
    this.status = 'pending',
    required this.createdAt,
  });

  factory SuccessStoryModel.fromMap(Map<String, dynamic> data, String id) {
    return SuccessStoryModel(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userImage: data['userImage'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
