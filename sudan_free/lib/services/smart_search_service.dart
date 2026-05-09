/// خدمة البحث الذكي - Smart Search Service
/// يبحث باستخدام المرادفات والتطابق التقريبي بدون AI
class SmartSearchService {
  // مرادفات الأعمال الشائعة في السودان
  static const Map<String, List<String>> _jobSynonyms = {
    // السباكة
    'سباك': ['سباكة', 'سبّاك', 'فني صحي', 'فني مواسير', 'مواسير', 'صحي'],
    'سباكة': ['سباك', 'سبّاك', 'فني صحي', 'فني مواسير', 'مواسير'],
    
    // الكهرباء
    'كهربائي': ['كهرباء', 'كهربجي', 'فني كهرباء', 'كهربا'],
    'كهرباء': ['كهربائي', 'كهربجي', 'فني كهرباء'],
    
    // النجارة
    'نجار': ['نجارة', 'نجّار', 'فني أثاث', 'أثاث'],
    'نجارة': ['نجار', 'نجّار', 'فني أثاث'],
    
    // الحدادة
    'حداد': ['حدادة', 'حدّاد', 'فني حديد', 'حديد'],
    'حدادة': ['حداد', 'حدّاد', 'فني حديد'],
    
    // الدهان
    'دهان': ['دهانات', 'نقاش', 'صباغ', 'طلاء'],
    'نقاش': ['دهان', 'دهانات', 'صباغ', 'طلاء'],
    
    // البناء
    'بناء': ['بنّاء', 'عامل بناء', 'مقاول', 'بناية'],
    'مقاول': ['بناء', 'بنّاء', 'عامل بناء', 'مقاولات'],
    
    // التكييف
    'تكييف': ['مكيفات', 'فني تكييف', 'تبريد', 'مكيف'],
    'مكيفات': ['تكييف', 'فني تكييف', 'تبريد'],
    
    // السيارات
    'ميكانيكي': ['ميكانيكا', 'كهربائي سيارات', 'فني سيارات'],
    'كهربائي سيارات': ['ميكانيكي', 'فني سيارات', 'سيارات'],
    
    // التعليم
    'مدرس': ['مدرّس', 'معلم', 'أستاذ', 'تدريس'],
    'معلم': ['مدرس', 'مدرّس', 'أستاذ', 'تدريس'],
    
    // التصميم
    'مصمم': ['تصميم', 'مصمم جرافيك', 'جرافيك', 'ديزاينر'],
    'تصميم': ['مصمم', 'مصمم جرافيك', 'جرافيك'],
    
    // البرمجة
    'مبرمج': ['برمجة', 'مطور', 'برمجي', 'developer'],
    'مطور': ['مبرمج', 'برمجة', 'برمجي', 'developer'],
    
    // التنظيف
    'تنظيف': ['نظافة', 'عامل نظافة', 'تنضيف'],
    'نظافة': ['تنظيف', 'عامل نظافة'],
    
    // النقل
    'سائق': ['سواق', 'توصيل', 'نقل'],
    'نقل': ['سائق', 'سواق', 'توصيل', 'ناقل'],
    
    // الطبخ
    'طباخ': ['طبخ', 'شيف', 'طاهي'],
    'شيف': ['طباخ', 'طبخ', 'طاهي'],
  };

