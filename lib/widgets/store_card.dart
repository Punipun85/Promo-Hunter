import 'package:flutter/material.dart';

import '../models/store_model.dart';
import '../utils/maps_launcher.dart';

class StoreCard extends StatelessWidget {
  const StoreCard({
    super.key,
    required this.store,
    required this.onTap,
    this.compact = false,
    this.distanceKm,
  });

  final StoreModel store;
  final VoidCallback onTap;
  final bool compact;
  final double? distanceKm;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.storefront_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      store.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                store.address,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: compact ? 2 : null,
                overflow: compact ? TextOverflow.ellipsis : null,
              ),
              const SizedBox(height: 4),
              Text(
                '${store.city} - ${store.openingHours}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (distanceKm != null && !distanceKm!.isInfinite) ...[
                const SizedBox(height: 6),
                Text(
                  '${distanceKm!.toStringAsFixed(distanceKm! < 10 ? 1 : 0)} km dari lokasi kamu',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF4FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${store.activePromoCount} promo aktif',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await MapsLauncher.openStore(context, store);
                    },
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Buka Maps'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (!compact) {
      return card;
    }

    return SizedBox(width: 280, child: card);
  }
}
