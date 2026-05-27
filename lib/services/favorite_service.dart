import 'dart:collection';

import 'supabase_service.dart';

class FavoriteService {
  FavoriteService([SupabaseService? supabaseService])
      : _supabaseService = supabaseService ?? const SupabaseService();

  final SupabaseService _supabaseService;
  final Map<String, Set<int>> _cache = {};

  Future<Set<int>> getUserFavorites(String userId) async {
    final client = _supabaseService.clientOrNull;
    if (client != null) {
      try {
        final response =
            await client.from('favorites').select('promo_id').eq('user_id', userId);
        final ids = (response as List)
            .map((item) => ((item as Map<String, dynamic>)['promo_id'] as num).toInt())
            .toSet();
        _cache[userId] = ids;
        return ids;
      } catch (_) {
        // Fall back to local cache.
      }
    }
    return _cache[userId] ?? <int>{};
  }

  Future<bool> checkIsFavorite(String userId, int promoId) async {
    final items = await getUserFavorites(userId);
    return items.contains(promoId);
  }

  Future<void> addFavorite(String userId, int promoId) async {
    final current = HashSet<int>.from(_cache[userId] ?? <int>{})..add(promoId);
    _cache[userId] = current;
    final client = _supabaseService.clientOrNull;
    if (client != null) {
      try {
        await client.from('favorites').upsert({
          'user_id': userId,
          'promo_id': promoId,
        });
      } catch (_) {
        // Keep local state for demo mode/failure fallback.
      }
    }
  }

  Future<void> removeFavorite(String userId, int promoId) async {
    final current = HashSet<int>.from(_cache[userId] ?? <int>{})..remove(promoId);
    _cache[userId] = current;
    final client = _supabaseService.clientOrNull;
    if (client != null) {
      try {
        await client
            .from('favorites')
            .delete()
            .eq('user_id', userId)
            .eq('promo_id', promoId);
      } catch (_) {
        // Keep local state for demo mode/failure fallback.
      }
    }
  }
}

