import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kos_gdgoc/core/theme/app_theme.dart';
import 'package:kos_gdgoc/features/explore/domain/kos_listing.dart';

/// A card widget that displays a single Kos listing in the Explore feed.
///
/// Matches the mockup layout: image | info + distance badge, price, rating,
/// AI summary pill, facility chips, "Lihat Detail" link.
/// CORS proxy base URL – routes image requests through the proxy on Flutter Web
/// to avoid cross-origin errors when loading images from third-party sources.
const _corsProxy = 'https://cors-proxy-two-gules.vercel.app/?url=';

class KosCard extends StatelessWidget {
  const KosCard({super.key, required this.listing, this.onTap});

  final KosListing listing;
  final VoidCallback? onTap;

  String _formatPrice(int price) {
    final str = price.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp${buffer.toString()} / bulan';
  }

  String _formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).round()} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  /// Returns the image URL, routed through the CORS proxy on Flutter Web.
  String _resolveImageUrl(String url) {
    if (url.isEmpty) return url;
    if (kIsWeb) {
      return '$_corsProxy${Uri.encodeComponent(url)}';
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    // Determine how many facility tags to show before collapsing
    const maxVisibleTags = 3;
    final visibleTags = listing.facilityTags.take(maxVisibleTags).toList();
    final overflowCount = listing.facilityTags.length - maxVisibleTags;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: image + info + distance ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: Image.network(
                      _resolveImageUrl(listing.imageUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.chipGray,
                        child: const Center(
                          child: Icon(Icons.home_outlined,
                              color: AppColors.iconDefault, size: 28),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Info column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + distance
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              listing.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Distance badge
                          if (listing.distanceKm >= 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on,
                                    size: 12,
                                    color: AppColors.primary.withOpacity(0.7)),
                                const SizedBox(width: 2),
                                Text(
                                  _formatDistance(listing.distanceKm),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Location
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              listing.location,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Price
                      Text(
                        _formatPrice(listing.pricePerMonth),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Source badge
                      if (listing.source.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            listing.source,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4F46E5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── AI Review Summary pill ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F0FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                        ).createShader(bounds),
                        child: const Icon(Icons.auto_awesome,
                            size: 14, color: Colors.white),
                      ),
                      const SizedBox(width: 6),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                        ).createShader(bounds),
                        child: const Text(
                          'AI Review Summary',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    listing.aiSummary,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Facility chips + Lihat Detail ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Chips
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ...visibleTags.map((tag) => _FacilityChip(label: tag)),
                      if (overflowCount > 0)
                        _FacilityChip(
                          label: '+$overflowCount Lainnya',
                          isOverflow: true,
                        ),
                    ],
                  ),
                ),

                // Lihat Detail
                GestureDetector(
                  onTap: onTap,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lihat Detail',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right,
                          size: 16, color: AppColors.primary),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Facility chip colors ──

const _chipColorMap = <String, ({Color bg, Color text, IconData? icon})>{
  'Lokasi': (
    bg: Color(0xFFD1FAE5),
    text: Color(0xFF065F46),
    icon: Icons.location_on_outlined,
  ),
  'Wifi': (
    bg: Color(0xFFEDE9FE),
    text: Color(0xFF5B21B6),
    icon: Icons.wifi,
  ),
  'Keamanan': (
    bg: Color(0xFFFEF3C7),
    text: Color(0xFF92400E),
    icon: Icons.shield_outlined,
  ),
  'Kenyamanan': (
    bg: Color(0xFFE0F2FE),
    text: Color(0xFF075985),
    icon: Icons.weekend_outlined,
  ),
};

class _FacilityChip extends StatelessWidget {
  const _FacilityChip({
    required this.label,
    this.isOverflow = false,
  });

  final String label;
  final bool isOverflow;

  @override
  Widget build(BuildContext context) {
    if (isOverflow) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.chipGray,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    final colors = _chipColorMap[label];
    final bg = colors?.bg ?? AppColors.chipGray;
    final textColor = colors?.text ?? AppColors.chipGrayText;
    final icon = colors?.icon;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