  /// استخراج اقتراحات بحث محفوظة محلياً في التطبيق بناءً على الإدخال
  static List<String> getPredefinedSuggestions(String query) {
    if (query.isEmpty) return [];
    
    final normalizedQuery = _normalizeArabic(query.toLowerCase().trim());
    final Set<String> results = {};
    
    // البحث في المفاتيح الأساسية
    for (final key in _jobSynonyms.keys) {
      if (_normalizeArabic(key).contains(normalizedQuery)) {
        results.add(key);
      }
    }
    
    // البحث في المرادفات
    for (final entry in _jobSynonyms.entries) {
      for (final synonym in entry.value) {
        if (_normalizeArabic(synonym).contains(normalizedQuery)) {
          results.add(synonym);
          // يمكن أيضاً إضافة المفتاح الرئيسي ليظهر كخيار
          results.add(entry.key); 
        }
      }
    }
    
    // إضافة المجالات الأخرى وتصنيفات المتاجر
    const otherKeywords = [
      // خدمات متنوعة
      'تطوير تطبيقات', 'مونتاج فيديو', 'إدخال بيانات', 'تسويق', 
      'ترجمة', 'صيانة أجهزة', 'خياطة', 'تجميل', 'مدرس خصوصي',
      'محامي', 'نقل عفش', 'مشاوير',
      // تصنيفات المتاجر (Shops)
      'إلكترونيات', 'ملابس', 'أثاث', 'مواد غذائية', 'مطعم',
      'سوبرماركت', 'صيدلية', 'تجميل ومستحضرات', 'قطع غيار سيارات',
      'مواد بناء', 'مجوهرات', 'جوالات وإكسسوارات', 'مكتبة',
      'رياضة', 'ألعاب أطفال', 'أدوات منزلية', 'موبايلات'
    ];
    
    for (final keyword in otherKeywords) {
      if (_normalizeArabic(keyword).contains(normalizedQuery)) {
        results.add(keyword);
      }
    }
    
    return results.take(8).toList();
  }

  // كلمات الربط التي تفصل بين الخدمة والموقع
  static const List<String> _locationKeywords = ['في', 'ب', 'من', 'قرب', 'حي', 'منطقة', 'شارع'];

