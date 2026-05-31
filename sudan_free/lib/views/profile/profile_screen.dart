import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../models/user_model.dart';
import '../../core/constants/app_colors.dart';

// Import the new separate screens
import 'shop_profile_screen.dart';
import 'freelancer_profile_screen.dart';
import '../auth/profile_setup_screen.dart';
import '../../widgets/common/verification_badge.dart';
import 'favorites_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final authProvider = context.read<AuthProvider>();
    final authUser = authProvider.user;

    // Case 1: Viewing own profile (param userId is null OR matches auth user id)
    if (widget.userId == null || (authUser != null && widget.userId == authUser.id)) {
      setState(() {
        _user = authUser;
        _isLoading = false;
      });
      return;
    }

    // Case 2: Viewing someone else
    setState(() => _isLoading = true);
    try {
      final fetchedUser = await FirestoreService().getUser(widget.userId!);
      if (mounted) {
        setState(() {
          _user = fetchedUser;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Could show error snackbar here
      }
    }
  }

  bool _isUploadingImage = false;

  Future<void> _pickAndUploadImage() async {
    if (_isUploadingImage || _user == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (pickedFile == null || !mounted) return;

    setState(() => _isUploadingImage = true);

    try {
      final file = File(pickedFile.path);
      final url = await StorageService().uploadProfileImage(_user!.id, file);

      if (url != null) {
        await FirestoreService().updateUserProfile(_user!.id, {'profileImageUrl': url});
        
        if (mounted) {
          final auth = context.read<AuthProvider>();
          await auth.refreshUserProfile();
          setState(() {
            _user = auth.user;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل رفع الصورة')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth user updates if we are viewing ourselves
    final authUser = context.watch<AuthProvider>().user;
    if (widget.userId == null || (authUser != null && widget.userId == authUser.id)) {
       // Only update _user if it's already set (to avoid overriding loading state initially)
       if (_user != null) _user = authUser;
    }

    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_user == null) return const Scaffold(body: Center(child: Text("المستخدم غير موجود")));

    final isMe = authUser?.id == _user!.id;

    // Direct to the appropriate screen based on Role
    switch (_user!.role) {
      case UserRole.shop:
        return ShopProfileScreen(user: _user!, isMe: isMe);
      
      case UserRole.freelancer:
      case UserRole.techService:
      case UserRole.privateService:
        return FreelancerProfileScreen(user: _user!, isMe: isMe);
      
      default:
        // Simple profile view for clients (who don't have public profiles usually)
        return _buildClientProfile(context, _user!, isMe);
    }
  }

  Widget _buildClientProfile(BuildContext context, UserModel user, bool isMe) {
    final locale = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(locale == 'ar' ? 'الملف الشخصي' : 'Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                GestureDetector(
                  onTap: isMe && !_isUploadingImage ? _pickAndUploadImage : null,
                  child: CircleAvatar(
                    radius: 65,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: user.profileImageUrl != null ? CachedNetworkImageProvider(user.profileImageUrl!) : null,
                    child: _isUploadingImage 
                        ? const CircularProgressIndicator()
                        : user.profileImageUrl == null
                            ? Text(
                                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary),
                              )
                            : null,
                  ),
                ),
                if (isMe)
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: GestureDetector(
                      onTap: !_isUploadingImage ? _pickAndUploadImage : null,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 3),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                VerificationBadge(isVerified: user.effectivelyVerified, size: 24),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_user, size: 16, color: isDark ? Colors.white60 : Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    locale == 'ar' ? 'حساب عميل' : 'Client Account',
                    style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            
            // Location info if available
            if (user.state != null) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: AppColors.primary.withValues(alpha: 0.7), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${user.state}${user.locality != null ? ' - ${user.locality}' : ''}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
            
            if (isMe) ...[
              const SizedBox(height: 28),
              
              // Favorites Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen())),
                  icon: const Icon(Icons.favorite, color: Colors.white),
                  label: Text(locale == 'ar' ? 'مفضلاتي' : 'My Favorites', style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileSetupScreen(existingUser: user))),
                  icon: const Icon(Icons.edit),
                  label: Text(locale == 'ar' ? 'تعديل الملف / ترقية الحساب' : 'Edit Profile / Upgrade Account'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }


}
