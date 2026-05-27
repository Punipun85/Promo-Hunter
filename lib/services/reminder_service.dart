import '../models/promo_model.dart';
import '../models/reminder_model.dart';
import 'notification_service.dart';
import 'supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReminderService {
  ReminderService([SupabaseService? supabaseService])
      : _supabaseService = supabaseService ?? const SupabaseService();

  final SupabaseService _supabaseService;
  final Map<String, List<ReminderModel>> _cache = {};

  Future<List<ReminderModel>> getUserReminders(String userId) async {
    final client = _supabaseService.clientOrNull;
    if (client != null) {
      try {
        final response = await client
            .from('reminders')
            .select('promo_id, reminder_time')
            .eq('user_id', userId)
            .order('reminder_time');
        final rows = (response as List).cast<Map<String, dynamic>>();
        final promoIds = rows
            .map((item) => ((item['promo_id'] ?? 0) as num).toInt())
            .where((id) => id > 0)
            .toSet()
            .toList();
        final promoLookup = await _getPromoLookup(client, promoIds);

        final reminders = rows
            .map((data) {
              final promoId = ((data['promo_id'] ?? 0) as num).toInt();
              final promo = promoLookup[promoId];
              return ReminderModel(
                promoId: promoId,
                productName: promo?.productName ?? 'Promo',
                storeName: promo?.storeName ?? '',
                reminderTime:
                    DateTime.tryParse(data['reminder_time']?.toString() ?? '') ??
                        DateTime.now(),
              );
            })
            .toList()
          ..sort((a, b) => a.reminderTime.compareTo(b.reminderTime));
        _cache[userId] = reminders;
        return reminders;
      } catch (_) {
        // Fall back to local cache.
      }
    }
    return _cache[userId] ?? <ReminderModel>[];
  }

  Future<String?> createReminder(
    String userId,
    PromoModel promo,
    DateTime reminderTime,
  ) async {
    if (promo.isExpired || reminderTime.isBefore(DateTime.now())) {
      return 'Reminder tidak bisa dibuat karena promo sudah terlalu dekat atau sudah berakhir.';
    }
    final current = [...(_cache[userId] ?? <ReminderModel>[])];
    if (current.any((item) => item.promoId == promo.id)) {
      return 'Reminder sudah dibuat untuk promo ini.';
    }

    final reminder = ReminderModel(
      promoId: promo.id,
      productName: promo.productName,
      storeName: promo.storeName,
      reminderTime: reminderTime,
    );
    _cache[userId] = [...current, reminder];

    final client = _supabaseService.clientOrNull;
    if (client != null) {
      try {
        await client.from('reminders').upsert({
          'user_id': userId,
          'promo_id': promo.id,
          'reminder_time': reminderTime.toIso8601String(),
        });
      } catch (_) {
        // Keep local fallback.
      }
    }

    await NotificationService.instance.schedulePromoReminder(
      promoId: promo.id,
      title: promo.productName,
      scheduledAt: reminderTime,
    );
    return null;
  }

  Future<void> deleteReminder(String userId, int promoId) async {
    _cache[userId] = [...(_cache[userId] ?? <ReminderModel>[])]
      ..removeWhere((item) => item.promoId == promoId);
    final client = _supabaseService.clientOrNull;
    if (client != null) {
      try {
        await client
            .from('reminders')
            .delete()
            .eq('user_id', userId)
            .eq('promo_id', promoId);
      } catch (_) {
        // Keep local fallback.
      }
    }
    await NotificationService.instance.cancelPromoReminder(promoId);
  }

  Future<Map<int, PromoModel>> _getPromoLookup(
    SupabaseClient client,
    List<int> promoIds,
  ) async {
    if (promoIds.isEmpty) return <int, PromoModel>{};
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
