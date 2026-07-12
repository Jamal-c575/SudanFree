import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/common/glass_container.dart';
import '../../services/subscription_service.dart';
import '../../models/payment_method_model.dart';

class ProAccountScreen extends StatefulWidget {
  const ProAccountScreen({super.key});

  @override
  State<ProAccountScreen> createState() => _ProAccountScreenState();
}

class _ProAccountScreenState extends State<ProAccountScreen> {
  int _selectedPlan = 1; // 0=Basic, 1=Pro
  bool _isLoading = false;
  final SubscriptionService _subscriptionService = SubscriptionService();
  List<PaymentMethodModel> _paymentMethods = [];
  bool _isLoadingMethods = true;
  String _subscriptionStatus = ''; // 'pending', 'active' or ''

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
      'price': '15,000 ج.س/شهر',
      'price_en': '15,000 SDG/mo',
      'color': const Color(0xFF1a6b6b),
      'features_ar': ['ظهور مميز في نتائج البحث', 'شارة PRO في الملف الشخصي', 'إحصائيات متقدمة', '20 طلب يومياً', 'دعم فني مخصص', 'الظهور أولاً في اقتراحات الذكاء الاصطناعي'],
      'features_en': ['Featured in search results', 'PRO badge on profile', 'Advanced analytics', '20 daily requests', 'Dedicated support', 'First in AI suggestions'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final methods = await _subscriptionService.getPaymentMethods();
      final currentSub = await _subscriptionService.getCurrentPendingRequest();
      if (mounted) {
        setState(() {
          _paymentMethods = methods;
          _isLoadingMethods = false;
          if (currentSub != null) {
            _subscriptionStatus = currentSub.status;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMethods = false);
      }
    }
  }

  Future<void> _subscribe() async {
    if (_selectedPlan == 0) return;

    final isAr = context.read<LocaleProvider>().isArabic;
    
    if (_subscriptionStatus == 'pending') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAr ? 'لديك طلب قيد المراجعة حالياً' : 'You have a pending request')),
      );
      return;
    }

    if (_paymentMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAr ? 'لا توجد طرق دفع متاحة حالياً' : 'No payment methods available right now')),
      );
      return;
    }

    _showPaymentBottomSheet();
  }

  void _showPaymentBottomSheet() {
    final isAr = context.read<LocaleProvider>().isArabic;
    PaymentMethodModel? selectedMethod;
    File? receiptImage;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16, right: 16, top: 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? 'اختر طريقة الدفع' : 'Choose Payment Method',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  if (selectedMethod == null) ...[
                    ..._paymentMethods.map((m) => ListTile(
                          leading: const Icon(Icons.account_balance_wallet, color: Color(0xFF1a6b6b)),
                          title: Text(m.bankName, style: const TextStyle(color: Colors.black87)),
                          subtitle: Text('${m.accountName}\n${m.accountNumber}', style: const TextStyle(color: Colors.black54)),
                          onTap: () {
                            setModalState(() {
                              selectedMethod = m;
                            });
                          },
                        )),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(isAr ? 'بيانات التحويل:' : 'Transfer Details:', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                              TextButton(
                                onPressed: () => setModalState(() => selectedMethod = null),
                                child: Text(isAr ? 'تغيير البنك' : 'Change Bank'),
                              )
                            ],
                          ),
                          Text('${isAr ? 'البنك' : 'Bank'}: ${selectedMethod!.bankName}', style: const TextStyle(color: Colors.black87)),
                          Text('${isAr ? 'الاسم' : 'Name'}: ${selectedMethod!.accountName}', style: const TextStyle(color: Colors.black87)),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${isAr ? 'رقم الحساب' : 'Account No'}: ${selectedMethod!.accountNumber}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, color: Color(0xFF1a6b6b)),
                                tooltip: isAr ? 'نسخ رقم الحساب' : 'Copy Account Number',
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: selectedMethod!.accountNumber));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(isAr ? 'تم النسخ!' : 'Copied!')),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isAr ? 'الرجاء تحويل المبلغ المطلوب ثم إرفاق صورة الإيصال هنا.' : 'Please transfer the required amount then attach the receipt screenshot here.',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setModalState(() {
                            receiptImage = File(pickedFile.path);
                          });
                        }
                      },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: receiptImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(receiptImage!, fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                                  const SizedBox(height: 8),
                                  Text(isAr ? 'اضغط لإرفاق الإيصال' : 'Tap to attach receipt', style: const TextStyle(color: Colors.black87)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isUploading || receiptImage == null
                            ? null
                            : () async {
                                setModalState(() => isUploading = true);
                                try {
                                  final url = await _subscriptionService.uploadReceipt(receiptImage!, 'current');
                                  await _subscriptionService.submitSubscriptionRequest(plan: 'Pro', receiptUrl: url);
                                  
                                  if (mounted) {
                                    Navigator.pop(context);
                                    setState(() {
                                      _subscriptionStatus = 'pending';
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(isAr ? 'تم إرسال الطلب بنجاح. سنقوم بالمراجعة قريباً.' : 'Request sent successfully. We will review it soon.'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                } finally {
                                  setModalState(() => isUploading = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1a6b6b)),
                        child: isUploading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(isAr ? 'إرسال الطلب' : 'Submit Request', style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        });
      },
    );
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
                if (_subscriptionStatus == 'pending')
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.hourglass_bottom, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(child: Text(isAr ? 'لديك طلب اشتراك قيد المراجعة حالياً.' : 'You have a pending subscription request.', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
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
                        boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12, spreadRadius: 2)] : [],
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
                                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
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
                      onPressed: _isLoading || _isLoadingMethods || _subscriptionStatus == 'pending' ? null : _subscribe,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1a6b6b),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isAr
                                  ? 'اشترك في خطة ${_plans[_selectedPlan]['name_ar']}'
                                  : 'Subscribe to ${_plans[_selectedPlan]['name_en']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  isAr
                      ? '* سيتم تفعيل حسابك بعد مراجعة إيصال التحويل.'
                      : '* Your account will be activated after receipt review.',
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
