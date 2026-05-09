import 'package:cloud_firestore/cloud_firestore.dart';

class PostReaction {
  static const String like = 'like';
  static const String love = 'love';
  static const String haha = 'haha';
  static const String wow = 'wow';
  static const String sad = 'sad';
  static const String angry = 'angry';
  
  static const List<String> values = [like, love, haha, wow, sad, angry];
}

enum PostCategory {
  general,
  question,
  help,
  announcement,
  discussion,
  buySell;

  String getName(String locale) {
    if (locale == 'ar') {
      switch (this) {
        case PostCategory.general: return 'عام';
        case PostCategory.question: return 'سؤال';
        case PostCategory.help: return 'مساعدة';
        case PostCategory.announcement: return 'إعلان';
        case PostCategory.discussion: return 'نقاش';
        case PostCategory.buySell: return 'بيع/شراء';
      }
    } else {
      switch (this) {
        case PostCategory.general: return 'General';
        case PostCategory.question: return 'Question';
        case PostCategory.help: return 'Help';
        case PostCategory.announcement: return 'Announcement';
        case PostCategory.discussion: return 'Discussion';
        case PostCategory.buySell: return 'Buy/Sell';
      }
    }
  }
} // End PostCategory Enum


class PostModel {
  final String id;
  final String userId;
  final String userName;
  final String? userRole;
  final String? userJobTitle;
  final String? userImageUrl;
  final String? imageUrl;
  final List<String> imageUrls;
  final String? caption;
  final String? category; 
  final List<String> mentionedUsers;
  final Map<String, String> reactions; // userId -> reactionType
  final int commentsCount;
  final int sharesCount;
  final bool showInCommunity;
  final bool showInProfile;
  final bool isPinned;
  final bool isUserVerified;
  final DateTime createdAt;
  final double? price;
  // ── Product-specific fields ──────────────────────────────────
  final List<String> productSizes;     // ['S','M','L','XL'] or custom
  final String? productCondition;      // 'new' | 'used'
  final String? productAgeGroup;       // 'baby' | 'child' | 'youth' | 'adult' | 'elderly'
  final List<String> productColors;    // ['أحمر','أزرق'] etc.
  final int? quantity;                 // كمية متاحة
  final bool hasShipping;              // هل يوجد توصيل

  PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userRole,
    this.userJobTitle,
    this.userImageUrl,
    this.imageUrl,
    this.imageUrls = const [],
    this.caption,
    this.category,
    this.mentionedUsers = const [],
    this.reactions = const {},
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.showInCommunity = true,
    this.showInProfile = true,
    this.isPinned = false,
    this.isUserVerified = false,
    required this.createdAt,
    this.price,
    this.productSizes = const [],
    this.productCondition,
    this.productAgeGroup,
    this.productColors = const [],
    this.quantity,
    this.hasShipping = false,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return PostModel.fromMap(data);
  }

  factory PostModel.fromMap(Map<String, dynamic> data) {
    return PostModel(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userRole: data['userRole'],
      userJobTitle: data['userJobTitle'],
      userImageUrl: data['userImageUrl'],
      imageUrl: data['imageUrl'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      caption: data['caption'],
      category: data['category'],
      mentionedUsers: List<String>.from(data['mentionedUsers'] ?? []),
      reactions: Map<String, String>.from(data['reactions'] ?? {}),
      commentsCount: data['commentsCount'] ?? 0,
      sharesCount: data['sharesCount'] ?? 0,
      showInCommunity: data['showInCommunity'] ?? true,
      showInProfile: data['showInProfile'] ?? false,
      isPinned: data['isPinned'] ?? false,
      isUserVerified: data['isUserVerified'] ?? false,
      // Handle Timestamp (Firestore) or String (JSON Cache)
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate()
          : data['createdAt'] is String 
              ? DateTime.parse(data['createdAt'])
              : DateTime.now(),
      price: (data['price'] as num?)?.toDouble(),
      productSizes: List<String>.from(data['productSizes'] ?? []),
      productCondition: data['productCondition'],
      productAgeGroup: data['productAgeGroup'],
      productColors: List<String>.from(data['productColors'] ?? []),
      quantity: data['quantity'] as int?,
      hasShipping: data['hasShipping'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'userJobTitle': userJobTitle,
      'userImageUrl': userImageUrl,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'caption': caption,
      'mentionedUsers': mentionedUsers,
      'reactions': reactions,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'showInCommunity': showInCommunity,
      'showInProfile': showInProfile,
      'isPinned': isPinned,
      'isUserVerified': isUserVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      if (price != null) 'price': price,
      if (productSizes.isNotEmpty) 'productSizes': productSizes,
      if (productCondition != null) 'productCondition': productCondition,
      if (productAgeGroup != null) 'productAgeGroup': productAgeGroup,
      if (productColors.isNotEmpty) 'productColors': productColors,
      if (quantity != null) 'quantity': quantity,
      if (hasShipping) 'hasShipping': hasShipping,
    };
    if (category != null) {
      map['category'] = category;
    }
    return map;
  }

  // JSON Map for Hive Cache
  Map<String, dynamic> toJsonMap() {
    final map = toFirestore();
    map['id'] = id;
    map['createdAt'] = createdAt.toIso8601String();
    return map;
  }

  /// Returns all image URLs (merges legacy imageUrl + imageUrls list)
  List<String> get allImageUrls {
    final urls = <String>[];
    if (imageUrl != null && imageUrl!.isNotEmpty) urls.add(imageUrl!);
    for (final url in imageUrls) {
      if (!urls.contains(url)) urls.add(url);
    }
    return urls;
  }

  int get totalReactions => reactions.length;

  String? getUserReaction(String userId) => reactions[userId];

  PostModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userRole,
    String? userJobTitle,
    String? userImageUrl,
    String? imageUrl,
    List<String>? imageUrls,
    String? caption,
    String? category,
    List<String>? mentionedUsers,
    Map<String, String>? reactions,
    int? commentsCount,
    int? sharesCount,
    bool? isPinned,
    bool? isUserVerified,
    bool? showInCommunity,
    bool? showInProfile,
    DateTime? createdAt,
    double? price,
    List<String>? productSizes,
    String? productCondition,
    String? productAgeGroup,
    List<String>? productColors,
    int? quantity,
    bool? hasShipping,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      userJobTitle: userJobTitle ?? this.userJobTitle,
      userImageUrl: userImageUrl ?? this.userImageUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      caption: caption ?? this.caption,
      category: category ?? this.category,
      mentionedUsers: mentionedUsers ?? this.mentionedUsers,
      reactions: reactions ?? this.reactions,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      showInCommunity: showInCommunity ?? this.showInCommunity,
      showInProfile: showInProfile ?? this.showInProfile,
      isPinned: isPinned ?? this.isPinned,
      isUserVerified: isUserVerified ?? this.isUserVerified,
      createdAt: createdAt ?? this.createdAt,
      price: price ?? this.price,
      productSizes: productSizes ?? this.productSizes,
      productCondition: productCondition ?? this.productCondition,
      productAgeGroup: productAgeGroup ?? this.productAgeGroup,
      productColors: productColors ?? this.productColors,
      quantity: quantity ?? this.quantity,
      hasShipping: hasShipping ?? this.hasShipping,
    );
  }
}
