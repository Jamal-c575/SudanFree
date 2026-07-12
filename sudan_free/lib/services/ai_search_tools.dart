import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/squad_model.dart';
import '../models/request_model.dart';
import '../models/job_model.dart';
import '../models/post_model.dart';
import 'package:geolocator/geolocator.dart';

/// AiSearchTools: The tool layer between the AI model and the app's Firestore data.
/// All operations are READ-ONLY. No write/delete/report is ever allowed.
class AiSearchTools {
  static final AiSearchTools _instance = AiSearchTools._internal();
  factory AiSearchTools() => _instance;
  AiSearchTools._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  double _calculateScore(dynamic item, double? userLat, double? userLng) {
    double score = 0;
    
    // Rating score (0-5)
    score += (item.rating ?? 0) * 2; 
    
    // Verification bonus
    if (item is UserModel && item.isVerified) score += 5;

    // Availability bonus (Rule 10: Search Quality)
    if (item is UserModel && item.isAvailable) score += 5;
    
    // Distance penalty (closer = higher score)
    if (userLat != null && userLng != null && item.latitude != null && item.longitude != null) {
      final distanceMeters = Geolocator.distanceBetween(userLat, userLng, item.latitude!, item.longitude!);
      double distanceBonus = 20 - (distanceMeters / 1000);
      if (distanceBonus < 0) distanceBonus = 0;
      score += distanceBonus;
    }
    
    return score;
  }

  /// حساب درجة الصلة بالبحث — كلما كانت المهنة الأساسية تطابق البحث، كانت الدرجة أعلى
  double _calculateRelevanceScore(UserModel u, List<String> queryWords) {
    double score = 0;
    final jobTitle = (u.jobTitle ?? '').toLowerCase();
    final skills = u.skills.map((s) => s.toLowerCase()).join(' ');
    final bio = (u.bio ?? '').toLowerCase();
    final name = u.name.toLowerCase();

    for (final word in queryWords) {
      // أعلى درجة: المهنة الأساسية تطابق البحث تماماً
      if (jobTitle.contains(word)) score += 100;
      // درجة عالية: المهارات تطابق
      if (skills.contains(word)) score += 50;
      // درجة متوسطة: الاسم يطابق
      if (name.contains(word)) score += 30;
      // درجة منخفضة: النبذة تطابق (قد لا يكون تخصصه الفعلي)
      if (bio.contains(word)) score += 10;
    }
    return score;
  }

  /// توسيع الاستعلام بالمترادفات والمجالات ذات الصلة
  /// مثال: "مبرمج" → يضيف ["برمجة", "developer", "تطوير", "كود"]
  List<String> _expandQueryWithSynonyms(List<String> words) {
    const synonymMap = <String, List<String>>{
      // ─── تقنية وبرمجة ───
      'مبرمج':    ['برمجة', 'developer', 'تطوير', 'كود', 'software', 'تطبيق', 'موقع'],
      'برمجة':    ['مبرمج', 'developer', 'تطوير', 'كود', 'تطبيق', 'موقع'],
      'تطوير':    ['مبرمج', 'developer', 'برمجة'],
      'developer':['مبرمج', 'برمجة', 'تطوير'],
      'software': ['مبرمج', 'برمجة', 'developer'],
      'كود':      ['مبرمج', 'برمجة', 'developer'],
      'تطبيق':    ['مبرمج', 'برمجة', 'developer'],
      'موقع':     ['مبرمج', 'برمجة', 'developer'],
      'تصميم':    ['مصمم', 'جرافيك', 'design', 'designer'],
      'مصمم':     ['تصميم', 'جرافيك', 'design'],
      'جرافيك':   ['مصمم', 'تصميم', 'design'],
      'شبكات':    ['نتورك', 'network', 'it', 'انترنت'],
      'صيانة':    ['تصليح', 'فني', 'technician'],
      'فني':      ['صيانة', 'تصليح', 'technician'],
      // ─── بناء ومقاولات ───
      'مقاول':    ['مقاولات', 'بناء', 'تشييد', 'contractor'],
      'مقاولات':  ['مقاول', 'بناء', 'تشييد'],
      'نجار':     ['نجارة', 'خشب', 'carpenter'],
      'نجارة':    ['نجار', 'خشب'],
      'حداد':     ['حدادة', 'حديد', 'معدن'],
      'كهربائي':  ['كهرباء', 'كهربائية', 'electrician'],
      'كهرباء':   ['كهربائي', 'كهربائية'],
      'سباك':     ['سباكة', 'مياه', 'plumber'],
      'سباكة':    ['سباك', 'مياه'],
      'دهان':     ['دهانة', 'طلاء', 'painter'],
      'دهانة':    ['دهان', 'طلاء'],
      // ─── تصوير وإعلام ───
      'مصور':     ['تصوير', 'photography', 'فيديو', 'camera'],
      'تصوير':    ['مصور', 'photography'],
      'مونتاج':   ['تحرير', 'فيديو', 'editor'],
      // ─── تعليم ───
      'معلم':     ['تدريس', 'تعليم', 'مدرس', 'teacher'],
      'مدرس':     ['تدريس', 'تعليم', 'معلم'],
      'تدريس':    ['معلم', 'مدرس', 'تعليم'],
      // ─── قانون ومال ───
      'محامي':    ['قانون', 'محاماة', 'lawyer'],
      'محاسب':    ['محاسبة', 'accounting', 'مالية'],
      'محاسبة':   ['محاسب', 'accounting', 'مالية'],
      // ─── خدمات يدوية ───
      'سائق':     ['قيادة', 'نقل', 'driver', 'توصيل'],
      'طباخ':     ['طبخ', 'cook', 'chef', 'مطبخ'],
      'طبخ':      ['طباخ', 'cook', 'chef'],
      'خياط':     ['خياطة', 'تفصيل', 'ملابس', 'tailor'],
      'خياطة':    ['خياط', 'تفصيل', 'ملابس'],
      'حلاق':     ['حلاقة', 'barber', 'شعر'],
      'تنظيف':    ['نظافة', 'cleaning', 'مكافحة'],
      // ─── طب وصحة ───
      'طبيب':     ['طب', 'صحة', 'doctor', 'عيادة'],
      'صيدلي':    ['صيدلة', 'دواء', 'pharmacy'],
    };

    final expanded = <String>{};
    for (final word in words) {
      expanded.add(word);
      // إضافة المترادفات
      final synonyms = synonymMap[word];
      if (synonyms != null) expanded.addAll(synonyms);
      // إزالة "ال" التعريف وإضافة الجذر
      if (word.startsWith('ال') && word.length > 3) expanded.add(word.substring(2));
    }
    return expanded.toList();
  }

