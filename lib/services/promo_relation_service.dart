import '../models/promo_model.dart';
import 'supabase_service.dart';

class PromoRelationService {
  PromoRelationService([SupabaseService? supabaseService])
      : _supabaseService = supabaseService ?? const SupabaseService();

  final SupabaseService _supabaseService;

  Future<Map<int, PromoModel>> getPromoLookup(List<int> promoIds) async {
    final client = _supabaseService.clientOrNull;
    if (client == null || promoIds.isEmpty) {
      return <int, PromoModel>{};
    }

    final response = await client
        .from('promos')
        .select('id, product_name, brand, image_url, normal_price, promo_price, '
            'unit_size, unit_type, start_date, end_date, terms, is_active, '
            'stores(name,address), categories(name)')
        .inFilter('id', promoIds);

    final promos = (response as List)
        .map((item) => PromoModel.fromMap(item as Map<String, dynamic>))
        .toList();
    return {for (final promo in promos) promo.id: promo};
  }
}
