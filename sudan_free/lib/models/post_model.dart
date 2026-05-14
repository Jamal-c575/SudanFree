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

/// Main category groups for display in UI
enum PostCategoryGroup {
  general,
  shops,
  services,
  tech,
  education,
  health,
  automotive,
  realEstate,
  food;

  String getName(String locale) {
    if (locale == 'ar') {
      switch (this) {
        case PostCategoryGroup.general: return 'عام';
        case PostCategoryGroup.shops: return 'المتاجر';
        case PostCategoryGroup.services: return 'الخدمات';
        case PostCategoryGroup.tech: return 'التقنية';
        case PostCategoryGroup.education: return 'التعليم';
        case PostCategoryGroup.health: return 'الصحة';
        case PostCategoryGroup.automotive: return 'السيارات';
        case PostCategoryGroup.realEstate: return 'العقارات';
        case PostCategoryGroup.food: return 'الطعام';
      }
    } else {
      switch (this) {
        case PostCategoryGroup.general: return 'General';
        case PostCategoryGroup.shops: return 'Shops';
        case PostCategoryGroup.services: return 'Services';
        case PostCategoryGroup.tech: return 'Technology';
        case PostCategoryGroup.education: return 'Education';
        case PostCategoryGroup.health: return 'Health';
        case PostCategoryGroup.automotive: return 'Automotive';
        case PostCategoryGroup.realEstate: return 'Real Estate';
        case PostCategoryGroup.food: return 'Food';
      }
    }
  }

  IconData get icon {
    switch (this) {
      case PostCategoryGroup.general: return Icons.public;
      case PostCategoryGroup.shops: return Icons.storefront;
      case PostCategoryGroup.services: return Icons.build;
      case PostCategoryGroup.tech: return Icons.code;
      case PostCategoryGroup.education: return Icons.school;
      case PostCategoryGroup.health: return Icons.local_hospital;
      case PostCategoryGroup.automotive: return Icons.directions_car;
      case PostCategoryGroup.realEstate: return Icons.apartment;
      case PostCategoryGroup.food: return Icons.restaurant;
    }
  }

  Color get color {
    switch (this) {
      case PostCategoryGroup.general: return const Color(0xFF6c5ce7);
      case PostCategoryGroup.shops: return const Color(0xFFe17055);
      case PostCategoryGroup.services: return const Color(0xFF00b894);
      case PostCategoryGroup.tech: return const Color(0xFF0984e3);
      case PostCategoryGroup.education: return const Color(0xFF6c5ce7);
      case PostCategoryGroup.health: return const Color(0xFFe84393);
      case PostCategoryGroup.automotive: return const Color(0xFF636e72);
      case PostCategoryGroup.realEstate: return const Color(0xFFfdcb6e);
      case PostCategoryGroup.food: return const Color(0xFFe17055);
    }
  }
}

enum PostCategory {
  // ── عام ──
  general,
  question,
  help,
  announcement,
  discussion,

  // ── المتاجر ──
  shopClothing,
  shopElectronics,
  shopHome,
  shopBeauty,
  shopFurniture,
  shopBuilding,
  shopMobile,
  shopJewelry,
  shopSports,
  shopToys,
  shopBookstore,
  shopOther,

  // ── الخدمات ──
  servicePlumbing,
  serviceElectricity,
  serviceCarpentry,
  servicePainting,
  serviceWelding,
  serviceCleaning,
  serviceTransport,
  serviceDelivery,
  serviceAirCondition,
  serviceSatellite,
  serviceGardening,
  serviceOther,

  // ── التقنية (البرمجة والتصميم) ──
  techWebDev,
  techMobileDev,
  techDesign,
  techUIUX,
  techSEO,
  techMarketing,
  techDataEntry,
  techVideoEditing,
  techNetworking,
  techOther,

  // ── التعليم ──
  eduTutoring,
  eduLanguages,
  eduTraining,
  eduOnlineCourses,
  eduOther,

  // ── الصحة ──
  healthMedical,
  healthPharmacy,
  healthFitness,
  healthNutrition,
  healthOther,

