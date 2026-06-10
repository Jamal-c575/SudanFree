import 'package:cloud_firestore/cloud_firestore.dart';

class RequestModel {
  final String id;
  final String clientId;
  final String clientName;
  final String? clientImageUrl;
  final String text;
  final String? imageUrl; // Legacy single image
  final List<String> imageUrls; // New: up to 3 images
  final String? audioUrl; // Voice record url
  final int? audioDuration; // Voice record duration in seconds
  final String? category;
  final String? state; // e.g. Khartoum
  final String? locality; // e.g. Omdurman
  final DateTime createdAt;
  final int offersCount;
  final bool isFulfilled; // Client marks it done or deletes

  RequestModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.clientImageUrl,
    required this.text,
    this.imageUrl,
    this.imageUrls = const [],
    this.audioUrl,
    this.audioDuration,
    this.category,
    this.state,
    this.locality,
    required this.createdAt,
    this.offersCount = 0,
    this.isFulfilled = false,
  });

  /// Get all image URLs (combines legacy imageUrl with new imageUrls)
  List<String> get allImageUrls {
    final List<String> urls = [];
    if (imageUrls.isNotEmpty) {
      urls.addAll(imageUrls);
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      urls.add(imageUrl!);
    }
    return urls;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'clientName': clientName,
      'clientImageUrl': clientImageUrl,
      'text': text,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'audioUrl': audioUrl,
      'audioDuration': audioDuration,
      'category': category,
      'state': state,
      'locality': locality,
      'createdAt': Timestamp.fromDate(createdAt),
      'offersCount': offersCount,
      'isFulfilled': isFulfilled,
    };
  }

  factory RequestModel.fromMap(Map<String, dynamic> map, String id) {
    return RequestModel(
      id: id,
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? 'عميل',
      clientImageUrl: map['clientImageUrl'],
      text: map['text'] ?? '',
      imageUrl: map['imageUrl'],
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      audioUrl: map['audioUrl'],
      audioDuration: map['audioDuration'],
      category: map['category'],
      state: map['state'],
      locality: map['locality'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      offersCount: map['offersCount'] ?? 0,
      isFulfilled: map['isFulfilled'] ?? false,
    );
  }
}
