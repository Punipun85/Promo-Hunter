import 'package:flutter/material.dart';

import '../../config/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  static const _slides = [
    (
      title: 'Temukan Promo Terdekat',
      body: 'Lihat promo dari banyak supermarket dan minimarket dalam satu aplikasi.',
      icon: Icons.storefront,
    ),
    (
      title: 'Simpan dan Diingatkan',
      body: 'Favoritkan promo penting dan dapatkan pengingat sebelum masa berlaku habis.',
      icon: Icons.notifications_active,
    ),
    (
      title: 'Bandingkan Harga Satuan',
      body: 'Hitung harga per gram, ml, liter, atau pcs agar belanja makin hemat.',
      icon: Icons.calculate,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
                  child: const Text('Lewati'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (_, index) {
                    final slide = _slides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(slide.icon, size: 100, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 28),
                        Text(
                          slide.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.body,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),
              FilledButton(
                onPressed: () {
                  if (isLast) {
                    Navigator.pushReplacementNamed(context, AppRoutes.home);
                  } else {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: Text(isLast ? 'Mulai' : 'Lanjut'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