  // ─── TOOL: searchFreelancers ──────────────────────────────────────
  /// بحث ثلاثي المستويات:
  /// 🥇 المستوى 1: تطابق المسمى الوظيفي (jobTitle) — الأدق
  /// 🥈 المستوى 2: تطابق المهارات (skills)
  /// 🥉 المستوى 3: أي تطابق آخر (اسم، نبذة)
  Future<AiToolResult> searchFreelancers(String query, {int limit = 20, double? lat, double? lng}) async {
    try {
      final lowerQuery = query.toLowerCase().trim();
      // استخراج الكلمات (أطول من حرف واحد)
      final queryWords = lowerQuery
          .split(RegExp(r'\s+'))
          .where((w) => w.length > 1)
          .toList();
      if (queryWords.isEmpty) queryWords.add(lowerQuery);

      // توسيع الاستعلام بالمترادفات
      final expandedWords = _expandQueryWithSynonyms(queryWords);

      // ══════════════════════════════════════════════
      // الخطوة 1: جلب المرشحين من Firestore
      // نبحث بكل كلمة أصلية (ليس المترادفات — كي لا نُضخم الطلبات)
      // ══════════════════════════════════════════════
      final Set<String> seenIds = {};
      final List<UserModel> allCandidates = [];

      for (final word in queryWords.take(3)) {
        final q = await _db
            .collection('users')
            .where('role', whereIn: ['freelancer', 'Freelancer', 'privateService', 'techService'])
            .where('searchKeywords', arrayContains: word)
            .limit(60)
            .get();

        for (final doc in q.docs) {
          try {
            final u = UserModel.fromFirestore(doc);
            if (seenIds.add(u.id)) allCandidates.add(u);
          } catch (_) {}
        }
      }

      // الخطوة 2: إذا النتائج قليلة، نفحص 50 مستخدم بحثاً client-side لتوفير القراءات
      // ══════════════════════════════════════════════
      if (allCandidates.length < 8) {
        final fallbackQ = await _db
            .collection('users')
            .where('role', whereIn: ['freelancer', 'Freelancer', 'privateService', 'techService'])
            .limit(50)
            .get();

        for (final doc in fallbackQ.docs) {
          try {
            final u = UserModel.fromFirestore(doc);
            if (seenIds.contains(u.id)) continue;
            // فقط أضف إذا كانت هناك أي صلة
            if (_calculateRelevanceScore(u, expandedWords) > 0) {
              seenIds.add(u.id);
              allCandidates.add(u);
            }
          } catch (_) {}
        }
      }

      if (allCandidates.isEmpty) return await getEmptyWithSuggestions(query);

      // ══════════════════════════════════════════════
      // الخطوة 3: تصنيف ثلاثي المستويات
      // ══════════════════════════════════════════════
      allCandidates.sort((a, b) {
        final rA = _calculateRelevanceScore(a, expandedWords);
        final rB = _calculateRelevanceScore(b, expandedWords);
        if (rA != rB) return rB.compareTo(rA);
        return _calculateScore(b, lat, lng).compareTo(_calculateScore(a, lat, lng));
      });

      List<UserModel> results;

      // 🥇 المستوى 1: تطابق في المسمى الوظيفي (نقاط >= 100)
      final tier1 = allCandidates
          .where((u) => _calculateRelevanceScore(u, expandedWords) >= 100)
          .toList();

      if (tier1.isNotEmpty) {
        results = tier1;
      } else {
        // 🥈 المستوى 2: تطابق في المهارات (نقاط >= 50)
        final tier2 = allCandidates
            .where((u) => _calculateRelevanceScore(u, expandedWords) >= 50)
            .toList();

        if (tier2.isNotEmpty) {
          results = tier2;
        } else {
          // 🥉 المستوى 3: أي تطابق (اسم أو نبذة)
          results = allCandidates
              .where((u) => _calculateRelevanceScore(u, expandedWords) > 0)
              .toList();
        }
      }

      if (results.isEmpty) return await getEmptyWithSuggestions(query);
      if (results.length > limit) results = results.sublist(0, limit);

      // ══════════════════════════════════════════════
      // الخطوة 4: بناء السياق للذكاء الاصطناعي
      // ══════════════════════════════════════════════
      final sb = StringBuffer();
      sb.writeln('نتائج البحث عن "$query" في التطبيق:');
      for (var i = 0; i < results.length; i++) {
        final u = results[i];
        sb.writeln('${i + 1}. الاسم: ${u.name} [ID:${u.id}]');
        if (u.jobTitle != null) sb.writeln('   التخصص: ${u.jobTitle}');
        if (u.skills.isNotEmpty) sb.writeln('   المهارات: ${u.skills.take(4).join("، ")}');
        sb.writeln('   التقييم: ${u.rating.toStringAsFixed(1)} ⭐ (${u.reviewsCount} تقييم)');
        if (u.completedJobs > 0) sb.writeln('   الخبرة (أعمال منجزة): ${u.completedJobs}');
        if (u.isVerified) sb.writeln('   حالة التوثيق: موثق ✅');
        if (u.isPremium) sb.writeln('   الباقة: مميزة 🌟');
        if (u.bio != null && u.bio!.isNotEmpty) {
          final bio = u.bio!;
          sb.writeln('   النبذة: ${bio.length > 120 ? "${bio.substring(0, 120)}..." : bio}');
        }
        sb.writeln('   الحالة: ${u.isAvailable ? "متاح الآن ✅" : "غير متاح حالياً"}');
        if (u.state != null) sb.writeln('   الموقع: ${u.state}');
        sb.writeln();
      }
      return AiToolResult(context: sb.toString(), users: results);
    } catch (e) {
      return AiToolResult.error(e.toString());
    }
  }

