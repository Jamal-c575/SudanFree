// lib/screens/analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('الإحصائيات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('analytics_events').orderBy('timestamp', descending: true).limit(500).get(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snap.data!.docs;

                // تجميع حسب اليوم
                final byDay = <String, int>{};
                final byEvent = <String, int>{};
                for (final d in docs) {
                  final data = d.data() as Map<String, dynamic>;
                  final ts = (data['timestamp'] as Timestamp?)?.toDate();
                  if (ts == null) continue;
                  final day = DateFormat('yyyy-MM-dd').format(ts);
                  byDay[day] = (byDay[day] ?? 0) + 1;
                  final name = data['eventName'] ?? 'unknown';
                  byEvent[name] = (byEvent[name] ?? 0) + 1;
                }

                final dayEntries = byDay.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
                final chartData = dayEntries.map((e) => _ChartData(e.key, e.value)).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('آخر 500 حدث', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          height: 300,
                          child: SfCartesianChart(
                            primaryXAxis: CategoryAxis(labelRotation: -45),
                            series: <CartesianSeries>[
                              LineSeries<_ChartData, String>(
                                dataSource: chartData,
                                xValueMapper: (d, _) => d.x,
                                yValueMapper: (d, _) => d.y,
                                color: const Color(0xFF10B981),
                                markerSettings: const MarkerSettings(isVisible: true),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('توزيع الأحداث حسب النوع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: byEvent.entries.map((e) {
                        return Chip(
                          avatar: const Icon(Icons.analytics, size: 16),
                          label: Text('${e.key}: ${e.value}'),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    const Text('أحدث 50 حدث', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 12),
                    Card(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length > 50 ? 50 : docs.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final data = docs[i].data() as Map<String, dynamic>;
                          final ts = (data['timestamp'] as Timestamp?)?.toDate();
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.fiber_manual_record, size: 12),
                            title: Text(data['eventName'] ?? ''),
                            subtitle: Text(ts != null ? DateFormat('yyyy-MM-dd HH:mm').format(ts) : ''),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartData {
  final String x;
  final int y;
  _ChartData(this.x, this.y);
}