  // ── السيارات ──
  autoParts,
  autoRepair,
  autoShowroom,
  autoRental,
  autoOther,

  // ── العقارات ──
  realEstateSale,
  realEstateRent,
  realEstateOffice,
  realEstateLand,
  realEstateOther,

  // ── الطعام ──
  foodRestaurant,
  foodCatering,
  foodHomemade,
  foodBakery,
  foodOther,

  // Legacy / backward-compat
  buySell;

  /// Returns which group this category belongs to
  PostCategoryGroup get group {
    switch (this) {
      case PostCategory.general:
      case PostCategory.question:
      case PostCategory.help:
      case PostCategory.announcement:
      case PostCategory.discussion:
      case PostCategory.buySell:
        return PostCategoryGroup.general;

      case PostCategory.shopClothing:
      case PostCategory.shopElectronics:
      case PostCategory.shopHome:
      case PostCategory.shopBeauty:
      case PostCategory.shopFurniture:
      case PostCategory.shopBuilding:
      case PostCategory.shopMobile:
      case PostCategory.shopJewelry:
      case PostCategory.shopSports:
      case PostCategory.shopToys:
      case PostCategory.shopBookstore:
      case PostCategory.shopOther:
        return PostCategoryGroup.shops;

      case PostCategory.servicePlumbing:
      case PostCategory.serviceElectricity:
      case PostCategory.serviceCarpentry:
      case PostCategory.servicePainting:
      case PostCategory.serviceWelding:
      case PostCategory.serviceCleaning:
      case PostCategory.serviceTransport:
      case PostCategory.serviceDelivery:
      case PostCategory.serviceAirCondition:
      case PostCategory.serviceSatellite:
      case PostCategory.serviceGardening:
      case PostCategory.serviceOther:
        return PostCategoryGroup.services;

      case PostCategory.techWebDev:
      case PostCategory.techMobileDev:
      case PostCategory.techDesign:
      case PostCategory.techUIUX:
      case PostCategory.techSEO:
      case PostCategory.techMarketing:
      case PostCategory.techDataEntry:
      case PostCategory.techVideoEditing:
      case PostCategory.techNetworking:
      case PostCategory.techOther:
        return PostCategoryGroup.tech;

      case PostCategory.eduTutoring:
      case PostCategory.eduLanguages:
      case PostCategory.eduTraining:
      case PostCategory.eduOnlineCourses:
      case PostCategory.eduOther:
        return PostCategoryGroup.education;

      case PostCategory.healthMedical:
      case PostCategory.healthPharmacy:
      case PostCategory.healthFitness:
      case PostCategory.healthNutrition:
      case PostCategory.healthOther:
        return PostCategoryGroup.health;

      case PostCategory.autoParts:
      case PostCategory.autoRepair:
      case PostCategory.autoShowroom:
      case PostCategory.autoRental:
      case PostCategory.autoOther:
        return PostCategoryGroup.automotive;

      case PostCategory.realEstateSale:
      case PostCategory.realEstateRent:
      case PostCategory.realEstateOffice:
      case PostCategory.realEstateLand:
      case PostCategory.realEstateOther:
        return PostCategoryGroup.realEstate;

      case PostCategory.foodRestaurant:
      case PostCategory.foodCatering:
      case PostCategory.foodHomemade:
      case PostCategory.foodBakery:
      case PostCategory.foodOther:
        return PostCategoryGroup.food;
    }
  }

