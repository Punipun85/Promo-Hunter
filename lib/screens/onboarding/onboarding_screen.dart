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
      icon: Icons.storefront_rounded,
      color: Color(0xFF2170E4),
    ),
    (
      title: 'Simpan dan Diingatkan',
      body: 'Favoritkan promo penting dan dapatkan pengingat sebelum masa berlaku habis.',
      icon: Icons.notifications_active_rounded,
      color: Color(0xFF22C55E),
    ),
    (
      title: 'Bandingkan Harga Satuan',
      body: 'Hitung harga per gram, ml, liter, atau pcs agar belanja makin hemat.',
      icon: Icons.calculate_rounded,
      color: Color(0xFFFACC15),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.home,
                  ),
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
                        Container(
                          width: 190,
                          height: 190,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(48),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x10000000),
                                blurRadius: 32,
                                offset: Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                top: 26,
                                right: 24,
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF4FF),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                              ),
                              Container(
                                width: 106,
                                height: 106,
                                decoration: BoxDecoration(
                                  color: slide.color.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Icon(
                                  slide.icon,
                                  size: 56,
                                  color: slide.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          slide.title,
                          style: Theme.of(context).textTheme.headlineMedium,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _index == index ? 28 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _index == index
                          ? Theme.of(context).colorScheme.primaryContainer
                          : const Color(0xFFDCE9FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
