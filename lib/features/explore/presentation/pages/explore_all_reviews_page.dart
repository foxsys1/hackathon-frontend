import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kos_gdgoc/core/theme/app_theme.dart';
import 'package:kos_gdgoc/features/explore/domain/kos_detail.dart';
import 'package:kos_gdgoc/features/explore/domain/kos_detail_provider.dart';
import 'package:kos_gdgoc/features/explore/presentation/pages/explore_detail_page.dart';

class ExploreAllReviewsPage extends ConsumerStatefulWidget {
  const ExploreAllReviewsPage({super.key, required this.kosId});

  final String kosId;

  @override
  ConsumerState<ExploreAllReviewsPage> createState() =>
      _ExploreAllReviewsPageState();
}

class _ExploreAllReviewsPageState extends ConsumerState<ExploreAllReviewsPage> {
  String _searchQuery = '';
  int? _selectedRating; // null = "Semua"
  String? _selectedCategory; // null = show all

  static const _categoryFilters = [
    'Wifi',
    'Keamanan',
    'Kenyamanan',
    'Lokasi',
    'Kebersihan',
  ];

  @override
  Widget build(BuildContext context) {
    final reviews = ref.watch(kosReviewsProvider(widget.kosId));

    // Apply filters
    var filtered = List<KosReview>.from(reviews);

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((r) {
        return r.userName.toLowerCase().contains(q) ||
            r.content.toLowerCase().contains(q) ||
            r.tags.any((t) => t.toLowerCase().contains(q));
      }).toList();
    }

    // Rating filter
    if (_selectedRating != null) {
      filtered = filtered.where((r) {
        return r.rating >= _selectedRating! && r.rating < _selectedRating! + 1;
      }).toList();
    }

    // Category filter
    if (_selectedCategory != null) {
      filtered = filtered.where((r) {
        return r.tags.contains(_selectedCategory);
      }).toList();
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
                      'Semua Review',
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

            // ── Search bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Cari nama kos, lokasi, atau sumber...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Rating filter chips ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _RatingChip(
                      label: 'Semua',
                      isSelected: _selectedRating == null,
                      onTap: () => setState(() => _selectedRating = null),
                    ),
                    for (int star = 5; star >= 1; star--)
                      _RatingChip(
                        label: '$star',
                        isSelected: _selectedRating == star,
                        showStar: true,
                        onTap: () => setState(() {
                          _selectedRating =
                              _selectedRating == star ? null : star;
                        }),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ── Category filter chips ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categoryFilters.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return _CategoryChip(
                      label: cat,
                      icon: _iconForCategory(cat),
                      isSelected: isSelected,
                      onTap: () => setState(() {
                        _selectedCategory = isSelected ? null : cat;
                      }),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Review list ──
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.rate_review_outlined,
                              size: 48,
                              color: AppColors.textHint.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          const Text(
                            'Tidak ada review ditemukan.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ReviewCard(review: filtered[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForCategory(String cat) {
    switch (cat) {
      case 'Wifi':
        return Icons.wifi;
      case 'Keamanan':
        return Icons.shield_outlined;
      case 'Kenyamanan':
        return Icons.weekend_outlined;
      case 'Lokasi':
        return Icons.location_on_outlined;
      case 'Kebersihan':
        return Icons.cleaning_services_outlined;
      default:
        return Icons.label_outline;
    }
  }
}

// ════════════════════════════════════════════════════════════════════
// Rating Filter Chip
// ════════════════════════════════════════════════════════════════════

class _RatingChip extends StatelessWidget {
  const _RatingChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.showStar = false,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showStar;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (showStar) ...[
              const SizedBox(width: 3),
              Icon(
                Icons.star,
                size: 13,
                color: isSelected ? Colors.white : const Color(0xFFF59E0B),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Category Filter Chip
// ════════════════════════════════════════════════════════════════════

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
