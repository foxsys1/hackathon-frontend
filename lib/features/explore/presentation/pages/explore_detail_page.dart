import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kos_gdgoc/core/theme/app_theme.dart';
import 'package:kos_gdgoc/features/explore/domain/kos_detail.dart';
import 'package:kos_gdgoc/features/explore/domain/kos_detail_provider.dart';

class ExploreDetailPage extends ConsumerWidget {
  const ExploreDetailPage({super.key, required this.kosId});

  final String kosId;

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
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(kosDetailProvider(kosId));

    if (detail == null) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        appBar: AppBar(title: const Text('Detail Kos')),
        body: const Center(child: Text('Data tidak ditemukan')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Custom AppBar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Detail Kos',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── Scrollable Content ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // ── Kos Info Header Card ──
                    _KosInfoHeader(
                      detail: detail,
                      formatPrice: _formatPrice,
                      formatDistance: _formatDistance,
                    ),
                    const SizedBox(height: 20),

                    // ── Ringkasan AI Section ──
                    ref.watch(kosAiSummaryProvider(kosId)).when(
                      data: (summary) {
                        return _AiSummarySection(
                          detail: detail,
                          aiSummary: summary?.shortSummary,
                          positives: summary?.positiveHighlights,
                          negatives: summary?.negativeHighlights,
                          isLive: summary != null,
                        );
                      },
                      loading: () => const _AiSummarySectionLoading(),
                      error: (err, stack) => _AiSummarySection(
                        detail: detail,
                        isLive: false,
                        warningMessage: 'Gagal memuat ringkasan live AI. Menampilkan data lokal.',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Topik yang sering dibahas ──
                    _TopikDibahasSection(
                      topics: ref.watch(kosAiSummaryProvider(kosId)).valueOrNull?.topicTags ??
                          detail.topikDibahas,
                    ),
                    const SizedBox(height: 20),

                    // ── Review Terbaru ──
                    _RecentReviewSection(
                      detail: detail,
                      onSeeAll: () => context.push('/explore/$kosId/reviews'),
                    ),
                    const SizedBox(height: 16),

                    // ── Lihat Semua Review Button ──
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            context.push('/explore/$kosId/reviews'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Lihat Semua Review',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Kos Info Header
// ════════════════════════════════════════════════════════════════════

class _KosInfoHeader extends StatelessWidget {
  const _KosInfoHeader({
    required this.detail,
    required this.formatPrice,
    required this.formatDistance,
  });

  final KosDetail detail;
  final String Function(int) formatPrice;
  final String Function(double) formatDistance;

  @override
  Widget build(BuildContext context) {
    const maxVisibleTags = 3;
    final visibleTags = detail.facilityTags.take(maxVisibleTags).toList();
    final overflowCount = detail.facilityTags.length - maxVisibleTags;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image + Info Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Image.network(
                    detail.imageUrl,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + Distance
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            detail.name,
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
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on,
                                size: 12,
                                color: AppColors.primary.withOpacity(0.7)),
                            const SizedBox(width: 2),
                            Text(
                              formatDistance(detail.distanceKm),
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
                            detail.location,
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
                      formatPrice(detail.pricePerMonth),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Rating
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 14, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 3),
                        Text(
                          detail.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${detail.reviewCount} review)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Facility chips
          Wrap(
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
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// AI Summary Section — Ringkasan AI
// ════════════════════════════════════════════════════════════════════

class _AiSummarySection extends StatelessWidget {
  const _AiSummarySection({
    required this.detail,
    this.aiSummary,
    this.positives,
    this.negatives,
    this.isLive = false,
    this.warningMessage,
  });

  final KosDetail detail;
  final String? aiSummary;
  final List<String>? positives;
  final List<String>? negatives;
  final bool isLive;
  final String? warningMessage;

  @override
  Widget build(BuildContext context) {
    final summaryText = aiSummary ?? detail.aiSummary;
    final posHighlights = positives ?? detail.positiveHighlights;
    final negHighlights = negatives ?? detail.negativeHighlights;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                ).createShader(bounds),
                child: const Icon(Icons.auto_awesome,
                    size: 18, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(
                isLive ? 'Ringkasan AI (Live)' : 'Ringkasan AI',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (isLive) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Live',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          if (warningMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFEF3C7)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: Color(0xFFB45309)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      warningMessage!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Summary paragraph
          Text(
            summaryText,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // ── Positive Highlights ──
          if (posHighlights.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFBBF7D0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.thumb_up_outlined,
                          size: 13,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Positive Highlights',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...posHighlights.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.check_circle,
                              size: 15,
                              color: Color(0xFF22C55E),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Negative Highlights ──
          if (negHighlights.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFECACA),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          size: 13,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Negative Highlights',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...negHighlights.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.cancel,
                              size: 15,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AiSummarySectionLoading extends StatelessWidget {
  const _AiSummarySectionLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'AI sedang menyusun ringkasan...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Placeholder lines
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.chipGray.withOpacity(0.5),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: 200,
            decoration: BoxDecoration(
              color: AppColors.chipGray.withOpacity(0.5),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: 150,
            decoration: BoxDecoration(
              color: AppColors.chipGray.withOpacity(0.5),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Topik yang sering dibahas
// ════════════════════════════════════════════════════════════════════

class _TopikDibahasSection extends StatelessWidget {
  const _TopikDibahasSection({required this.topics});
  final List<String> topics;

  @override
  Widget build(BuildContext context) {
    const maxVisible = 3;
    final visible = topics.take(maxVisible).toList();
    final overflow = topics.length - maxVisible;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.chat_bubble_outline,
                  size: 18, color: AppColors.textPrimary),
              SizedBox(width: 8),
              Text(
                'Topik yang sering dibahas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...visible.map((tag) => _FacilityChip(label: tag)),
              if (overflow > 0)
                _FacilityChip(
                  label: '+$overflow Lainnya',
                  isOverflow: true,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Recent Review Section
// ════════════════════════════════════════════════════════════════════

class _RecentReviewSection extends StatelessWidget {
  const _RecentReviewSection({
    required this.detail,
    required this.onSeeAll,
  });

  final KosDetail detail;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    if (detail.reviews.isEmpty) return const SizedBox.shrink();

    final latestReview = detail.reviews.first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          const Row(
            children: [
              Icon(Icons.star_outline, size: 18, color: AppColors.textPrimary),
              SizedBox(width: 8),
              Text(
                'Review Terbaru',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Single review card preview
          ReviewCard(review: latestReview),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Shared Review Card Widget (used in both detail and reviews pages)
// ════════════════════════════════════════════════════════════════════

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review});
  final KosReview review;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info row
          Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.chipGray,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.person_outline,
                    size: 22, color: AppColors.iconDefault),
              ),
              const SizedBox(width: 10),
              // Name + role + time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${review.userRole} · ${review.timeAgo}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Rating badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _ratingBgColor(review.rating),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      review.rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _ratingTextColor(review.rating),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.star,
                      size: 13,
                      color: _ratingStarColor(review.rating),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Review content
          Text(
            review.content,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),

          // Tags
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children:
                review.tags.map((tag) => _FacilityChip(label: tag)).toList(),
          ),
        ],
      ),
    );
  }

  Color _ratingBgColor(double rating) {
    if (rating >= 4.0) return const Color(0xFFF0FDF4);
    if (rating >= 3.0) return const Color(0xFFFEFCE8);
    return const Color(0xFFFEF2F2);
  }

  Color _ratingTextColor(double rating) {
    if (rating >= 4.0) return const Color(0xFF16A34A);
    if (rating >= 3.0) return const Color(0xFFA16207);
    return const Color(0xFFDC2626);
  }

  Color _ratingStarColor(double rating) {
    if (rating >= 4.0) return const Color(0xFF22C55E);
    if (rating >= 3.0) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

// ════════════════════════════════════════════════════════════════════
// Shared Facility Chip
// ════════════════════════════════════════════════════════════════════

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
  'Kebersihan': (
    bg: Color(0xFFFCE7F3),
    text: Color(0xFF9D174D),
    icon: Icons.cleaning_services_outlined,
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
