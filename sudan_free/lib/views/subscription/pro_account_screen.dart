import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/common/glass_container.dart';

class ProAccountScreen extends StatefulWidget {
  const ProAccountScreen({super.key});

  @override
  State<ProAccountScreen> createState() => _ProAccountScreenState();
}

class _ProAccountScreenState extends State<ProAccountScreen> {
  int _selectedPlan = 1; // 0=Basic, 1=Pro, 2=Elite
  bool _isLoading = false;

  final _plans = [
    {
      'name_ar': 'أساسي',
      'name_en': 'Basic',
      'price': 'مجاني',
      'price_en': 'Free',
      'color': Colors.grey,
      'features_ar': ['بحث أساسي', '5 طلبات يومياً', 'ملف شخصي عادي', 'دعم عبر البريد'],
      'features_en': ['Basic search', '5 daily requests', 'Standard profile', 'Email support'],
    },
    {
      'name_ar': 'محترف',
      'name_en': 'Pro',
      'price': '9.99\$/شهر',
      'price_en': '\$9.99/month',
      'color': const Color(0xFF1a6b6b),
      'features_ar': ['ظهور مميز في نتائج البحث', 'شارة PRO في الملف الشخصي', 'إحصائيات متقدمة', '20 طلب يومياً', 'دعم فني مخصص', 'إخفاء الإعلانات'],
      'features_en': ['Featured in search results', 'PRO badge on profile', 'Advanced analytics', '20 daily requests', 'Dedicated support', 'Ad-free experience'],
    },
    {
      'name_ar': 'نخبة',
      'name_en': 'Elite',
      'price': '19.99\$/شهر',
      'price_en': '\$19.99/month',
      'color': const Color(0xFFFFB300),
      'features_ar': ['كل مزايا Pro', 'ظهور أول في الخريطة', 'إعلانات مجانية شهرية', 'مدير حساب مخصص', 'طلبات غير محدودة', 'تحليلات السوق'],
      'features_en': ['All Pro features', 'First on map', 'Free monthly ads', 'Dedicated account manager', 'Unlimited requests', 'Market analytics'],
    },
  ];

  Future<void> _subscribe() async {
    if (_selectedPlan == 0) return;
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final planName = _plans[_selectedPlan]['name_ar'];
      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'isPremium': true,
        'premiumPlan': planName,
        'premiumSince': FieldValue.serverTimestamp(),
        'premiumUntil': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create subscription record
      await FirebaseFirestore.instance.collection('subscriptions').add({
        'userId': user.id,
        'plan': planName,
        'amount': _selectedPlan == 1 ? 9.99 : 19.99,
        'currency': 'USD',
        'status': 'active',
        'startDate': FieldValue.serverTimestamp(),
        'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم الاشتراك في خطة $planName بنجاح! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<LocaleProvider>().isArabic;
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF0d3d3d),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0d3d3d), Color(0xFF1a6b6b), Color(0xFF0d3d3d)],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    const Icon(Icons.workspace_premium, color: Color(0xFFFFB300), size: 56),
                    const SizedBox(height: 12),
                    Text(
                      isAr ? 'ترقية الحساب' : 'Account Upgrade',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      isAr ? 'افتح إمكانياتك الكاملة' : 'Unlock your full potential',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                ...List.generate(_plans.length, (index) {
                  final plan = _plans[index];
                  final isSelected = _selectedPlan == index;
                  final color = plan['color'] as Color;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedPlan = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? color : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, spreadRadius: 2)] : [],
                      ),
                      child: GlassContainer(
                        borderRadius: BorderRadius.circular(18),
                        padding: const EdgeInsets.all(20),
                        enableBlur: true,
                        blur: 10,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    if (isSelected)
                                      Icon(Icons.check_circle, color: color, size: 22),
                                    if (!isSelected)
                                      Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 22),
                                    const SizedBox(width: 10),
                                    Text(
                                      isAr ? plan['name_ar'] as String : plan['name_en'] as String,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                      ),
                                    ),
                                    if (index == 1) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1a6b6b),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          isAr ? 'الأكثر شيوعاً' : 'Most Popular',
                                          style: const TextStyle(color: Colors.white, fontSize: 10),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  isAr ? plan['price'] as String : plan['price_en'] as String,
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ...(isAr ? plan['features_ar'] as List<String> : plan['features_en'] as List<String>)
                                .map((f) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        children: [
                                          Icon(Icons.check, color: color, size: 16),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(f,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: theme.colorScheme.onSurface.withOpacity(0.85),
                                                )),
                                          ),
                                        ],
                                      ),
                                    )),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                if (_selectedPlan > 0)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _subscribe,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedPlan == 2 ? const Color(0xFFFFB300) : const Color(0xFF1a6b6b),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isAr
                                  ? 'اشترك في خطة ${_plans[_selectedPlan]['name_ar']}'
                                  : 'Subscribe to ${_plans[_selectedPlan]['name_en']}',
                              style: TextStyle(
                                color: _selectedPlan == 2 ? Colors.black87 : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  isAr
                      ? '* يمكن إلغاء الاشتراك في أي وقت. لا يوجد رسوم خفية.'
                      : '* Cancel anytime. No hidden fees.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
