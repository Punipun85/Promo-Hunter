import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class PromoImage extends StatelessWidget {
  const PromoImage({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.borderRadius = 20,
    this.fit = BoxFit.cover,
  });

  final String imageUrl;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit fit;

  static const fallbackImageUrl =
      'https://images.unsplash.com/photo-1607083206968-13611e3d76db?w=1200';

  @override
  Widget build(BuildContext context) {
    final effectiveUrl = _safeImageUrl(imageUrl);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: effectiveUrl,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 180),
        placeholder: (_, __) => _Placeholder(width: width, height: height),
        errorWidget: (_, __, ___) => _Placeholder(
          width: width,
          height: height,
          icon: Icons.broken_image_outlined,
          label: 'Gambar tidak tersedia',
        ),
      ),
    );
  }

  String _safeImageUrl(String value) {
    final trimmed = value.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        !uri.hasScheme ||
        trimmed.isEmpty ||
        _isPlaceholderHost(uri.host)) {
      return fallbackImageUrl;
    }
    return trimmed;
  }

  bool _isPlaceholderHost(String host) {
    final normalized = host.toLowerCase();
    return normalized == 'example.com' || normalized.endsWith('.example.com');
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.width,
    required this.height,
    this.icon = Icons.image_outlined,
    this.label,
  });

  final double width;
  final double height;
  final IconData icon;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFEFF4FF),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.secondary),
          if (label != null) ...[
            const SizedBox(height: 6),
            Text(
              label!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