  Future<AiToolResult> getEmptyWithSuggestions(String query) async {
    try {
      final sb = StringBuffer();
      sb.writeln('عذراً، لم أتمكن من العثور على "$query" في قاعدة البيانات.');
      sb.writeln('لكن تفضل بعض الاقتراحات المميزة التي قد تفيدك:');
      sb.writeln();

      List<UserModel> suggestedUsers = [];
      List<PostModel> suggestedPosts = [];

      final freelancersQuery = await _db.collection('users').where('role', whereIn: ['freelancer', 'Freelancer', 'privateService', 'techService']).orderBy('rating', descending: true).limit(2).get();
      suggestedUsers.addAll(freelancersQuery.docs.map((d) { try { return UserModel.fromFirestore(d); } catch (_) { return null; } }).whereType<UserModel>());

      final shopsQuery = await _db.collection('users').where('role', whereIn: ['shop', 'Shop']).orderBy('rating', descending: true).limit(1).get();
      suggestedUsers.addAll(shopsQuery.docs.map((d) { try { return UserModel.fromFirestore(d); } catch (_) { return null; } }).whereType<UserModel>());

      final postsQuery = await _db.collection('posts').orderBy('createdAt', descending: true).limit(2).get();
      suggestedPosts.addAll(postsQuery.docs.map((d) { try { return PostModel.fromMap(d.data()..["id"] = d.id); } catch (_) { return null; } }).whereType<PostModel>());

      if (suggestedUsers.isEmpty && suggestedPosts.isEmpty) return AiToolResult.empty(query);

      if (suggestedUsers.isNotEmpty) {
        sb.writeln('💡 **مقدمو خدمات ومتاجر مميزة:**');
        for (var u in suggestedUsers) {
          sb.writeln('- ${u.name} [ID:${u.id}]');
          if (u.jobTitle != null) sb.writeln('   التخصص: ${u.jobTitle}');
          sb.writeln('   التقييم: ${u.rating.toStringAsFixed(1)} ⭐');
        }
        sb.writeln();
      }

      if (suggestedPosts.isNotEmpty) {
        sb.writeln('🛒 **منتجات حديثة:**');
        for (var p in suggestedPosts) {
          sb.writeln('- ${p.caption ?? "بدون عنوان"} [ID:${p.id}]');
        }
      }
      return AiToolResult(context: sb.toString(), users: suggestedUsers, posts: suggestedPosts);
    } catch (e) {
      return AiToolResult.empty(query);
    }
  }

