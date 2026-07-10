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

  static const List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      title: 'Bandingkan Harga Satuan',
      body:
          'Lihat harga per satuan produk agar belanja harian jadi lebih hemat.',
      icon: Icons.shopping_basket_rounded,
      color: Color(0xFF14B8A6),
      background: Color(0xFFE8F7F4),
    ),
    _OnboardingSlide(
      title: 'Jangan Lewatkan Promo',
      body:
          'Simpan promo favorit dan aktifkan pengingat sebelum promo berakhir.',
      icon: Icons.notifications_active_rounded,
      color: Color(0xFFF97316),
      background: Color(0xFFFFF2E8),
    ),
    _OnboardingSlide(
      title: 'Temukan Toko Terdekat',
      body:
          'Cari promo online, jaringan toko, dan cabang terdekat dari lokasi kamu.',
      icon: Icons.storefront_rounded,
      color: Color(0xFF10B981),
      background: Color(0xFFE8F7EE),
      walking: true,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _slides.length - 1;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, index) {
                  return _OnboardingPage(slide: _slides[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _index == index ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: _index == index
                              ? const Color(0xFF10B981)
                              : const Color(0xFFD9E2EC),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (isLast) {
                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.home,
                          );
                          return;
                        }
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                        );
                      },
                      child: Text(isLast ? 'Mulai' : 'Lanjut'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.home,
                    ),
                    child: const Text('Lewati'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 560;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(28, compact ? 28 : 54, 28, 18),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - (compact ? 46 : 72),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StitchStyleIllustration(slide: slide, compact: compact),
                SizedBox(height: compact ? 28 : 42),
                Text(
                  slide.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  slide.body,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF64748B),
                        height: 1.55,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StitchStyleIllustration extends StatefulWidget {
  const _StitchStyleIllustration({
    required this.slide,
    required this.compact,
  });

  final _OnboardingSlide slide;
  final bool compact;

  @override
  State<_StitchStyleIllustration> createState() =>
      _StitchStyleIllustrationState();
}

class _StitchStyleIllustrationState extends State<_StitchStyleIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _float;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _float = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _pulse = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = widget.slide;
    final size = widget.compact ? 178.0 : 220.0;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: slide.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final offset = disableAnimations ? 0.0 : -8.0 * _float.value;
            return Transform.translate(
              offset: Offset(0, offset),
              child: child,
            );
          },
          child: Container(
            width: size * 0.62,
            height: size * 0.62,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 22,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (slide.walking)
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) => _WalkingStoreScene(
                      progress: disableAnimations ? 0.5 : _controller.value,
                      size: size,
                      color: slide.color,
                    ),
                  )
                else ...[
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, child) => Transform.scale(
                      scale: disableAnimations ? 1 : _pulse.value,
                      child: child,
                    ),
                    child: Container(
                      width: size * 0.36,
                      height: size * 0.36,
                      decoration: BoxDecoration(
                        color: slide.color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Icon(
                    slide.icon,
                    color: slide.color,
                    size: size * 0.22,
                  ),
                  Positioned(
                    right: size * 0.15,
                    bottom: size * 0.15,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final shift =
                            disableAnimations ? 0.0 : 5 * _float.value;
                        return Transform.translate(
                          offset: Offset(shift, -shift),
                          child: child,
                        );
                      },
                      child: Container(
                        width: size * 0.12,
                        height: size * 0.12,
                        decoration: BoxDecoration(
                          color: slide.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WalkingStoreScene extends StatelessWidget {
  const _WalkingStoreScene({
    required this.progress,
    required this.size,
    required this.color,
  });

  final double progress;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final walkX = (progress - 0.5) * size * 0.14;
    final swing = (progress - 0.5) * 1.2;
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: size * 0.13,
          child: Container(
            width: size * 0.32,
            height: size * 0.25,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.storefront_rounded,
              color: color,
              size: size * 0.15,
            ),
          ),
        ),
        Positioned(
          bottom: size * 0.16,
          child: Container(
            width: size * 0.44,
            height: 4,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(walkX, size * 0.12),
          child: SizedBox(
            width: size * 0.24,
            height: size * 0.34,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Container(
                  width: size * 0.09,
                  height: size * 0.09,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: color,
                    size: size * 0.07,
                  ),
                ),
                Positioned(
                  top: size * 0.085,
                  child: Container(
                    width: size * 0.085,
                    height: size * 0.12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                _WalkingLimb(
                  top: size * 0.12,
                  left: size * 0.045,
                  height: size * 0.12,
                  color: color,
                  angle: swing,
                ),
                _WalkingLimb(
                  top: size * 0.12,
                  right: size * 0.045,
                  height: size * 0.12,
                  color: color.withValues(alpha: 0.65),
                  angle: -swing,
                ),
                _WalkingLimb(
                  top: size * 0.19,
                  left: size * 0.065,
                  height: size * 0.13,
                  color: color,
                  angle: -swing,
                ),
                _WalkingLimb(
                  top: size * 0.19,
                  right: size * 0.065,
                  height: size * 0.13,
                  color: color.withValues(alpha: 0.65),
                  angle: swing,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WalkingLimb extends StatelessWidget {
  const _WalkingLimb({
    required this.top,
    required this.height,
    required this.color,
    required this.angle,
    this.left,
    this.right,
  });

  final double top;
  final double? left;
  final double? right;
  final double height;
  final Color color;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: Transform.rotate(
        angle: angle,
        alignment: Alignment.topCenter,
        child: Container(
          width: 5,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    required this.background,
    this.walking = false,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final Color background;
  final bool walking;
}
