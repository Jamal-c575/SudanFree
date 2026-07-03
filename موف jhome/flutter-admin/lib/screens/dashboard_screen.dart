// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../services/auth_service.dart';

class DashboardScreen extends ConsumerWidget {
  final Widget child;
  const DashboardScreen({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('J', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w800, fontSize: 22)),
            const Text('home', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18)),
            const SizedBox(width: 16),
            const Text('لوحة التحكم', style: TextStyle(fontSize: 14, color: Colors.white60)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: 'فتح الموقع',
            onPressed: () {
              // افتح الموقع في تبويب جديد
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      drawer: const _SideDrawer(),
      body: child,
    );
  }
}

class _SideDrawer extends ConsumerWidget {
  const _SideDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final items = [
      _DrawerItem('/', Icons.dashboard, 'الرئيسية'),
      _DrawerItem('/posts', Icons.article, 'المقالات'),
      _DrawerItem('/stories', Icons.star, 'قصص النجاح'),
      _DrawerItem('/messages', Icons.message, 'الرسائل'),
      _DrawerItem('/media', Icons.image, 'مكتبة الوسائط'),
      _DrawerItem('/pages', Icons.edit_note, 'محتوى الصفحات'),
      _DrawerItem('/analytics', Icons.bar_chart, 'الإحصائيات'),
    ];

    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Jhome', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
                Text('لوحة تحكم الموقع', style: TextStyle(fontSize: 12, color: Colors.white60)),
              ],
            ),
          ),
          ...items.map((item) {
            final selected = location == item.route;
            return ListTile(
              leading: Icon(item.icon, color: selected ? const Color(0xFF10B981) : null),
              title: Text(item.label),
              selected: selected,
              onTap: () {
                context.go(item.route);
                Navigator.of(context).pop();
              },
            );
          }),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add_circle, color: Color(0xFF10B981)),
            title: const Text('مقال جديد'),
            onTap: () {
              context.go('/posts/new');
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

class _DrawerItem {
  final String route;
  final IconData icon;
  final String label;
  _DrawerItem(this.route, this.icon, this.label);
}

class DashboardHome extends ConsumerWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<HttpsCallableResult<dynamic>>(
      future: FirebaseFunctions.instance.httpsCallable('adminGetDashboardStats').call(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }
        final data = snapshot.data!.data['data'] as Map<String, dynamic>;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('مرحباً بك في لوحة تحكم Jhome 👋',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),
              LayoutBuilder(builder: (context, c) {
                final crossAxisCount = c.maxWidth > 1200 ? 5 : (c.maxWidth > 800 ? 3 : 2);
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.3,
                  children: [
                    _StatCard('المقالات المنشورة', data['totalPosts'], Icons.article, Colors.blue),
                    _StatCard('قصص النجاح', data['totalStories'], Icons.star, Colors.amber),
                    _StatCard('قصص بانتظار الموافقة', data['pendingSubmissions'], Icons.pending_actions, Colors.orange),
                    _StatCard('رسائل جديدة', data['newMessages'], Icons.message, Colors.pink),
                    _StatCard('مشتركو النشرة', data['totalSubscribers'], Icons.email, Colors.green),
                  ],
                );
              }),
              const SizedBox(height: 32),
              const Text('إجراءات سريعة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ActionButton('مقال جديد', Icons.add, () => context.go('/posts/new')),
                  _ActionButton('مراجعة القصص', Icons.star, () => context.go('/stories')),
                  _ActionButton('قراءة الرسائل', Icons.message, () => context.go('/messages')),
                  _ActionButton('مكتبة الوسائط', Icons.image, () => context.go('/media')),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final num value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            Text(value.toString(),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionButton(this.label, this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
    );
  }
}