import 'package:flutter/material.dart';
import 'auth_provider.dart';

class FavoritesProvider extends ChangeNotifier {
  AuthProvider? _authProvider;

  void update(AuthProvider authProvider) {
    _authProvider = authProvider;
  }

  // Toggle Favorite User
  Future<void> toggleFavoriteUser(String targetUserId) async {
    final user = _authProvider?.user;
    if (user == null) return;

    try {
      final updatedFavorites = List<String>.from(user.favoriteUserIds);
      if (updatedFavorites.contains(targetUserId)) {
        updatedFavorites.remove(targetUserId);
      } else {
        updatedFavorites.add(targetUserId);
      }
      
      await _authProvider!.updateUserProfile({'favoriteUserIds': updatedFavorites});
    } catch (e) {
      debugPrint('Error toggling favorite user: $e');
    }
  }

  // Toggle Favorite Product
  Future<void> toggleFavoriteProduct(String productId) async {
    final user = _authProvider?.user;
    if (user == null) return;

    try {
      final updatedFavorites = List<String>.from(user.favoriteProductIds);
      if (updatedFavorites.contains(productId)) {
        updatedFavorites.remove(productId);
      } else {
        updatedFavorites.add(productId);
      }
      
      await _authProvider!.updateUserProfile({'favoriteProductIds': updatedFavorites});
    } catch (e) {
      debugPrint('Error toggling favorite product: $e');
    }
  }

  // Toggle Favorite Squad
  Future<void> toggleFavoriteSquad(String squadId) async {
    final user = _authProvider?.user;
    if (user == null) return;

    try {
      final updatedFavorites = List<String>.from(user.favoriteSquadIds);
      if (updatedFavorites.contains(squadId)) {
        updatedFavorites.remove(squadId);
      } else {
        updatedFavorites.add(squadId);
      }
      
      await _authProvider!.updateUserProfile({'favoriteSquadIds': updatedFavorites});
    } catch (e) {
      debugPrint('Error toggling favorite squad: $e');
    }
  }
}