  // أسماء أحياء ومناطق مشهورة في السودان (للتطابق التقريبي)
  static const List<String> _knownNeighborhoods = [
    // ==================== ولاية الخرطوم ====================
    // الخرطوم
    'الرياض', 'المعمورة', 'الخرطوم ٢', 'الخرطوم 2', 'الصحافة', 'جبرة', 'المنشية',
    'الديوم', 'الديوم الشرقية', 'بري', 'بري اللاماب', 'بري المحس',
    'الطائف', 'الأزهري', 'المقرن', 'الخرطوم شرق', 'كافوري',
    'أركويت', 'الشجرة', 'جبل المرخيات', 'سوبا', 'الكلاكلة',
    'ناصر', 'الفيحاء', 'الجريف شرق', 'الجريف غرب', 'المنصورة',
    'الاندلس', 'النزهة', 'حي العرب', 'الشهيد طه', 'العمارات', 'الخرطوم ٣',
    'جبل أولياء', 'الشعبية', 'النصر', 'حلة حمد', 'الدروشاب',
    // أم درمان
    'أم بدة', 'ام بدة', 'أم بده', 'الثورة', 'أبو سعد', 'ابو سعد',
    'الفتيحاب', 'بيت المال', 'الملازمين', 'الموردة', 'العباسية',
    'ود نوباوي', 'أبو روف', 'ابو روف', 'الحارة', 'الحارة الأولى',
    'الحارة الثانية', 'الحارة الثالثة', 'العرضة', 'السوق الكبير',
    'ال30', 'ال ٣٠', 'الثلاثين', 'عربية خاصة',
    'أم درمان الثورة', 'حي النصر', 'حي الوحدة', 'الهاشماب',
    'ود البخيت', 'الخليفة', 'حي السلام', 'حي المهندسين',
    // بحري
    'الحاج يوسف', 'حاج يوسف', 'الحلفاية', 'شمبات', 'الصبابي',
    'الخوجلاب', 'التكينة', 'بحري الصناعية', 'المزاد',
    'حلة خوجلي', 'الدناقلة', 'الكدرو', 'السامراب',
    'الشقلة', 'أم دوم', 'ام دوم', 'الباقير', 'المؤسسة',
    // كرري وشرق النيل
    'كرري', 'أم القرى', 'الفتح', 'أبو حليمة',
    'شرق النيل', 'الجريف', 'حلة كوكو',

    // ==================== ولاية الجزيرة ====================
    'ود مدني', 'الكاملين', 'الحصاحيصا', 'المناقل', 'الهلالية',
    'حي الموظفين', 'حي الضباط', 'حي الوادي', 'حي السلام', 'حي الربيع',
    'حنتوب', 'الحوش', 'طابت', 'الحاج عبدالله', 'أبو عشر',
    'ود النيل', 'ود المليك', 'المسيد', 'الخيرات', 'أبو حراز',

    // ==================== ولاية نهر النيل ====================
    'الدامر', 'عطبرة', 'شندي', 'بربر', 'أبو حمد', 'المتمة',
    'حي السوق', 'حي الجامعة', 'حي المطار', 'حي الشاطئ',
    'أم علي', 'كبوشية', 'الزيداب', 'العبيدية', 'المكابراب',
    'حي النخيل', 'حي البساتين', 'حي التقدم', 'حي الأمل',

    // ==================== الولاية الشمالية ====================
    'دنقلا', 'مروي', 'كريمة', 'دلقو', 'حلفا', 'أرقو', 'نوري',
    'الدبة', 'البرقيق', 'القولد', 'صاي', 'دنقلا العجوز',
    'الغابة', 'الخندق', 'أبكر', 'جدي',

    // ==================== ولاية كسلا ====================
    'كسلا', 'حلفا الجديدة', 'خشم القربة', 'ود الحليو', 'أروما',
    'حي الجامعة', 'حي المطار', 'حي التاكا', 'حي النشيشبة',
    'حي كرن', 'حي الخلاء', 'حي المنشية', 'حي الميرغنية',
    'تلكوك', 'همشكوريب', 'الشوك',

    // ==================== ولاية القضارف ====================
    'القضارف', 'قلع النحل', 'الفاو', 'الفشقة', 'القريشة', 'الرهد',
    'حي الشرقي', 'حي الغربي', 'حي الوحدة', 'حي الثورة',
    'حي المصالح', 'حي سلالاب', 'حي المدنيين', 'الغرب',
    'دوكة', 'القلابات', 'أم السنط',

    // ==================== ولاية البحر الأحمر ====================
    'بورتسودان', 'سواكن', 'طوكر', 'هيا', 'جبيت', 'سنكات',
    'حي ديم عرب', 'حي ديم مدني', 'حي ديم النور', 'حي السلام',
    'حي الضباط', 'حي المطار', 'حي الهبيل', 'حي العمال',
    'حي الأمراء', 'حي البوادر', 'حي المينا', 'حي فلامنقو',

    // ==================== ولاية سنار ====================
    'سنار', 'سنجة', 'الدندر', 'الدالي', 'المزموم',
    'حي العشرة', 'حي السوق', 'حي البوستة', 'حي الدرجة',
    'أبو نعامة', 'مايورنو', 'الصوفي',

    // ==================== ولاية النيل الأزرق ====================
    'الدمازين', 'الروصيرص', 'باو', 'قيسان', 'الكرمك',
    'حي السوق', 'حي الوحدة', 'حي السلام', 'حي النيل',
    'ديم النور', 'حي المعلمين', 'حي المهندسين',

    // ==================== ولاية النيل الأبيض ====================
    'ربك', 'كوستي', 'الدويم', 'تندلتي', 'أم رمتة', 'الجزيرة أبا',
    'حي المنشية', 'حي بانت', 'حي الأزهري', 'حي السلام',
    'حي النصر', 'حي الثورة', 'حي الزهور', 'أم جر',
    'جبل الأولياء', 'الجبلين', 'كنانة',

    // ==================== شمال كردفان ====================
    'الأبيض', 'شيكان', 'أم روابة', 'النهود', 'بارا', 'سودري',
    'حي السوق الكبير', 'حي الثورة', 'حي السلام', 'حي المعلمين',
    'حي أبو حبل', 'حي النزلة', 'حي الموظفين', 'حي الضباط',
    'حي المطار', 'حي النصر', 'أم درمان كردفان',

    // ==================== جنوب كردفان ====================
    'كادقلي', 'الدلنج', 'أبو جبيهة', 'تلودي', 'رشاد', 'الليري',
    'حي السوق', 'حي الضباط', 'حي الأمل', 'حي العسكر',
    'هبيلا', 'كيلك', 'كلوقي', 'أم برمبيطة',

    // ==================== غرب كردفان ====================
    'الفولة', 'النهود', 'أبو زبد', 'المجلد', 'لقاوة',
    'حي السوق', 'حي البلدية', 'حي الثورة', 'حي النصر',
    'بابنوسة', 'المرام', 'غبيش',

    // ==================== شمال دارفور ====================
    'الفاشر', 'كتم', 'كبكابية', 'أم كدادة', 'الكومة', 'طويلة', 'مليط',
    'حي السوق', 'حي المطار', 'حي الوحدة', 'حي السلام',
    'حي الثورة', 'حي الميدان', 'أبو شوك',

    // ==================== جنوب دارفور ====================
    'نيالا', 'كاس', 'مرشنج', 'قريضة', 'تلس', 'عد الفرسان', 'شعيرية',
    'حي السوق الكبير', 'حي دومة', 'حي السلام', 'حي الوحدة',
    'حي المطار', 'حي الثورة', 'حي المنشية', 'كلمة',

    // ==================== غرب دارفور ====================
    'الجنينة', 'كرينك', 'سربا', 'هبيلا', 'مستري', 'بيضة',
    'حي السوق', 'حي الجامعة', 'حي النصر', 'حي الوحدة',
    'حي الشهداء', 'حي الضباط', 'مسطري',

    // ==================== وسط دارفور ====================
    'زالنجي', 'نرتتي', 'أم دخن', 'أزوم', 'بندسي',
    'حي السوق', 'حي المركز', 'حي السلام', 'روكيرو',

    // ==================== شرق دارفور ====================
    'الضعين', 'أبو كارنكا', 'عديلة', 'أبو جابرة',
    'حي السوق', 'حي الشعبي', 'حي النصر', 'حي المجلس',
    'أبو مطارق', 'لعيت',
  ];

