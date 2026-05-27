import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_routes.dart';
import '../../models/promo_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/promo_provider.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';

class PromoDetailScreen extends StatelessWidget {
  const PromoDetailScreen({super.key, required this.promo});

  final PromoModel promo;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PromoProvider>();
    final auth = context.watch<AuthProvider>();
    final activePromo = provider.promos.firstWhere((item) => item.id == promo.id);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Promo'),
        actions: [
          IconButton(
            onPressed: () {
              if (!auth.isLoggedIn) {
                Navigator.pushNamed(context, AppRoutes.login);
                return;
              }
              provider.toggleFavorite(activePromo.id);
            },
            icon: Icon(
              activePromo.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: activePromo.isFavorite ? Colors.red : null,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: CachedNetworkImage(
              imageUrl: activePromo.imageUrl,
              height: 260,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            activePromo.productName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text('${activePromo.brand} • ${activePromo.categoryName}'),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                CurrencyFormatter.format(activePromo.promoPrice),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(width: 12),
              Text(
                CurrencyFormatter.format(activePromo.normalPrice),
                style: const TextStyle(decoration: TextDecoration.lineThrough),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Diskon ${activePromo.discountPercent.toStringAsFixed(0)}% • ${CurrencyFormatter.format(activePromo.unitPrice)}/${activePromo.unitType}',
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Toko', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(activePromo.storeName),
                  Text(activePromo.storeAddress),
                  const SizedBox(height: 12),
                  Text('Masa berlaku', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    '${DateFormatter.short(activePromo.startDate)} - ${DateFormatter.short(activePromo.endDate)}',
                  ),
                  const SizedBox(height: 12),
                  Text('Syarat & ketentuan', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(activePromo.terms),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: activePromo.isExpired
                ? null
                : () async {
                    if (!auth.isLoggedIn) {
                      Navigator.pushNamed(context, AppRoutes.login);
                      return;
                    }
                    final message = await provider.addReminder(
                      activePromo,
                      const Duration(hours: 3),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          message ?? 'Reminder 3 jam sebelum promo berakhir berhasil dibuat.',
                        ),
                      ),
                    );
                  },
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Ingatkan Saya'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final uri = Uri.parse('https://maps.google.com/?q=${Uri.encodeComponent(activePromo.storeAddress)}');
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.map_outlined),
            label: const Text('Buka Lokasi Toko'),
          ),
        ],
      ),
    );
  }
}
