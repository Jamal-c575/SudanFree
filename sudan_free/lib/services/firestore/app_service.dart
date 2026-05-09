import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/contact_log_model.dart';
import '../../models/notification_model.dart';

class AppFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // App Version Info
  Future<Map<String, dynamic>> getAppVersionInfo() async {
    final doc = await _firestore.collection('app_config').doc('version_info').get();
    return doc.data() ?? {};
  }

  // ==================== CONTACT LOGS ====================
  Future<String> createContactLog(ContactLogModel log) async {
    final existingQuery = await _firestore
        .collection('contactLogs')
        .where('contacterId', isEqualTo: log.contacterId)
        .where('freelancerId', isEqualTo: log.freelancerId)
        .get();

    if (existingQuery.docs.isNotEmpty) {
      final logs = existingQuery.docs.map((doc) => ContactLogModel.fromFirestore(doc)).toList();
      logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final lastLog = logs.first;
      
      final hoursSinceLastContact = DateTime.now().difference(lastLog.createdAt).inHours;
      if (hoursSinceLastContact < 24) return lastLog.id;
    }

    final docRef = _firestore.collection('contactLogs').doc();
    final data = log.toFirestore();
    data['id'] = docRef.id;
    await docRef.set(data);

    try {
      final notifRef = _firestore.collection('notifications').doc();
      final notification = NotificationModel(
        id: notifRef.id,
        userId: log.contacterId,
        type: NotificationType.reviewRequest,
        title: 'كيف كانت تجربتك؟',
        message: 'تواصلت مع ${log.freelancerName}. قيّم تجربتك لمساعدة الآخرين',
        createdAt: Timestamp.now(),
        relatedId: log.freelancerId,
      );
      await notifRef.set(notification.toFirestore());
    } catch (e) { debugPrint('AppService: Review notification error: $e'); }

    return docRef.id;
  }

  Future<ContactLogModel?> getContactLog(String contacterId, String freelancerId) async {
    final query = await _firestore
        .collection('contactLogs')
        .where('contacterId', isEqualTo: contacterId)
        .where('freelancerId', isEqualTo: freelancerId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    
    if (query.docs.isEmpty) return null;
    return ContactLogModel.fromFirestore(query.docs.first);
  }

  Future<bool> hasContactLog(String contacterId, String freelancerId) async {
    final log = await getContactLog(contacterId, freelancerId);
    return log != null;
  }

  Future<void> markContactAsReviewed(String logId) async {
    // ✅ Fix: يجب إرسال reviewedAt مع hasReviewed معاً لتتطابق مع قاعدة Firestore
    await _firestore.collection('contactLogs').doc(logId).update({
      'hasReviewed': true,
      'reviewedAt': Timestamp.now(),
    });
  }
}
