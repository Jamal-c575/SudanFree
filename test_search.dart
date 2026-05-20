import 'sudan_free/lib/services/smart_search_service.dart';

void main() {
  final isPlumberMatch = SmartSearchService.matchesSmartSearch(
    'سباك',
    name: 'أحمد',
    skills: ['تطوير تطبيقات', 'مبرمج'],
    jobTitle: 'مبرمج',
    bio: 'أعمل بشكل صحيح',
  );
  
  print('Does "سباك" match programmer with bio "صحيح"? $isPlumberMatch');
  
  final isRealPlumber = SmartSearchService.matchesSmartSearch(
    'سباك',
    name: 'علي',
    skills: ['صيانة منزلية', 'سباكة'],
    jobTitle: 'فني صحي',
    bio: 'خبرة 10 سنوات',
  );
  
  print('Does "سباك" match actual plumber? $isRealPlumber');
}
