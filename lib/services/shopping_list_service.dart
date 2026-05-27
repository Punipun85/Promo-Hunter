import '../models/promo_model.dart';
import '../models/shopping_list_model.dart';
import 'promo_relation_service.dart';
import 'supabase_service.dart';

class ShoppingListService {
  ShoppingListService([SupabaseService? supabaseService])
      : _supabaseService = supabaseService ?? const SupabaseService(),
        _promoRelationService = PromoRelationService(
          supabaseService ?? const SupabaseService(),
        );

  final SupabaseService _supabaseService;
  final PromoRelationService _promoRelationService;
  final Map<String, List<ShoppingListModel>> _items = {};

  Future<List<ShoppingListModel>> getItems(String? userId) async {
    if (userId == null) return const <ShoppingListModel>[];
    final client = _supabaseService.clientOrNull;
    if (client != null) {
      try {
        final response = await client
            .from('shopping_lists')
            .select('promo_id, quantity, note, is_purchased')
            .eq('user_id', userId)
            .order('created_at');
        final rows = (response as List).cast<Map<String, dynamic>>();
        final promoIds = rows
            .map((item) => ((item['promo_id'] ?? 0) as num).toInt())
            .where((id) => id > 0)
            .toList();
        final promoLookup = await _promoRelationService.getPromoLookup(promoIds);
        final items = rows.map((data) {
          final promoId = ((data['promo_id'] ?? 0) as num).toInt();
          final promo = promoLookup[promoId];
          return ShoppingListModel(
            promoId: promoId,
            productName: promo?.productName ?? 'Promo',
            storeName: promo?.storeName ?? '',
            price: promo?.promoPrice ?? 0,
            quantity: ((data['quantity'] ?? 1) as num).toInt(),
            note: data['note'] as String? ?? '',
            isPurchased: data['is_purchased'] as bool? ?? false,
          );
        }).toList();
        _items[userId] = items;
        return items;
      } catch (_) {
        // Fall back to local state.
      }
    }
    return List<ShoppingListModel>.from(_items[userId] ?? <ShoppingListModel>[]);
  }

  Future<void> addPromo(String? userId, PromoModel promo, {int quantity = 1}) async {
    if (userId == null) return;
    final current = [...(_items[userId] ?? <ShoppingListModel>[])];
    final index = current.indexWhere((item) => item.promoId == promo.id);
    if (index >= 0) {
      final item = current[index];
      current[index] = item.copyWith(quantity: item.quantity + quantity);
      _items[userId] = current;
      final client = _supabaseService.clientOrNull;
      if (client != null) {
        try {
          await client.from('shopping_lists').upsert({
            'user_id': userId,
            'promo_id': promo.id,
            'quantity': current[index].quantity,
          });
        } catch (_) {}
      }
      return;
    }
    current.add(
      ShoppingListModel(
        promoId: promo.id,
        productName: promo.productName,
        storeName: promo.storeName,
        price: promo.promoPrice,
        quantity: quantity,
      ),
    );
    _items[userId] = current;
    final client = _supabaseService.clientOrNull;
    if (client != null) {
      try {
        await client.from('shopping_lists').upsert({
          'user_id': userId,
          'promo_id': promo.id,
          'quantity': quantity,
          'note': '',
          'is_purchased': false,
        });
      } catch (_) {}
    }
  }

  Future<void> updateItem(
    String? userId,
    int promoId, {
    int? quantity,
    String? note,
    bool? isPurchased,
  }) async {
    if (userId == null) return;
    final current = [...(_items[userId] ?? <ShoppingListModel>[])];
    final index = current.indexWhere((item) => item.promoId == promoId);
    if (index < 0) return;
    current[index] = current[index].copyWith(
      quantity: quantity,
      note: note,
      isPurchased: isPurchased,
    );
    _items[userId] = current;
    final client = _supabaseService.clientOrNull;
    if (client != null) {
      try {
        await client
            .from('shopping_lists')
            .update({
              'quantity': current[index].quantity,
              'note': current[index].note,
              'is_purchased': current[index].isPurchased,
            })
            .eq('user_id', userId)
            .eq('promo_id', promoId);
      } catch (_) {}
    }
  }

  Future<void> removeItem(String? userId, int promoId) async {
    if (userId == null) return;
    final current = [...(_items[userId] ?? <ShoppingListModel>[])]
      ..removeWhere((item) => item.promoId == promoId);
    _items[userId] = current;
    final client = _supabaseService.clientOrNull;
    if (client != null) {
      try {
        await client
            .from('shopping_lists')
            .delete()
            .eq('user_id', userId)
            .eq('promo_id', promoId);
      } catch (_) {}
    }
  }
}