  /// البحث الذكي - يشمل المرادفات والتطابق الجزئي
  static bool matchesSearch(String searchQuery, {
    required String name,
    required List<String> skills,
    String? jobTitle,
    String? bio,
  }) {
    if (searchQuery.isEmpty) return true;
    
    final query = _normalizeArabic(searchQuery.toLowerCase().trim());
    final expandedQueries = _expandQuery(query);
    
    // البحث في كل الحقول
    for (final q in expandedQueries) {
      // البحث في الاسم
      if (_containsMatch(_normalizeArabic(name.toLowerCase()), q)) return true;
      
      // البحث في نوع العمل
      if (jobTitle != null && _containsMatch(_normalizeArabic(jobTitle.toLowerCase()), q)) return true;
      
      // البحث في المهارات
      for (final skill in skills) {
        if (_containsMatch(_normalizeArabic(skill.toLowerCase()), q)) return true;
      }
      
      // البحث في النبذة
      if (bio != null && _containsMatch(_normalizeArabic(bio.toLowerCase()), q)) return true;
    }
    
    return false;
  }

  /// البحث الذكي المتقدم - يفهم جمل مثل "سباك في أم درمان"
  /// يفصل الاستعلام إلى جزء المهارة وجزء الموقع
  static bool matchesSmartSearch(String searchQuery, {
    required String name,
    required List<String> skills,
    String? jobTitle,
    String? bio,
    String? state,
    String? locality,
  }) {
    if (searchQuery.isEmpty) return true;
    
    final query = _normalizeArabic(searchQuery.toLowerCase().trim());
    
    // محاولة تقسيم الاستعلام إلى مهارة + موقع
    final parsed = _parseQuery(query);
    
    if (parsed != null) {
      // تم العثور على كلمة ربط → بحث مركب (مهارة + موقع)
      final skillMatch = _matchesSkillPart(parsed.skillPart, name: name, skills: skills, jobTitle: jobTitle);
      final locationMatch = _matchesLocationPart(parsed.locationPart, bio: bio, state: state, locality: locality);
      return skillMatch && locationMatch;
    }
    
    // لا توجد كلمة ربط → بحث عادي (ممكن يكون اسم حي أو مهارة)
    // جرّب البحث العادي أولاً
    if (matchesSearch(searchQuery, name: name, skills: skills, jobTitle: jobTitle, bio: bio)) {
      return true;
    }
    
    // جرّب مطابقة كحي في النبذة أو الموقع
    if (_matchesLocationPart(query, bio: bio, state: state, locality: locality)) {
      return true;
    }
    
    return false;
  }

