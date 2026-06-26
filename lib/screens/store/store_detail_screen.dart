import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../models/store_model.dart';
import '../../providers/dashboard_experience_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/promo_provider.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/maps_launcher.dart';
import '../../utils/promo_access_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/promo_card.dart';

class StoreDetailScreen extends StatelessWidget {
  const StoreDetailScreen({super.key, required this.store});

  final StoreModel store;

  @override
  Widget build(BuildContext context) {
    final promoProvider = context.watch<PromoProvider>();
    final auth = context.watch<AuthProvider>();
    final experience = context.watch<DashboardExperienceProvider>();
    final favoriteProvider = context.watch<FavoriteProvider>();
    final promos = promoProvider.promosByStore(store.name);
    final bestDiscount =
        promos.isEmpty ? 0.0 : promos.map((promo) => promo.discountPercent).reduce((a, b) => a > b ? a : b);
    final totalPotentialSavings = promos.fold<double>(
      0,
      (total, promo) => total + promo.savingsAmount,
    );

    return Scaffold(
      appBar: AppBar(title: Text(store.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFF0F7FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        Icons.storefront_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            store.address,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            store.city,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF64748B),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoPill(
                      icon: Icons.schedule_rounded,
                      label: store.openingHours,
                    ),
                    if (store.latitude != null && store.longitude != null)
                      _InfoPill(
                        icon: Icons.pin_drop_outlined,
                        label:
                            'Lat ${store.latitude!.toStringAsFixed(5)}, Lng ${store.longitude!.toStringAsFixed(5)}',
                      ),
                    _InfoPill(
                      icon: Icons.local_offer_outlined,
                      label: '${promos.length} promo aktif',
                    ),
                    if (bestDiscount > 0)
                      _InfoPill(
                        icon: Icons.percent_rounded,
                        label: 'Diskon hingga ${bestDiscount.toStringAsFixed(0)}%',
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: 'Potensi hemat',
                        value: promos.isEmpty
                            ? 'Belum ada'
                            : CurrencyFormatter.format(totalPotentialSavings),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        title: 'Promo tersedia',
                        value: '${promos.length}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: promos.isEmpty
                            ? null
                            : () {
                                promoProvider.updateSelectedStore(store.name);
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.promoList,
                                );
                              },
                        icon: const Icon(Icons.local_offer_outlined),
                        label: const Text('Lihat Katalog'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openMaps(context),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Buka Google Maps'),
                      ),
                    ),
                  ],
                ),
                if (store.latitude != null && store.longitude != null) ...[
                  const SizedBox(height: 18),
                  _StoreMapPreview(store: store),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Promo Aktif', style: Theme.of(context).textTheme.titleLarge),
              Text(
                '${promos.length} item',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (promos.isEmpty)
            const EmptyState(
              title: 'Belum ada promo aktif',
              subtitle: 'Promo toko ini akan tampil di sini.',
              icon: Icons.local_offer_outlined,
            )
          else
            ...promos.map(
              (promo) => PromoCard(
                promo: promo.copyWith(
                  isFavorite: favoriteProvider.isFavorite(promo.id),
                ),
                isLocked: experience.isPromoLocked(promo.id),
                lockLabel: experience.promoLockLabel(promo.id),
                onTap: () => openPromoWithAccessGuard(context, promo),
                onFavoriteTap: () {
                  if (!auth.isLoggedIn) {
                    Navigator.pushNamed(context, AppRoutes.login);
                    return;
                  }
                  favoriteProvider.toggleFavorite(auth.currentUser!.id, promo);
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openMaps(BuildContext context) async {
    await MapsLauncher.openStore(context, store);
  }
}

class _StoreMapPreview extends StatelessWidget {
  const _StoreMapPreview({required this.store});

  final StoreModel store;

  @override
  Widget build(BuildContext context) {
    final position = LatLng(store.latitude!, store.longitude!);
    final marker = Marker(
      markerId: MarkerId('store-${store.id}'),
      position: position,
      infoWindow: InfoWindow(
        title: store.name,
        snippet: store.address,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lokasi Toko',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 220,
            child: Stack(
              children: [
                IgnorePointer(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: position,
                      zoom: 15,
                    ),
                    markers: {marker},
                    myLocationButtonEnabled: false,
                    mapToolbarEnabled: false,
                    zoomControlsEnabled: false,
                    rotateGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                    scrollGesturesEnabled: false,
                    zoomGesturesEnabled: false,
                    liteModeEnabled: true,
                  ),
                ),
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: FilledButton.icon(
                    onPressed: () => MapsLauncher.openStore(context, store),
                    icon: const Icon(Icons.navigation_outlined),
                    label: const Text('Buka Google Maps'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF64748B),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}
