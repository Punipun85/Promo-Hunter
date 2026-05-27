import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../providers/promo_provider.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/promo_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final promoProvider = context.watch<PromoProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('PromoHunter'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: promoProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cari promo apa hari ini?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Pantau diskon, bandingkan harga, dan belanja lebih hemat.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  onChanged: promoProvider.updateSearch,
                  decoration: const InputDecoration(
                    hintText: 'Cari minyak, beras, susu...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: promoProvider.categories.map((category) {
                      return CategoryChip(
                        label: category.name,
                        selected: promoProvider.selectedCategory == category.name,
                        onTap: () => promoProvider.updateCategory(category.name),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Promo Hampir Berakhir',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.promoList),
                      child: const Text('Lihat semua'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...promoProvider.endingSoonPromos.map(
                  (promo) => PromoCard(
                    promo: promo,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.promoDetail,
                      arguments: promo,
                    ),
                    onFavoriteTap: () => promoProvider.toggleFavorite(promo.id),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.favorites),
                      icon: const Icon(Icons.favorite_border),
                      label: const Text('Favorit'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.reminders),
                      icon: const Icon(Icons.notifications_none),
                      label: const Text('Reminder'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.calculator),
                      icon: const Icon(Icons.calculate_outlined),
                      label: const Text('Kalkulator'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.stores),
                      icon: const Icon(Icons.store_mall_directory_outlined),
                      label: const Text('Toko'),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
