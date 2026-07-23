import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/safe_parse.dart';
import 'enums/post_enums.dart';

export 'enums/post_enums.dart';

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
  final List<String> productSizes; // ['S','M','L','XL'] or custom
  final String? productCondition; // 'new' | 'used'
  final String?
      productAgeGroup; // 'baby' | 'child' | 'youth' | 'adult' | 'elderly'
  final List<String> productColors; // ['أحمر','أزرق'] etc.
  final int? quantity; // كمية متاحة
  final bool hasShipping; // هل يوجد توصيل
  // ── Product Link (for community posts) ──────────────────────
  final String? linkedProductId; // رابط المنشور المنتج المرتبط
  final String? linkedProductName; // اسم المنتج للعرض السريع
  final String? linkedProductImage; // صورة المنتج المصغرة
  final double? linkedProductPrice; // سعر المنتج
  final int viewsCount; // عدد المشاهدات
  // ── Poll (استطلاع رأي) ──────────────────────────────────────
  final PollModel? poll;
  // ── Hashtags ────────────────────────────────────────────────
  final List<String> hashtags;

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
    this.linkedProductId,
    this.linkedProductName,
    this.linkedProductImage,
    this.linkedProductPrice,
    this.viewsCount = 0,
    this.poll,
    this.hashtags = const [],
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return PostModel.fromMap(data);
  }

  factory PostModel.fromMap(Map<String, dynamic> data) {
    return PostModel(
      id: SafeParse.string(data['id']),
      userId: SafeParse.string(data['userId']),
      userName: SafeParse.string(data['userName']),
      userRole: SafeParse.nullableString(data['userRole']),
      userJobTitle: SafeParse.nullableString(data['userJobTitle']),
      userImageUrl: SafeParse.nullableString(data['userImageUrl']),
      imageUrl: SafeParse.nullableString(data['imageUrl']),
      imageUrls: SafeParse.stringList(data['imageUrls']),
      caption: SafeParse.nullableString(data['caption']),
      category: SafeParse.nullableString(data['category']),
      mentionedUsers: SafeParse.stringList(data['mentionedUsers']),
      reactions: SafeParse.stringMap(data['reactions']),
      commentsCount: SafeParse.integer(data['commentsCount']),
      sharesCount: SafeParse.integer(data['sharesCount']),
      showInCommunity: SafeParse.boolean(data['showInCommunity'], true),
      showInProfile: SafeParse.boolean(data['showInProfile'], true),
      isPinned: SafeParse.boolean(data['isPinned']),
      isUserVerified: SafeParse.boolean(data['isUserVerified']),
      createdAt: SafeParse.dateTime(data['createdAt']),
      price: SafeParse.nullableDecimal(data['price']),
      productSizes: SafeParse.stringList(data['productSizes']),
      productCondition: SafeParse.nullableString(data['productCondition']),
      productAgeGroup: SafeParse.nullableString(data['productAgeGroup']),
      productColors: SafeParse.stringList(data['productColors']),
      quantity:
          data['quantity'] != null ? SafeParse.integer(data['quantity']) : null,
      hasShipping: SafeParse.boolean(data['hasShipping']),
      linkedProductId: SafeParse.nullableString(data['linkedProductId']),
      linkedProductName: SafeParse.nullableString(data['linkedProductName']),
      linkedProductImage: SafeParse.nullableString(data['linkedProductImage']),
      linkedProductPrice: SafeParse.nullableDecimal(data['linkedProductPrice']),
      viewsCount: SafeParse.integer(data['viewsCount']),
      poll: data['poll'] is Map
          ? (() {
              try {
                return PollModel.fromMap(
                    Map<String, dynamic>.from(data['poll'] as Map));
              } catch (_) {
                return null;
              }
            })()
          : null,
      hashtags: SafeParse.stringList(data['hashtags']),
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
      if (linkedProductId != null) 'linkedProductId': linkedProductId,
      if (linkedProductName != null) 'linkedProductName': linkedProductName,
      if (linkedProductImage != null) 'linkedProductImage': linkedProductImage,
      if (linkedProductPrice != null) 'linkedProductPrice': linkedProductPrice,
      'viewsCount': viewsCount,
      if (poll != null) 'poll': poll!.toMap(),
      if (hashtags.isNotEmpty) 'hashtags': hashtags,
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
    return SafeParse.sanitizeForCache(map);
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
    String? linkedProductId,
    String? linkedProductName,
    String? linkedProductImage,
    double? linkedProductPrice,
    int? viewsCount,
    PollModel? poll,
    List<String>? hashtags,
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
      linkedProductId: linkedProductId ?? this.linkedProductId,
      linkedProductName: linkedProductName ?? this.linkedProductName,
      linkedProductImage: linkedProductImage ?? this.linkedProductImage,
      linkedProductPrice: linkedProductPrice ?? this.linkedProductPrice,
      viewsCount: viewsCount ?? this.viewsCount,
      poll: poll ?? this.poll,
      hashtags: hashtags ?? this.hashtags,
    );
  }
}
