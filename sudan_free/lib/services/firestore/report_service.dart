import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/report_model.dart';
import 'package:intl/intl.dart';

class ReportFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submitReport(ReportModel report) async {
    final limitRef = _firestore.collection('user_reports_limit').doc(report.reporterId);
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await _firestore.runTransaction((tx) async {
      final doc = await tx.get(limitRef);
      int dailyCount = 0;
      String lastDate = '';

      if (doc.exists) {
        dailyCount = doc.data()!['dailyCount'] ?? 0;
        lastDate = doc.data()!['lastReportDate'] ?? '';
      }

      if (lastDate == todayStr) {
        if (dailyCount >= 3) {
          throw Exception('لقد تجاوزت الحد اليومي المسموح للإبلاغات (3 بلاغات). يرجى المحاولة غداً.');
        }
        tx.set(limitRef, {
          'dailyCount': dailyCount + 1,
          'lastReportDate': todayStr,
        }, SetOptions(merge: true));
      } else {
        tx.set(limitRef, {
          'dailyCount': 1,
          'lastReportDate': todayStr,
        }, SetOptions(merge: true));
      }

      final reportRef = _firestore.collection('reports').doc();
      tx.set(reportRef, report.toFirestore());
    });
  }
}