  String getName(String locale) {
    if (locale == 'ar') {
      switch (this) {
        // عام
        case PostCategory.general: return 'عام';
        case PostCategory.question: return 'سؤال';
        case PostCategory.help: return 'مساعدة';
        case PostCategory.announcement: return 'إعلان';
        case PostCategory.discussion: return 'نقاش';
        case PostCategory.buySell: return 'بيع/شراء';

        // المتاجر
        case PostCategory.shopClothing: return 'ملابس';
        case PostCategory.shopElectronics: return 'إلكترونيات';
        case PostCategory.shopHome: return 'أدوات منزلية';
        case PostCategory.shopBeauty: return 'تجميل ومستحضرات';
        case PostCategory.shopFurniture: return 'أثاث';
        case PostCategory.shopBuilding: return 'مواد بناء';
        case PostCategory.shopMobile: return 'جوالات وإكسسوارات';
        case PostCategory.shopJewelry: return 'مجوهرات وإكسسوارات';
        case PostCategory.shopSports: return 'رياضة';
        case PostCategory.shopToys: return 'ألعاب أطفال';
        case PostCategory.shopBookstore: return 'مكتبة وقرطاسية';
        case PostCategory.shopOther: return 'متجر أخرى';

        // الخدمات
        case PostCategory.servicePlumbing: return 'سباكة';
        case PostCategory.serviceElectricity: return 'كهرباء';
        case PostCategory.serviceCarpentry: return 'نجارة';
        case PostCategory.servicePainting: return 'دهان وطلاء';
        case PostCategory.serviceWelding: return 'لحام وحدادة';
        case PostCategory.serviceCleaning: return 'تنظيف';
        case PostCategory.serviceTransport: return 'نقل وترحيل';
        case PostCategory.serviceDelivery: return 'توصيل';
        case PostCategory.serviceAirCondition: return 'تكييف وتبريد';
        case PostCategory.serviceSatellite: return 'ستلايت وشاشات';
        case PostCategory.serviceGardening: return 'حدائق وزراعة';
        case PostCategory.serviceOther: return 'خدمة أخرى';

        // التقنية
        case PostCategory.techWebDev: return 'تطوير مواقع';
        case PostCategory.techMobileDev: return 'تطوير تطبيقات';
        case PostCategory.techDesign: return 'تصميم جرافيك';
        case PostCategory.techUIUX: return 'تصميم واجهات';
        case PostCategory.techSEO: return 'تحسين محركات البحث';
        case PostCategory.techMarketing: return 'تسويق رقمي';
        case PostCategory.techDataEntry: return 'إدخال بيانات';
        case PostCategory.techVideoEditing: return 'مونتاج وتصوير';
        case PostCategory.techNetworking: return 'شبكات وصيانة';
        case PostCategory.techOther: return 'تقنية أخرى';

        // التعليم
        case PostCategory.eduTutoring: return 'دروس خصوصية';
        case PostCategory.eduLanguages: return 'لغات';
        case PostCategory.eduTraining: return 'تدريب مهني';
        case PostCategory.eduOnlineCourses: return 'دورات أونلاين';
        case PostCategory.eduOther: return 'تعليم أخرى';

        // الصحة
        case PostCategory.healthMedical: return 'طب وعلاج';
        case PostCategory.healthPharmacy: return 'صيدلية';
        case PostCategory.healthFitness: return 'لياقة وتمارين';
        case PostCategory.healthNutrition: return 'تغذية';
        case PostCategory.healthOther: return 'صحة أخرى';

        // السيارات
        case PostCategory.autoParts: return 'قطع غيار';
        case PostCategory.autoRepair: return 'ورشة وصيانة';
        case PostCategory.autoShowroom: return 'معرض سيارات';
        case PostCategory.autoRental: return 'تأجير سيارات';
        case PostCategory.autoOther: return 'سيارات أخرى';

        // العقارات
        case PostCategory.realEstateSale: return 'بيع عقار';
        case PostCategory.realEstateRent: return 'إيجار';
        case PostCategory.realEstateOffice: return 'مكاتب';
        case PostCategory.realEstateLand: return 'أراضي';
        case PostCategory.realEstateOther: return 'عقارات أخرى';

        // الطعام
        case PostCategory.foodRestaurant: return 'مطعم';
        case PostCategory.foodCatering: return 'تموين وبوفيه';
        case PostCategory.foodHomemade: return 'أكل بيتي';
        case PostCategory.foodBakery: return 'مخبوزات وحلويات';
        case PostCategory.foodOther: return 'طعام أخرى';
      }
    } else {
      switch (this) {
        // General
        case PostCategory.general: return 'General';
        case PostCategory.question: return 'Question';
        case PostCategory.help: return 'Help';
        case PostCategory.announcement: return 'Announcement';
        case PostCategory.discussion: return 'Discussion';
        case PostCategory.buySell: return 'Buy/Sell';

        // Shops
        case PostCategory.shopClothing: return 'Clothing';
        case PostCategory.shopElectronics: return 'Electronics';
        case PostCategory.shopHome: return 'Home Appliances';
        case PostCategory.shopBeauty: return 'Beauty & Cosmetics';
        case PostCategory.shopFurniture: return 'Furniture';
        case PostCategory.shopBuilding: return 'Building Materials';
        case PostCategory.shopMobile: return 'Phones & Accessories';
        case PostCategory.shopJewelry: return 'Jewelry & Accessories';
        case PostCategory.shopSports: return 'Sports';
        case PostCategory.shopToys: return 'Kids & Toys';
        case PostCategory.shopBookstore: return 'Books & Stationery';
        case PostCategory.shopOther: return 'Other Shop';

        // Services
        case PostCategory.servicePlumbing: return 'Plumbing';
        case PostCategory.serviceElectricity: return 'Electrical';
        case PostCategory.serviceCarpentry: return 'Carpentry';
        case PostCategory.servicePainting: return 'Painting';
        case PostCategory.serviceWelding: return 'Welding';
        case PostCategory.serviceCleaning: return 'Cleaning';
        case PostCategory.serviceTransport: return 'Transport';
        case PostCategory.serviceDelivery: return 'Delivery';
        case PostCategory.serviceAirCondition: return 'AC & Cooling';
        case PostCategory.serviceSatellite: return 'Satellite & TV';
        case PostCategory.serviceGardening: return 'Gardening';
        case PostCategory.serviceOther: return 'Other Service';

        // Tech
        case PostCategory.techWebDev: return 'Web Development';
        case PostCategory.techMobileDev: return 'App Development';
        case PostCategory.techDesign: return 'Graphic Design';
        case PostCategory.techUIUX: return 'UI/UX Design';
        case PostCategory.techSEO: return 'SEO';
        case PostCategory.techMarketing: return 'Digital Marketing';
        case PostCategory.techDataEntry: return 'Data Entry';
        case PostCategory.techVideoEditing: return 'Video Editing';
        case PostCategory.techNetworking: return 'Networking & IT';
        case PostCategory.techOther: return 'Other Tech';

        // Education
        case PostCategory.eduTutoring: return 'Tutoring';
        case PostCategory.eduLanguages: return 'Languages';
        case PostCategory.eduTraining: return 'Vocational Training';
        case PostCategory.eduOnlineCourses: return 'Online Courses';
        case PostCategory.eduOther: return 'Other Education';

        // Health
        case PostCategory.healthMedical: return 'Medical';
        case PostCategory.healthPharmacy: return 'Pharmacy';
        case PostCategory.healthFitness: return 'Fitness';
        case PostCategory.healthNutrition: return 'Nutrition';
        case PostCategory.healthOther: return 'Other Health';

        // Automotive
        case PostCategory.autoParts: return 'Auto Parts';
        case PostCategory.autoRepair: return 'Auto Repair';
        case PostCategory.autoShowroom: return 'Car Showroom';
        case PostCategory.autoRental: return 'Car Rental';
        case PostCategory.autoOther: return 'Other Auto';

        // Real Estate
        case PostCategory.realEstateSale: return 'Property Sale';
        case PostCategory.realEstateRent: return 'Property Rent';
        case PostCategory.realEstateOffice: return 'Offices';
        case PostCategory.realEstateLand: return 'Land';
        case PostCategory.realEstateOther: return 'Other Real Estate';

        // Food
        case PostCategory.foodRestaurant: return 'Restaurant';
        case PostCategory.foodCatering: return 'Catering';
        case PostCategory.foodHomemade: return 'Homemade Food';
        case PostCategory.foodBakery: return 'Bakery & Sweets';
        case PostCategory.foodOther: return 'Other Food';
      }
    }
  }

  /// Get categories for a specific group
  static List<PostCategory> getCategoriesForGroup(PostCategoryGroup group) {
    return PostCategory.values.where((c) => c.group == group).toList();
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
