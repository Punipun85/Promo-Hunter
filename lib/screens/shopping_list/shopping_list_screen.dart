import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shopping_list_provider.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Daftar Belanja')),
        body: Center(
          child: FilledButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
            child: const Text('Login untuk melihat daftar belanja'),
          ),
        ),
      );
    }

    final provider = context.watch<ShoppingListProvider>();
    if (provider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Daftar Belanja')),
        body: const LoadingWidget(message: 'Sedang memuat daftar belanja...'),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Belanja')),
      body: provider.items.isEmpty
          ? const EmptyState(
              title: 'Belum ada item belanja',
              subtitle: 'Tambahkan promo dari halaman detail promo.',
              icon: Icons.shopping_cart_outlined,
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ...provider.items.map(
                  (item) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(item.storeName),
                                  ],
                                ),
                              ),
                              Checkbox(
                                value: item.isPurchased,
                                onChanged: (_) =>
                                    provider.togglePurchased(item),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              IconButton(
                                onPressed: item.quantity > 1
                                    ? () => provider.updateQuantity(
                                          item.promoId,
                                          item.quantity - 1,
                                        )
                                    : null,
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text('${item.quantity}'),
                              IconButton(
                                onPressed: () => provider.updateQuantity(
                                  item.promoId,
                                  item.quantity + 1,
                                ),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                              const Spacer(),
                              Text(
                                CurrencyFormatter.format(item.totalPrice),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () =>
                                  provider.removeItem(item.promoId),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Hapus'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    title: const Text('Total estimasi belanja'),
                    trailing: Text(
                      CurrencyFormatter.format(provider.totalEstimatedPrice),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
