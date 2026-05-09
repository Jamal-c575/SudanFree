import 'package:cloud_firestore/cloud_firestore.dart';

enum AdMediaType { image, video, gif }

/// نوع الإعلان — يحدد شكل العرض والموقع
enum AdPlacement {
  /// بانر أفقي في الرئيسية (إعلان اليوم)
  homeBanner,
  /// كارت صغير ضمن تغذية المجتمع
  communityFeed,
  /// إعلان مميز في قسم الخدمات
  featuredService,
  /// إعلان متجر مميز
  featuredShop,
  /// بانر شريطي صغير (text + CTA)
  strip,
}

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
  final AdPlacement placement;
  final String? advertiserName;
  final int impressions;
  final int clicks;

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
    this.placement = AdPlacement.homeBanner,
    this.advertiserName,
    this.impressions = 0,
    this.clicks = 0,
  });

  factory AdModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      mediaUrl: data['mediaUrl'] ?? data['imageUrl'] ?? '',
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
      placement: AdPlacement.values.firstWhere(
        (e) => e.name == data['placement'],
        orElse: () => AdPlacement.homeBanner,
      ),
      advertiserName: data['advertiserName'],
      impressions: data['impressions'] ?? 0,
      clicks: data['clicks'] ?? 0,
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
      'placement': placement.name,
      'advertiserName': advertiserName,
      'impressions': impressions,
      'clicks': clicks,
    };
  }

  bool get isValid => isActive && expiryDate.isAfter(DateTime.now());

  /// Get localized placement name
  String getPlacementName(String locale) {
    if (locale == 'ar') {
      switch (placement) {
        case AdPlacement.homeBanner: return 'بانر الرئيسية';
        case AdPlacement.communityFeed: return 'تغذية المجتمع';
        case AdPlacement.featuredService: return 'خدمة مميزة';
        case AdPlacement.featuredShop: return 'متجر مميز';
        case AdPlacement.strip: return 'شريط إعلاني';
      }
    }
    switch (placement) {
      case AdPlacement.homeBanner: return 'Home Banner';
      case AdPlacement.communityFeed: return 'Community Feed';
      case AdPlacement.featuredService: return 'Featured Service';
      case AdPlacement.featuredShop: return 'Featured Shop';
      case AdPlacement.strip: return 'Strip Banner';
    }
  }
}
