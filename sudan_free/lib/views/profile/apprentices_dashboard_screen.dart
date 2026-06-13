import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/firestore/user_service.dart';

class ApprenticesDashboardScreen extends StatefulWidget {
  const ApprenticesDashboardScreen({super.key});

  @override
  State<ApprenticesDashboardScreen> createState() => _ApprenticesDashboardScreenState();
}

class _ApprenticesDashboardScreenState extends State<ApprenticesDashboardScreen> {
  final UserFirestoreService _userService = UserFirestoreService();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final locale = context.watch<LocaleProvider>().locale.languageCode;
    final isAr = locale == 'ar';

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(isAr ? 'لوحة تحكم المعلم' : 'Master Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAr ? 'لوحة القيادة' : 'Dashboard', style: const TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            tabs: [
              Tab(text: isAr ? 'فريقي (${user.apprenticesIds.length})' : 'My Team (${user.apprenticesIds.length})'),
              Tab(text: isAr ? 'طلبات الانضمام (${user.pendingApprenticeRequests.length})' : 'Requests (${user.pendingApprenticeRequests.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildApprenticesList(context, user, isAr),
            _buildPendingRequestsList(context, user, isAr),
          ],
        ),
      ),
    );
  }

  Widget _buildApprenticesList(BuildContext context, UserModel user, bool isAr) {
    if (user.apprenticesIds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group_off, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(isAr ? 'لا يوجد لديك صبيان حالياً' : 'You have no apprentices currently', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      );
    }
    
    return FutureBuilder<List<UserModel>>(
      future: FirestoreService().getUsersByIds(user.apprenticesIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return _buildShimmer(Theme.of(context).brightness == Brightness.dark);
        if (snapshot.hasError) return Center(child: Text(isAr ? 'حدث خطأ' : 'Error occurred'));
        
        final apprentices = snapshot.data ?? [];
        if (apprentices.isEmpty) return const SizedBox.shrink();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: apprentices.length,
          itemBuilder: (context, index) {
            final apprentice = apprentices[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: apprentice.profileImageUrl != null ? NetworkImage(apprentice.profileImageUrl!) : null,
                          child: apprentice.profileImageUrl == null ? const Icon(Icons.person) : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(apprentice.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(apprentice.jobTitle ?? (isAr ? 'حرفي' : 'Craftsman'), style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                          child: Text('${apprentice.completedJobs} ${isAr ? 'مهمة' : 'Jobs'}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isAr ? 'قريباً: إسناد مهمة مباشرة!' : 'Coming soon: Assign Task!')));
                            },
                            icon: const Icon(Icons.assignment),
                            label: Text(isAr ? 'إسناد طلب' : 'Assign Task'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(isAr ? 'طرد الصبي' : 'Fire Apprentice'),
                                content: Text(isAr ? 'هل أنت متأكد من إنهاء تدريب ${apprentice.name}؟' : 'Are you sure you want to fire ${apprentice.name}?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isAr ? 'تراجع' : 'Cancel')),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(isAr ? 'طرد' : 'Fire', style: const TextStyle(color: Colors.red))),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await _userService.terminateApprentice(user.id, apprentice.id);
                            }
                          },
                          child: Text(isAr ? 'طرد' : 'Fire'),
                        )
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPendingRequestsList(BuildContext context, UserModel user, bool isAr) {
    if (user.pendingApprenticeRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(isAr ? 'لا توجد طلبات انضمام حالياً' : 'No pending requests currently', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      );
    }

    return FutureBuilder<List<UserModel>>(
      future: FirestoreService().getUsersByIds(user.pendingApprenticeRequests),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return _buildShimmer(Theme.of(context).brightness == Brightness.dark);
        if (snapshot.hasError) return Center(child: Text(isAr ? 'حدث خطأ' : 'Error occurred'));
        
        final requests = snapshot.data ?? [];
        if (requests.isEmpty) return const SizedBox.shrink();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final requester = requests[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundImage: requester.profileImageUrl != null ? NetworkImage(requester.profileImageUrl!) : null,
                  child: requester.profileImageUrl == null ? const Icon(Icons.person) : null,
                ),
                title: Text(requester.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(isAr ? 'يرغب في الانضمام كصبي لك' : 'Wants to join as your apprentice'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green, size: 32),
                      onPressed: () async {
                        await _userService.handleApprenticeshipRequest(user.id, requester.id, true);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red, size: 32),
                      onPressed: () async {
                        await _userService.handleApprenticeshipRequest(user.id, requester.id, false);
                      },
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

  Widget _buildShimmer(bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
        child: Container(
          height: 140,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }
}