  // ─── TOOL: searchShops ──────────────────────────────────────────
  Future<AiToolResult> searchShops(String query, {int limit = 20, double? lat, double? lng}) async {
    try {
      final lowerQuery = query.toLowerCase().trim();
      final queryWords = lowerQuery.split(RegExp(r'\s+')).where((w) => w.length > 2).toList();
      if (queryWords.isEmpty) queryWords.add(lowerQuery);
      
      List<UserModel> results = [];

      final snapshot = await _db
          .collection('users')
          .where('role', whereIn: ['shop', 'Shop'])
          .where('searchKeywords', arrayContains: queryWords.first)
          .limit(limit)
          .get();

      results = snapshot.docs.map((doc) {
        try { return UserModel.fromFirestore(doc); } catch (_) { return null; }
      }).whereType<UserModel>().toList();
      
      results.sort((a, b) => _calculateScore(b, lat, lng).compareTo(_calculateScore(a, lat, lng)));

      if (results.isEmpty) {
        final all = await _db
            .collection('users')
            .where('role', whereIn: ['shop', 'Shop'])
            .limit(100)
            .get();
        results = all.docs.map((doc) {
          try { return UserModel.fromFirestore(doc); } catch (_) { return null; }
        }).whereType<UserModel>().where((u) {
          final name = u.name.toLowerCase();
          final bio = (u.bio ?? '').toLowerCase();
          
          bool isMatch = false;
          for (final word in queryWords) {
            if (name.contains(word) || bio.contains(word)) {
              isMatch = true;
              break;
            }
          }
          return isMatch;
        }).toList();
        
        results.sort((a, b) => _calculateScore(b, lat, lng).compareTo(_calculateScore(a, lat, lng)));
        if (results.length > limit) results = results.sublist(0, limit);
      }

      if (results.isEmpty) return await getEmptyWithSuggestions(query);

      final sb = StringBuffer();
      sb.writeln('المتاجر المتعلقة بـ "$query":');
      for (var i = 0; i < results.length; i++) {
        final u = results[i];
        sb.writeln('${i + 1}. اسم المتجر: ${u.name} [ID:${u.id}]');
        if (u.bio != null && u.bio!.isNotEmpty) {
          final bio = u.bio!;
          sb.writeln('   عن المتجر: ${bio.length > 120 ? "${bio.substring(0, 120)}..." : bio}');
        }
        sb.writeln('   التقييم: ${u.rating.toStringAsFixed(1)} ⭐ (${u.reviewsCount} تقييم)');
        if (u.completedJobs > 0) sb.writeln('   الخبرة (مبيعات/أعمال): ${u.completedJobs}');
        if (u.isVerified) sb.writeln('   حالة التوثيق: موثق ✅');
        if (u.isPremium) sb.writeln('   الباقة: مميزة 🌟');
        sb.writeln('   الحالة: ${u.isShopCurrentlyOpen ? "مفتوح الآن ✅" : "مغلق حالياً"}');
        if (u.state != null) sb.writeln('   الموقع: ${u.state}');
        sb.writeln();
      }
      return AiToolResult(context: sb.toString(), users: results);
    } catch (e) {
      return AiToolResult.error(e.toString());
    }
  }

