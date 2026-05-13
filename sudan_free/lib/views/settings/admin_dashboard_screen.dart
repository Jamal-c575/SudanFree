import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../models/user_model.dart';
import '../../models/ad_model.dart';
import '../../widgets/common/loading_widget.dart';
import '../../core/constants/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة تحكم المشرف', style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'الإحصائيات', icon: Icon(Icons.analytics)),
              Tab(text: 'طلبات التوثيق', icon: Icon(Icons.verified_user)),
              Tab(text: 'طلبات الحذف', icon: Icon(Icons.delete_sweep)),
              Tab(text: 'سجل العقود', icon: Icon(Icons.handshake)),
              Tab(text: 'الإعلانات', icon: Icon(Icons.campaign)),
            ],
          ),
        ),
        body: Container(
          color: Colors.grey[50],
          child: TabBarView(
            children: [
              _buildStatistics(),
              _buildVerificationQueue(),
              _buildDeletionQueue(),
              _buildContractsLog(),
              _buildAdsManager(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const LoadingIndicator();
        final stats = snapshot.data ?? {};

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'نظرة عامة على النظام',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildStatCard('إجمالي المستخدمين', stats['totalUsers'].toString(), Icons.people, Colors.blue),
                  _buildStatCard('الموثقين', stats['verifiedUsers'].toString(), Icons.verified, Colors.green),
                  _buildStatCard('المنشورات', stats['totalPosts'].toString(), Icons.post_add, Colors.orange),
                  _buildStatCard('المشاريع والطلبات', stats['totalJobs'].toString(), Icons.work, Colors.purple),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey[800], fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getStats() async {
    final users = await FirebaseFirestore.instance.collection('users').count().get();
    final verified = await FirebaseFirestore.instance.collection('users').where('isVerified', isEqualTo: true).count().get();
    final posts = await FirebaseFirestore.instance.collection('posts').count().get();
    final jobs = await FirebaseFirestore.instance.collection('jobs').count().get();

    return {
      'totalUsers': users.count,
      'verifiedUsers': verified.count,
      'totalPosts': posts.count,
      'totalJobs': jobs.count,
    };
  }

  Widget _buildVerificationQueue() {
    return StreamBuilder<List<UserModel>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('verificationStatus', isEqualTo: 'pending')
          .snapshots()
          .map((s) => s.docs.map((d) => UserModel.fromFirestore(d)).toList()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const LoadingIndicator();
        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return _buildEmptyState(Icons.verified_user_outlined, 'لا توجد طلبات توثيق معلقة');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: user.profileImageUrl != null ? NetworkImage(user.profileImageUrl!) : null,
                  child: user.profileImageUrl == null ? const Icon(Icons.person, color: AppColors.primary) : null,
                ),
                title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.phoneNumber ?? user.email, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text('المهنة: ${user.jobTitle ?? 'غير محدد'}', style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                    ],
                  ),
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _showReviewDialog(context, user),
                  child: const Text('مراجعة'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showReviewDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('توثيق: ${user.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('صورة الهوية المرفقة:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (user.idCardUrl != null)
              GestureDetector(
                onTap: () => _showImagePreview(context, user.idCardUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: user.idCardUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  ),
                ),
              )
            else
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Text('لم يتم رفع هوية', style: TextStyle(color: Colors.red))),
              ),
            const SizedBox(height: 16),
            const Text('هل الهوية مطابقة لبيانات المستخدم الحقيقية؟', style: TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          if (user.phoneNumber != null)
            TextButton(
              onPressed: () => _sendAdminOtp(context, user.phoneNumber!),
              child: const Text('إرسال رمز واتساب', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
          TextButton(
            onPressed: () => _updateVerification(user.id, VerificationStatus.rejected),
            child: const Text('رفض الطلب', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () => _updateVerification(user.id, VerificationStatus.verified),
            child: const Text('توثيق الحساب'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateVerification(String userId, VerificationStatus status) async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'verificationStatus': status.name,
      'isVerified': status == VerificationStatus.verified,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (mounted) nav.pop();
    messenger.showSnackBar(SnackBar(
      content: Text(status == VerificationStatus.verified ? 'تم توثيق الحساب بنجاح' : 'تم رفض التوثيق'),
      backgroundColor: status == VerificationStatus.verified ? Colors.green : Colors.red,
    ));
  }

  Future<void> _sendAdminOtp(BuildContext context, String phoneNumber) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('sendWhatsAppOTP');
      final result = await callable.call({'phoneNumber': phoneNumber});
      final data = result.data as Map<String, dynamic>;
      if (data['success'] == true) {
        messenger.showSnackBar(const SnackBar(content: Text('تم إرسال رمز التحقق عبر واتساب')));
      } else {
        messenger.showSnackBar(SnackBar(content: Text(data['message'] ?? 'فشل إرسال الرمز'), backgroundColor: Colors.red));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('فشل إرسال رمز واتساب: $e'), backgroundColor: Colors.red));
    }
  }

  Widget _buildDeletionQueue() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('deletion_requests')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const LoadingIndicator();
        final requests = snapshot.data?.docs ?? [];

        if (requests.isEmpty) {
          return _buildEmptyState(Icons.person_remove_outlined, 'لا توجد طلبات حذف معلقة');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            final data = req.data() as Map<String, dynamic>;
            
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.red.withValues(alpha: 0.3))),
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(data['name'] ?? 'مستخدم', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('السبب المذكور:', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(data['reason'] ?? 'لم يذكر', style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('تأكيد الحذف'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _showDeleteApprovalDialog(context, req.id, data['userId'], data['name']),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteApprovalDialog(BuildContext context, String requestId, String userId, String userName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد حذف $userName', style: const TextStyle(color: Colors.red)),
        content: const Text('هل أنت متأكد من رغبتك في الموافقة على طلب الحذف؟ سيتم مسح حساب المستخدم نهائياً ولن يتمكن من الدخول مرة أخرى.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
              
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(context);
              
              try {
                await FirebaseFirestore.instance.collection('users').doc(userId).delete();
                await FirebaseFirestore.instance.collection('deletion_requests').doc(requestId).update({
                  'status': 'approved',
                  'approvedAt': FieldValue.serverTimestamp(),
                });
                if (mounted) {
                  nav.pop();
                  messenger.showSnackBar(const SnackBar(content: Text('تم حذف الحساب نهائياً'), backgroundColor: Colors.green));
                }
              } catch (e) {
                if (mounted) {
                  nav.pop();
                  messenger.showSnackBar(SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('تأكيد وحذف'),
          ),
        ],
      ),
    );
  }

  Widget _buildContractsLog() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('messages')
          .where('type', isEqualTo: 'contract')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const LoadingIndicator();
        if (snapshot.hasError) {
          return Center(child: Text('خطأ في جلب العقود. تأكد من وجود Index.\n${snapshot.error}', textAlign: TextAlign.center));
        }

        final contracts = snapshot.data?.docs ?? [];
        if (contracts.isEmpty) return _buildEmptyState(Icons.handshake_outlined, 'لا توجد عقود مسجلة في النظام');

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: contracts.length,
          itemBuilder: (context, index) {
            final data = contracts[index].data() as Map<String, dynamic>;
            final status = data['contractStatus'] ?? 'pending';
            final price = data['contractPrice'] ?? 0;
            
            Color statusColor = Colors.orange;
            String statusText = 'قيد الانتظار';
            IconData statusIcon = Icons.pending_actions;
            
            if (status == 'accepted') { statusColor = Colors.green; statusText = 'مقبول'; statusIcon = Icons.check_circle; }
            else if (status == 'rejected') { statusColor = Colors.red; statusText = 'مرفوض'; statusIcon = Icons.cancel; }
            else if (status == 'cancelled') { statusColor = Colors.grey; statusText = 'ملغى'; statusIcon = Icons.not_interested; }

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: statusColor.withValues(alpha: 0.1),
                  child: Icon(statusIcon, color: statusColor),
                ),
                title: Text('${data['senderName'] ?? 'مجهول'} ➔ عميل', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(data['contractDetails'] ?? '', style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('السعر: $price SDG', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAdsManager() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('ads').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const LoadingIndicator();
          final ads = snapshot.data?.docs ?? [];

          if (ads.isEmpty) return _buildEmptyState(Icons.campaign_outlined, 'لا توجد إعلانات حالياً');

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: ads.length,
            itemBuilder: (context, index) {
              final ad = AdModel.fromFirestore(ads[index]);
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    if (ad.mediaUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: CachedNetworkImage(imageUrl: ad.mediaUrl, height: 150, width: double.infinity, fit: BoxFit.cover),
                      ),
                    ListTile(
                      title: Text(ad.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${ad.targetRegion == 'all' ? 'كل المناطق' : ad.targetRegion} | ${ad.targetProfession == 'all' ? 'الكل' : ad.targetProfession}'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: ad.isValid ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(ad.isValid ? 'نشط' : 'منتهي', style: TextStyle(color: ad.isValid ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                    const Divider(height: 1),
                    OverflowBar(
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text('حذف', style: TextStyle(color: Colors.red)),
                          onPressed: () => _deleteAd(ad.id),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showAddAdDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('إعلان جديد'),
      ),
    );
  }

  void _showAddAdDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final mediaUrlCtrl = TextEditingController();
    String targetRegion = 'all';
    String targetProfession = 'all';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('إضافة إعلان جديد', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'عنوان الإعلان', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'الوصف', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: mediaUrlCtrl, decoration: const InputDecoration(labelText: 'رابط الصورة (URL)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(decoration: const InputDecoration(labelText: 'المنطقة (اتركه فارغاً للكل)', border: OutlineInputBorder()), onChanged: (val) => targetRegion = val.isEmpty ? 'all' : val),
            const SizedBox(height: 12),
            TextField(decoration: const InputDecoration(labelText: 'المهنة (اتركه فارغاً للكل)', border: OutlineInputBorder()), onChanged: (val) => targetProfession = val.isEmpty ? 'all' : val),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: () async {
                if (titleCtrl.text.isEmpty || mediaUrlCtrl.text.isEmpty) return;
                
                final nav = Navigator.of(ctx);
                
                await FirebaseFirestore.instance.collection('ads').add({
                  'title': titleCtrl.text,
                  'description': descCtrl.text,
                  'mediaUrl': mediaUrlCtrl.text,
                  'targetRegion': targetRegion,
                  'targetProfession': targetProfession,
                  'expiryDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
                  'createdAt': FieldValue.serverTimestamp(),
                  'isActive': true,
                });
                if (mounted) nav.pop();
              },
              child: const Text('نشر الإعلان', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAd(String adId) async {
    await FirebaseFirestore.instance.collection('ads').doc(adId).delete();
  }

  void _showImagePreview(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(16), child: CachedNetworkImage(imageUrl: url)),
            const SizedBox(height: 16),
            CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
