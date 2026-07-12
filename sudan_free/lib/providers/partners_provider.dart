import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

class PartnersProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  AuthProvider? _authProvider;

  List<UserModel> _partners = [];
  List<UserModel> get partners => _partners;

  DateTime? _lastFetch;
  static const _cacheTtl = Duration(minutes: 5);

  void update(AuthProvider authProvider) {
    _authProvider = authProvider;
  }

  // Toggle Partner (Add/Remove Colleague)
  Future<void> sendPartnerRequest(String targetId) async {
    final user = _authProvider?.user;
    if (user == null) return;

    // Prevent if already partner or already pending
    if (user.partnerIds.contains(targetId) ||
        user.pendingPartnerIds.contains(targetId)) {
      return;
    }

    try {
      await _firestoreService.sendPartnerRequest(
          user.id, user.name, targetId);
      // Wait for stream update instead of optimistic
    } catch (e) {
      debugPrint('Error sending partner request: $e');
    }
  }

  // Handle Partner Request (Accept/Decline)
  Future<void> handlePartnerRequest(String requesterId, bool accept,
      {UserModel? requester}) async {
    final user = _authProvider?.user;
    if (user == null) return;

    try {
      await _firestoreService.handlePartnerRequest(
          user.id, user.name, requesterId, accept);

      final updatedPending = List<String>.from(user.pendingPartnerIds);
      updatedPending.remove(requesterId);

      final updatedPartners = List<String>.from(user.partnerIds);
      if (accept && !updatedPartners.contains(requesterId)) {
        updatedPartners.add(requesterId);
      }

      // Update local auth provider user
      await _authProvider!.updateUserProfile({
        'pendingPartnerIds': updatedPending,
        'partnerIds': updatedPartners,
      });

      if (accept && requester != null) {
        final existing =
            _partners.where((u) => u.id == requester.id).isNotEmpty;
        if (!existing) {
          _partners.add(requester);
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error handling partner request: $e');
      rethrow;
    }
  }

  // Remove Partner (Cancel Request / Remove Colleague)
  Future<void> removePartner(String targetId) async {
    final user = _authProvider?.user;
    if (user == null) return;
    try {
      await _firestoreService.removePartner(user.id, targetId);

      final updatedPartners = List<String>.from(user.partnerIds);
      updatedPartners.remove(targetId);
      
      final updatedPending = List<String>.from(user.pendingPartnerIds);
      updatedPending.remove(targetId);

      await _authProvider!.updateUserProfile({
        'partnerIds': updatedPartners,
        'pendingPartnerIds': updatedPending,
      });

      _partners.removeWhere((p) => p.id == targetId);
      _lastFetch = null; // بطل الكاش عند التعديل
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing partner: $e');
      rethrow;
    }
  }

  // Fetch My Partners & Followed Shops — مع كاش داخلي 5 دقائق
  Future<void> fetchPartners({bool forceRefresh = false}) async {
    final user = _authProvider?.user;
    if (user == null) {
      _partners = [];
      notifyListeners();
      return;
    }

    // الكاش صالح وليس forceRefresh: نرجع البيانات الموجودة فوراً
    if (!forceRefresh &&
        _partners.isNotEmpty &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheTtl) {
      return;
    }

    // نعرض البيانات القديمة فوراً (إن وُجدت) ثم نحدّث في الخلفية
    if (_partners.isNotEmpty && !forceRefresh) {
      notifyListeners(); // عرض فوري للبيانات الموجودة
    }

    // Merge partners and followed shops
    final Set<String> combinedIds = {...user.partnerIds, ...user.following};

    if (combinedIds.isEmpty) {
      _partners = [];
      _lastFetch = DateTime.now();
      notifyListeners();
      return;
    }

    try {
      _partners = await _firestoreService.getUsersByIds(combinedIds.toList());
      _lastFetch = DateTime.now();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching partners/following: $e');
    }
  }
}