  // ─── TOOL: searchJobs ──────────────────────────────────────────
  Future<AiToolResult> searchJobs(String query, {int limit = 5}) async {
    try {
      final snapshot = await _db
          .collection('jobs')
          .where('status', isEqualTo: 'open')
          .limit(100)
          .get();

      final lowerQuery = query.toLowerCase();
      final filteredDocs = snapshot.docs.where((doc) {
        final data = doc.data();
        final title = (data['title'] ?? '').toString().toLowerCase();
        final desc = (data['description'] ?? '').toString().toLowerCase();
        return title.contains(lowerQuery) || desc.contains(lowerQuery);
      }).toList();

      // Sort locally
      filteredDocs.sort((a, b) {
        final aDate = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      final filtered = filteredDocs.take(limit).toList();

      if (filtered.isEmpty) return await getEmptyWithSuggestions(query);

      final sb = StringBuffer();
      sb.writeln('فرص العمل المتاحة لـ "$query":');
      final jobsList = <JobModel>[];
      for (var i = 0; i < filtered.length; i++) {
        final doc = filtered[i];
        final job = JobModel.fromFirestore(doc);
        jobsList.add(job);
        
        sb.writeln('${i + 1}. ${job.title} [ID:${job.id}]');
        if (job.description.isNotEmpty) {
          final desc = job.description;
          sb.writeln('   الوصف: ${desc.length > 100 ? "${desc.substring(0, 100)}..." : desc}');
        }
        sb.writeln('   الميزانية: من ${job.budgetMin} إلى ${job.budgetMax} ${job.currency}');
        sb.writeln();
      }
      return AiToolResult(context: sb.toString(), jobs: jobsList);
    } catch (e) {
      return AiToolResult.error(e.toString());
    }
  }

  // ─── TOOL: getTopRated ──────────────────────────────────────────
  Future<AiToolResult> getTopRated({String? category, int limit = 5}) async {
    try {
      Query query = _db
          .collection('users')
          .where('role', whereIn: ['freelancer', 'Freelancer', 'privateService', 'techService'])
          .limit(limit);

      if (category != null && category.isNotEmpty) {
        query = _db
            .collection('users')
            .where('role', whereIn: ['freelancer', 'Freelancer', 'privateService', 'techService'])
            .where('searchKeywords', arrayContains: category.toLowerCase())
            .limit(limit);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) return AiToolResult.empty(category ?? '');

      final results = snapshot.docs.map((doc) {
        try { return UserModel.fromFirestore(doc); } catch (_) { return null; }
      }).whereType<UserModel>().toList();
      results.sort((a, b) => b.rating.compareTo(a.rating));

      final sb = StringBuffer();
      sb.writeln('أعلى الحرفيين تقييماً${category != null ? ' في "$category"' : ''}:');
      for (var i = 0; i < results.length; i++) {
        final u = results[i];
        sb.writeln('${i + 1}. ${u.name} [ID:${u.id}]');
        sb.writeln('   التقييم: ${u.rating.toStringAsFixed(1)} ⭐ (${u.reviewsCount} تقييم)');
        if (u.jobTitle != null) sb.writeln('   التخصص: ${u.jobTitle}');
        if (u.completedJobs > 0) sb.writeln('   الأعمال المنجزة: ${u.completedJobs}');
        if (u.isVerified) sb.writeln('   حالة التوثيق: موثق ✅');
        if (u.isPremium) sb.writeln('   الباقة: مميزة 🌟');
        sb.writeln('   الحالة: ${u.isAvailable ? "متاح ✅" : "مشغول"}');
        sb.writeln();
      }
      return AiToolResult(context: sb.toString(), users: results);
    } catch (e) {
      return AiToolResult.error(e.toString());
    }
  }

  // ─── TOOL: getSuccessStories ──────────────────────────────────────────
  Future<AiToolResult> getSuccessStories({int limit = 5}) async {
    try {
      final snapshot = await _db
          .collection('success_stories')
          .where('status', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      if (snapshot.docs.isEmpty) return AiToolResult.empty('قصص نجاح');

      final results = snapshot.docs;
      final sb = StringBuffer();
      sb.writeln('قصص نجاح الحرفيين والمستخدمين الملهمة:');
      
      final stories = [];
      for (var i = 0; i < results.length; i++) {
        final doc = results[i];
        final data = doc.data();
        stories.add(data);
        sb.writeln('${i + 1}. قصة: ${data['title']}');
        sb.writeln('   الكاتب: ${data['userName']}');
        sb.writeln('   المحتوى: ${data['content'].toString().length > 150 ? "${data['content'].toString().substring(0, 150)}..." : data['content']}');
        sb.writeln();
      }
      
      // We pass the raw data so the UI can format it, but wait, we need to add a UI card for this in AiAssistantScreen if we want.
      // For now, context is enough for the AI.
      return AiToolResult(context: sb.toString());
    } catch (e) {
      return AiToolResult.error(e.toString());
    }
  }

  // ─── TOOL: getUserProfile ──────────────────────────────────────
  Future<AiToolResult> getUserProfile(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) return AiToolResult.empty(userId);
      final u = UserModel.fromFirestore(doc);

      final sb = StringBuffer();
      sb.writeln('ملف ${u.name} [ID:${u.id}]:');
      if (u.jobTitle != null) sb.writeln('  التخصص: ${u.jobTitle}');
      if (u.bio != null) sb.writeln('  النبذة: ${u.bio}');
      if (u.skills.isNotEmpty) sb.writeln('  المهارات: ${u.skills.join("، ")}');
      sb.writeln('  التقييم: ${u.rating.toStringAsFixed(1)} ⭐ (${u.reviewsCount} تقييم)');
      sb.writeln('  الأعمال المنجزة: ${u.completedJobs}');
      if (u.isVerified) sb.writeln('  حالة التوثيق: موثق ✅');
      if (u.isPremium) sb.writeln('  الباقة: مميزة 🌟');
      sb.writeln('  الحالة: ${u.isAvailable ? "متاح الآن ✅" : "غير متاح"}');
      if (u.state != null) sb.writeln('  الموقع: ${u.state}');
      sb.writeln('  عضو منذ: ${u.createdAt.year}');
      return AiToolResult(context: sb.toString(), users: [u]);
    } catch (e) {
      return AiToolResult.error(e.toString());
    }
  }

  // ─── TOOL: searchSquads ──────────────────────────────────────────
  /// Search service groups (squads) by name, category, or skills.
  Future<AiToolResult> searchSquads(String query, {int limit = 5, double? lat, double? lng}) async {
    try {
      final lowerQuery = query.toLowerCase().trim();
      final snapshot = await _db
          .collection('squads')
          .limit(80)
          .get();

      final filteredDocs = snapshot.docs.where((doc) {
        final data = doc.data();
        final name = (data['name'] ?? '').toString().toLowerCase();
        final desc = (data['description'] ?? '').toString().toLowerCase();
        final skills = (data['combinedSkills'] as List<dynamic>? ?? [])
            .map((s) => s.toString().toLowerCase())
            .join(' ');
        final category = (data['category'] ?? '').toString().toLowerCase();
        return name.contains(lowerQuery) ||
            desc.contains(lowerQuery) ||
            skills.contains(lowerQuery) ||
            category.contains(lowerQuery);
      }).toList();
      
      final results = filteredDocs.map((doc) {
        try { return SquadModel.fromFirestore(doc); } catch (_) { return null; }
      }).whereType<SquadModel>().toList();
      
      results.sort((a, b) => _calculateScore(b, lat, lng).compareTo(_calculateScore(a, lat, lng)));
      final limitedResults = results.take(limit).toList();

      if (limitedResults.isEmpty) return await getEmptyWithSuggestions(query);

      final squads = limitedResults;

      final sb = StringBuffer();
      sb.writeln('المجموعات الخدمية المتعلقة بـ "$query":');
      for (var i = 0; i < squads.length; i++) {
        final s = squads[i];
        sb.writeln('${i + 1}. اسم المجموعة: ${s.name} [ID:${s.id}]');
        sb.writeln('   التصنيف: ${s.category.getName("ar")}');
        if (s.description.isNotEmpty) {
          sb.writeln('   الوصف: ${s.description.length > 100 ? "${s.description.substring(0, 100)}..." : s.description}');
        }
        sb.writeln('   التقييم: ${s.rating.toStringAsFixed(1)} ⭐');
        sb.writeln('   عدد الأعضاء: ${s.memberIds.length}');
        sb.writeln('   الأعمال المنجزة: ${s.completedJobs}');
        if (s.combinedSkills.isNotEmpty) {
          sb.writeln('   المهارات: ${s.combinedSkills.take(5).join("، ")}');
        }
        sb.writeln('   الحالة: ${s.isAvailable ? "متاحة للعمل ✅" : "مشغولة حالياً"}');
        if (s.state != null) sb.writeln('   الموقع: ${s.state}');
        sb.writeln();
      }
      return AiToolResult(context: sb.toString(), squads: squads);
    } catch (e) {
      return AiToolResult.error(e.toString());
    }
  }

  // ─── TOOL: getSquadMembers ──────────────────────────────────────
  Future<AiToolResult> getSquadMembers(String squadId) async {
    try {
      final squadDoc = await _db.collection('squads').doc(squadId).get();
      if (!squadDoc.exists) return AiToolResult.error("المجموعة غير موجودة.");
      
      final squad = SquadModel.fromFirestore(squadDoc);
      if (squad.memberIds.isEmpty) return AiToolResult(context: "لا يوجد أعضاء في هذه المجموعة حالياً.", users: []);

      // Fetch members
      final membersSnap = await _db.collection('users').where(FieldPath.documentId, whereIn: squad.memberIds.take(10).toList()).get();
      final members = membersSnap.docs.map((doc) {
        try { return UserModel.fromFirestore(doc); } catch (_) { return null; }
      }).whereType<UserModel>().toList();

      final sb = StringBuffer();
      sb.writeln('أعضاء مجموعة "${squad.name}":');
      for (var i = 0; i < members.length; i++) {
        final m = members[i];
        sb.writeln('${i + 1}. ${m.name} [ID:${m.id}] - التخصص: ${m.jobTitle ?? "غير محدد"} - التقييم: ${m.rating.toStringAsFixed(1)} ⭐');
      }
      return AiToolResult(context: sb.toString(), users: members);
    } catch (e) {
      return AiToolResult.error(e.toString());
    }
  }

  // ─── TOOL: getSquadProfile ──────────────────────────────────────
  Future<AiToolResult> getSquadProfile(String squadId) async {
    try {
      final doc = await _db.collection('squads').doc(squadId).get();
      if (!doc.exists) return AiToolResult.error("المجموعة غير موجودة.");
      final squad = SquadModel.fromFirestore(doc);

      final sb = StringBuffer();
      sb.writeln('بيانات وملف المجموعة "${squad.name}" [ID:${squad.id}]:');
      sb.writeln('  التصنيف: ${squad.category.getName("ar")}');
      if (squad.description.isNotEmpty) {
        sb.writeln('  النبذة: ${squad.description}');
      }
      if (squad.combinedSkills.isNotEmpty) {
        sb.writeln('  المهارات المشتركة: ${squad.combinedSkills.join("، ")}');
      }
      sb.writeln('  التقييم: ${squad.rating.toStringAsFixed(1)} ⭐');
      sb.writeln('  عدد الأعضاء: ${squad.memberIds.length}');
      sb.writeln('  الأعمال المنجزة: ${squad.completedJobs}');
      sb.writeln('  الحالة: ${squad.isAvailable ? "متاحة للعمل ✅" : "مشغولة حالياً"}');
      if (squad.state != null) sb.writeln('  الموقع: ${squad.state}');
      sb.writeln('  سنة التأسيس: ${squad.createdAt.year}');
      return AiToolResult(context: sb.toString(), squads: [squad]);
    } catch (e) {
      return AiToolResult.error(e.toString());
    }
  }

  // ─── TOOL: searchRequests ──────────────────────────────────────────
  /// Search active client service requests.
  Future<AiToolResult> searchRequests(String query, {int limit = 5}) async {
    try {
      final lowerQuery = query.toLowerCase().trim();
      final now = DateTime.now();

      final snapshot = await _db
          .collection('requests')
          .where('isFulfilled', isEqualTo: false)
          .limit(100)
          .get();

      final filtered = snapshot.docs.where((doc) {
        final data = doc.data();
        // Skip expired requests
        final expiresAt = data['expiresAt'];
        if (expiresAt != null) {
          final expDate = (expiresAt as Timestamp).toDate();
          if (expDate.isBefore(now)) return false;
        }
        final text = (data['text'] ?? '').toString().toLowerCase();
        final category = (data['category'] ?? '').toString().toLowerCase();
        return lowerQuery.isEmpty || text.contains(lowerQuery) || category.contains(lowerQuery);
      }).toList();
      
      filtered.sort((a, b) {
         final aTime = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
         final bTime = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
         return bTime.compareTo(aTime);
      });

      if (filtered.isEmpty) return await getEmptyWithSuggestions(query);

      final requestsList = filtered.take(limit).map((doc) {
        try {
          return RequestModel.fromMap(doc.data(), doc.id);
        } catch (_) {
          return null;
        }
      }).whereType<RequestModel>().toList();

      final sb = StringBuffer();
      sb.writeln('طلبات الخدمة النشطة${query.isNotEmpty ? " المتعلقة بـ \"$query\"" : ""}:');
      for (var i = 0; i < filtered.length; i++) {
        final data = filtered[i].data();
        sb.writeln('${i + 1}. [ID:${filtered[i].id}]');
        sb.writeln('   الطلب: ${(data["text"] ?? "").toString().length > 120 ? "${data["text"].toString().substring(0, 120)}..." : data["text"]}');
        if (data['category'] != null) sb.writeln('   التصنيف: ${data["category"]}');
        if (data['price'] != null) sb.writeln('   الميزانية المقترحة: ${data["price"]} جنيه');
        sb.writeln('   عدد العروض الواردة: ${data["offersCount"] ?? 0}');
        if (data['state'] != null) sb.writeln('   الموقع: ${data["state"]}');
        sb.writeln('   صاحب الطلب: ${data["clientName"] ?? "عميل"}${data["isClientVerified"] == true ? " ✔️ موثق" : ""}');
        sb.writeln();
      }
      return AiToolResult(context: sb.toString(), requests: requestsList);
    } catch (e) {
      return AiToolResult.error(e.toString());
    }
  }

  // ─── TOOL: searchPosts (Products) ──────────────────────────────────
  /// Search community posts, particularly products (laptops, phones, etc.)
  Future<AiToolResult> searchPosts(String query, {int limit = 20}) async {
    try {
      final lowerQuery = query.toLowerCase().trim();
      final queryWords = lowerQuery.split(RegExp(r'\s+')).where((w) => w.length > 2).toList();
      if (queryWords.isEmpty) queryWords.add(lowerQuery);

      // Query the posts collection, prioritizing recent ones
      final snapshot = await _db
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(150)
          .get();

      final filtered = snapshot.docs.where((doc) {
        final data = doc.data();
        final text = (data['caption'] ?? '').toString().toLowerCase();
        final category = (data['category'] ?? '').toString().toLowerCase();
        final productCondition = (data['productCondition'] ?? '').toString().toLowerCase();
        
        if (lowerQuery.isEmpty) return true;
        
        bool isMatch = false;
        for (final word in queryWords) {
          if (text.contains(word) || category.contains(word) || productCondition.contains(word)) {
            isMatch = true;
            break;
          }
        }
        return isMatch;
      }).toList();

      final finalFiltered = filtered.take(limit).toList();

      if (finalFiltered.isEmpty) return await getEmptyWithSuggestions(query);

      final postsList = finalFiltered.map((doc) {
        try {
          return PostModel.fromMap(doc.data()..["id"] = doc.id);
        } catch (_) {
          return null;
        }
      }).whereType<PostModel>().toList();

      final sb = StringBuffer();
      sb.writeln('المنتجات والمنشورات${query.isNotEmpty ? " المتعلقة بـ \"$query\"" : ""}:');
      for (var i = 0; i < postsList.length; i++) {
        final post = postsList[i];
        sb.writeln('${i + 1}. [ID:${post.id}]');
        sb.writeln('   الوصف: ${post.caption != null && post.caption!.length > 100 ? "${post.caption!.substring(0, 100)}..." : post.caption ?? "بدون وصف"}');
        if (post.category != null) sb.writeln('   التصنيف: ${post.category}');
        if (post.price != null) sb.writeln('   السعر: ${post.price} جنيه');
        if (post.productCondition != null) sb.writeln('   الحالة: ${post.productCondition == "new" ? "جديد" : "مستعمل"}');
        sb.writeln('   البائع: ${post.userName}${post.isUserVerified ? " ✔️ موثق" : ""}');
        sb.writeln();
      }
      return AiToolResult(context: sb.toString(), posts: postsList);
    } catch (e) {
      return AiToolResult.error(e.toString());
    }
  }

  // ─── TOOL: estimateServicePrice ────────────────────────────────────
  /// Estimates the price range of a service based on active requests
  Future<AiToolResult> estimateServicePrice(String serviceName) async {
    try {
      final lowerQuery = serviceName.toLowerCase().trim();
      final queryWords = lowerQuery.split(RegExp(r'\s+')).where((w) => w.length > 1).toList();
      if (queryWords.isEmpty) queryWords.add(lowerQuery);
      
      final expandedWords = _expandQueryWithSynonyms(queryWords);

      // 1. حساب متوسط الأجر بالساعة للحرفيين
      double sumHourly = 0;
      int countHourly = 0;
      double minHourly = double.infinity;
      double maxHourly = 0;

      for (final word in expandedWords.take(2)) {
        final usersSnap = await _db.collection('users')
          .where('role', whereIn: ['freelancer', 'Freelancer', 'privateService', 'techService'])
          .where('searchKeywords', arrayContains: word)
          .limit(30)
          .get();
          
        for (var doc in usersSnap.docs) {
          final hr = (doc.data()['hourlyRate'] as num?)?.toDouble();
          if (hr != null && hr > 0) {
            sumHourly += hr;
            countHourly++;
            if (hr < minHourly) minHourly = hr;
            if (hr > maxHourly) maxHourly = hr;
          }
        }
      }

      // 2. حساب متوسط الأسعار الثابتة في طلبات العملاء السابقة
      final requestsSnap = await _db.collection('requests').limit(50).get();
      final filteredReqs = requestsSnap.docs.where((doc) {
        final data = doc.data();
        final text = (data['text'] ?? '').toString().toLowerCase();
        final category = (data['category'] ?? '').toString().toLowerCase();
        return text.contains(lowerQuery) || category.contains(lowerQuery);
      }).toList();

      double sumFixed = 0;
      int countFixed = 0;
      double minFixed = double.infinity;
      double maxFixed = 0;

      for (var doc in filteredReqs) {
        final price = (doc.data()['price'] as num?)?.toDouble();
        if (price != null && price > 0) {
          sumFixed += price;
          countFixed++;
          if (price < minFixed) minFixed = price;
          if (price > maxFixed) maxFixed = price;
        }
      }

      if (countHourly == 0 && countFixed == 0) {
        return AiToolResult(
          context: 'لا تتوفر بيانات كافية لتسعير "$serviceName" حالياً (لا يوجد تسعير بالساعة للحرفيين أو طلبات مسعرة).',
          estimatedPriceRange: 'غير متوفر',
        );
      }

      final sb = StringBuffer();
      sb.writeln('بناءً على تحليل بيانات تطبيق سودان فري لخدمة "$serviceName":');
      
      String rangeStr = '';
      if (countHourly > 0) {
        final avgH = sumHourly / countHourly;
        rangeStr = countHourly == 1 ? '${avgH.toStringAsFixed(0)} ج/ساعة' : '${minHourly.toStringAsFixed(0)} ج - ${maxHourly.toStringAsFixed(0)} ج في الساعة';
        sb.writeln('- متوسط الأجر بالساعة للحرفيين: ${avgH.toStringAsFixed(0)} جنيه سوداني.');
        sb.writeln('  (النطاق: $rangeStr)');
      }

      if (countFixed > 0) {
        final avgF = sumFixed / countFixed;
        final rangeF = countFixed == 1 ? '${avgF.toStringAsFixed(0)} ج' : '${minFixed.toStringAsFixed(0)} ج - ${maxFixed.toStringAsFixed(0)} ج للخدمة كاملة';
        sb.writeln('- متوسط السعر للخدمة المقطوعة في طلبات العملاء السابقة: ${avgF.toStringAsFixed(0)} جنيه سوداني.');
        sb.writeln('  (النطاق: $rangeF)');
        if (rangeStr.isEmpty) rangeStr = rangeF;
      }

      return AiToolResult(
        context: sb.toString(),
        estimatedPriceRange: rangeStr,
      );
    } catch (e) {
      return AiToolResult.error(e.toString());
    }
  }

  // ─── Dispatcher ──────────────────────────────────────────────────
  Future<AiToolResult> executeToolCall(String toolName, String params, {double? lat, double? lng}) async {
    switch (toolName.toLowerCase().trim()) {
      case 'searchfreelancers':
      case 'searchfreelancer':
      case 'search':
        return await searchFreelancers(params, lat: lat, lng: lng);
      case 'searchshops':
      case 'searchshop':
        return await searchShops(params, lat: lat, lng: lng);
      case 'searchjobs':
      case 'searchjob':
        return await searchJobs(params);
      case 'getuserprofile':
      case 'userprofile':
      case 'profile':
        return await getUserProfile(params);
      case 'gettoprated':
      case 'toprated':
        return await getTopRated(category: params.isEmpty ? null : params);
      case 'searchsquads':
      case 'searchsquad':
      case 'squads':
        return await searchSquads(params, lat: lat, lng: lng);
      case 'getsquadprofile':
      case 'squadprofile':
        return await getSquadProfile(params);
      case 'getsquadmembers':
        return await getSquadMembers(params);
      case 'requests':
        return await searchRequests(params);
      case 'searchposts':
      case 'searchpost':
      case 'searchproducts':
      case 'posts':
      case 'products':
        return await searchPosts(params);
      case 'estimateserviceprice':
      case 'estimateprice':
      case 'price':
        return await estimateServicePrice(params);
      case 'getsuccessstories':
      case 'successstories':
      case 'stories':
        return await getSuccessStories();
      default:
        // Generic: try freelancers -> shops -> squads
        final freelancerResult = await searchFreelancers(params, lat: lat, lng: lng);
        if (freelancerResult.hasResults) return freelancerResult;
        final shopResult = await searchShops(params, lat: lat, lng: lng);
        if (shopResult.hasResults) return shopResult;
        return await searchSquads(params, lat: lat, lng: lng);
    }
  }
}

class AiToolResult {
  final String context;
  final List<UserModel> users;
  final List<SquadModel> squads;
  final List<RequestModel> requests;
  final List<JobModel> jobs;
  final List<PostModel> posts;
  final String? estimatedPriceRange;
  final bool hasResults;
  final bool isError;

  AiToolResult({
    required this.context,
    this.users = const [],
    this.squads = const [],
    this.requests = const [],
    this.jobs = const [],
    this.posts = const [],
    this.estimatedPriceRange,
    this.isError = false,
  }) : hasResults = context.isNotEmpty && context != 'NO_RESULTS' && !context.startsWith('ERROR');

  factory AiToolResult.empty(String query) => AiToolResult(
        context: 'لا توجد نتائج لـ "$query" في قاعدة البيانات حالياً.',
      );

  factory AiToolResult.error(String error) => AiToolResult(
        context: 'حدث خطأ أثناء البحث: $error',
        isError: true,
      );
}
