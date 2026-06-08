import 'package:cloud_firestore/cloud_firestore.dart';

enum SquadCategory {
  construction,
  software,
  events,
  media,
  maintenance,
  education,
  logistics,
  other,
}

extension SquadCategoryExt on SquadCategory {
  String getName(String locale) {
    if (locale == 'ar') {
      switch (this) {
        case SquadCategory.construction: return 'مقاولات وبناء';
        case SquadCategory.software: return 'تقنية وبرمجيات';
        case SquadCategory.events: return 'تنظيم مناسبات';
        case SquadCategory.media: return 'تصوير وإعلام';
        case SquadCategory.maintenance: return 'صيانة عامة';
        case SquadCategory.education: return 'تعليم وتدريب';
        case SquadCategory.logistics: return 'نقل ولوجستيات';
        case SquadCategory.other: return 'أخرى';
      }
    }
    switch (this) {
      case SquadCategory.construction: return 'Construction & Building';
      case SquadCategory.software: return 'Tech & Software';
      case SquadCategory.events: return 'Events Planning';
      case SquadCategory.media: return 'Media & Photography';
      case SquadCategory.maintenance: return 'General Maintenance';
      case SquadCategory.education: return 'Education & Training';
      case SquadCategory.logistics: return 'Logistics & Transport';
      case SquadCategory.other: return 'Other';
    }
  }
}

class SquadModel {
  final String id;
  final String name;
  final String description;
  final String leaderId;
  final List<String> memberIds;
  final String? squadImageUrl;
  final List<String> combinedSkills;
  final int completedJobs;
  final double rating;
  final DateTime createdAt;
  final SquadCategory category;
  final String? state;
  final String? locality;

  SquadModel({
    required this.id,
    required this.name,
    required this.description,
    required this.leaderId,
    this.memberIds = const [],
    this.squadImageUrl,
    this.combinedSkills = const [],
    this.completedJobs = 0,
    this.rating = 0.0,
    required this.createdAt,
    this.category = SquadCategory.other,
    this.state,
    this.locality,
  });

  factory SquadModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Safety parse for category
    SquadCategory parsedCategory = SquadCategory.other;
    if (data['category'] != null) {
      final String catStr = data['category'] as String;
      parsedCategory = SquadCategory.values.firstWhere(
        (e) => e.name == catStr, 
        orElse: () => SquadCategory.other
      );
    }
    
    return SquadModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      leaderId: data['leaderId'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      squadImageUrl: data['squadImageUrl'],
      combinedSkills: List<String>.from(data['combinedSkills'] ?? []),
      completedJobs: data['completedJobs'] ?? 0,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      category: parsedCategory,
      state: data['state'],
      locality: data['locality'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'leaderId': leaderId,
      'memberIds': memberIds,
      'squadImageUrl': squadImageUrl,
      'combinedSkills': combinedSkills,
      'completedJobs': completedJobs,
      'rating': rating,
      'createdAt': Timestamp.fromDate(createdAt),
      'category': category.name,
      'state': state,
      'locality': locality,
    };
  }
}