  /// تقسيم الاستعلام إلى مهارة + موقع
  static _ParsedQuery? _parseQuery(String query) {
    for (final keyword in _locationKeywords) {
      final normalizedKeyword = _normalizeArabic(keyword);
      // البحث عن "في" أو "ب" ككلمة منفصلة
      final pattern = keyword.length == 1
          ? ' $normalizedKeyword' // حرف واحد مثل "ب" → يجب أن يسبقه مسافة
          : ' $normalizedKeyword '; // كلمة كاملة مثل "في"
      
      final index = query.indexOf(pattern);
      if (index > 0) {
        final skillPart = query.substring(0, index).trim();
        final locationPart = query.substring(index + pattern.length).trim();
        if (skillPart.isNotEmpty && locationPart.isNotEmpty) {
          return _ParsedQuery(skillPart: skillPart, locationPart: locationPart);
        }
      }
    }
    return null;
  }

  /// مطابقة جزء المهارة
  static bool _matchesSkillPart(String skillQuery, {
    required String name,
    required List<String> skills,
    String? jobTitle,
  }) {
    final expandedQueries = _expandQuery(skillQuery);
    for (final q in expandedQueries) {
      if (_containsMatch(_normalizeArabic(name.toLowerCase()), q)) return true;
      if (jobTitle != null && _containsMatch(_normalizeArabic(jobTitle.toLowerCase()), q)) return true;
      for (final skill in skills) {
        if (_containsMatch(_normalizeArabic(skill.toLowerCase()), q)) return true;
      }
    }
    return false;
  }

  /// مطابقة جزء الموقع (ولاية، محلية، نبذة، أحياء)
  static bool _matchesLocationPart(String locationQuery, {
    String? bio,
    String? state,
    String? locality,
  }) {
    final normalizedQuery = _normalizeArabic(locationQuery);
    
    // مطابقة مباشرة مع الولاية والمحلية
    if (state != null && _containsMatch(_normalizeArabic(state.toLowerCase()), normalizedQuery)) return true;
    if (locality != null && _containsMatch(_normalizeArabic(locality.toLowerCase()), normalizedQuery)) return true;
    
    // مطابقة مع النبذة (هنا يكتب المستخدم حيه)
    if (bio != null) {
      final normalizedBio = _normalizeArabic(bio.toLowerCase());
      if (_containsMatch(normalizedBio, normalizedQuery)) return true;
      
      // مطابقة تقريبية مع أسماء الأحياء المعروفة
      // إذا بحث المستخدم باسم حي معروف، نبحث عنه في النبذة بتطابق تقريبي
      for (final neighborhood in _knownNeighborhoods) {
        final normalizedNeighborhood = _normalizeArabic(neighborhood.toLowerCase());
        // هل الاستعلام يطابق اسم حي معروف (تقريبياً)؟
        if (_isFuzzyMatch(normalizedQuery, normalizedNeighborhood)) {
          // هل هذا الحي مذكور في النبذة (تقريبياً)؟
          final bioWords = normalizedBio.split(RegExp(r'\s+'));
          for (int i = 0; i < bioWords.length; i++) {
            // مطابقة كلمة واحدة أو كلمتين متتاليتين
            final singleWord = bioWords[i];
            final doubleWord = i + 1 < bioWords.length ? '${bioWords[i]} ${bioWords[i + 1]}' : '';
            
            if (_isFuzzyMatch(singleWord, normalizedNeighborhood) ||
                _isFuzzyMatch(doubleWord, normalizedNeighborhood)) {
              return true;
            }
          }
        }
      }
    }
    
    return false;
  }

  /// مطابقة تقريبية متقدمة - تسمح بأخطاء إملائية
  static bool _isFuzzyMatch(String text, String target) {
    if (text.isEmpty || target.isEmpty) return false;
    if (text == target) return true;
    if (text.contains(target) || target.contains(text)) return true;
    
    // مقارنة بدون فراغات
    final textNoSpaces = text.replaceAll(' ', '');
    final targetNoSpaces = target.replaceAll(' ', '');
    if (textNoSpaces == targetNoSpaces) return true;
    if (textNoSpaces.contains(targetNoSpaces) || targetNoSpaces.contains(textNoSpaces)) return true;
    
    // Levenshtein-like: إذا كان الفرق <= 2 حرف (للكلمات الطويلة)
    if (text.length >= 3 && target.length >= 3) {
      final distance = _levenshtein(textNoSpaces, targetNoSpaces);
      final maxLen = textNoSpaces.length > targetNoSpaces.length ? textNoSpaces.length : targetNoSpaces.length;
      // سماح بخطأ 1 لكل 4 أحرف (الحد الأدنى 1)
      final allowedErrors = (maxLen / 4).ceil();
      if (distance <= allowedErrors) return true;
    }
    
    return false;
  }

  /// حساب مسافة Levenshtein (عدد التعديلات للتحويل من نص لآخر)
  static int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;
    
    List<int> previousRow = List<int>.generate(t.length + 1, (i) => i);
    
    for (int i = 0; i < s.length; i++) {
      List<int> currentRow = [i + 1];
      for (int j = 0; j < t.length; j++) {
        final cost = s[i] == t[j] ? 0 : 1;
        currentRow.add([
          currentRow[j] + 1,           // إدخال
          previousRow[j + 1] + 1,      // حذف
          previousRow[j] + cost,       // استبدال
        ].reduce((a, b) => a < b ? a : b));
      }
      previousRow = currentRow;
    }
    return previousRow.last;
  }

  /// توسيع البحث ليشمل المرادفات
  static List<String> _expandQuery(String query) {
    final queries = <String>{query};
    
    // إضافة المرادفات
    _jobSynonyms.forEach((key, synonyms) {
      final normalizedKey = _normalizeArabic(key);
      if (query.contains(normalizedKey) || normalizedKey.contains(query)) {
        queries.add(normalizedKey);
        for (final syn in synonyms) {
          queries.add(_normalizeArabic(syn));
        }
      }
    });
    
    return queries.toList();
  }

  /// التطابق الجزئي (Fuzzy)
  static bool _containsMatch(String text, String query) {
    // تطابق مباشر
    if (text.contains(query)) return true;
    
    // التطابق إذا كان الفرق حرف واحد فقط
    final words = text.split(' ');
    for (final word in words) {
      if (_isCloseMatch(word, query)) return true;
    }
    
    return false;
  }

  /// التطابق التقريبي - يسمح بفرق حرف واحد
  static bool _isCloseMatch(String word, String query) {
    if (word == query) return true;
    if ((word.length - query.length).abs() > 2) return false;
    
    // إذا كانت الكلمة تبدأ بنفس الأحرف
    if (word.length >= 3 && query.length >= 3) {
      if (word.substring(0, 3) == query.substring(0, 3)) return true;
    }
    
    return false;
  }

  /// تطبيع النص العربي (إزالة التشكيل والهمزات)
  static String _normalizeArabic(String text) {
    return text
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'[\u064B-\u065F]'), ''); // إزالة التشكيل
  }
}

/// نتيجة تقسيم الاستعلام
class _ParsedQuery {
  final String skillPart;
  final String locationPart;
  
  _ParsedQuery({required this.skillPart, required this.locationPart});
}
