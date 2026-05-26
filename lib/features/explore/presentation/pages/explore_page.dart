import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kos_gdgoc/core/theme/app_theme.dart';
import 'package:kos_gdgoc/features/explore/data/discover_provider.dart';
import 'package:kos_gdgoc/features/explore/data/location_provider.dart';
import 'package:kos_gdgoc/features/explore/domain/explore_filter_state.dart';
import 'package:kos_gdgoc/features/explore/presentation/widgets/explore_filter_sheet.dart';
import 'package:kos_gdgoc/features/explore/presentation/widgets/kos_card.dart';

class ExplorePage extends ConsumerWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(exploreFilterNotifierProvider);
    final listings = ref.watch(filteredKosListingsProvider);
    final apiAsync = ref.watch(apiKosListingsProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Eksplor Kos',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Temukan kos dan lihat ringkasan kos otomatis.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Filter icon button
                  _FilterIconButton(
                    hasActiveFilters: filter.selectedLocations.isNotEmpty ||
                        filter.selectedFacilities.isNotEmpty ||
                        filter.minimumRating != null ||
                        filter.priceMin != 300000 ||
                        filter.priceMax != 2500000,
                    onTap: () => ExploreFilterSheet.show(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── API error indicator ──
            if (apiAsync.hasError)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off,
                          size: 16, color: Color(0xFF92400E)),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Tidak bisa terhubung ke server. Menampilkan data lokal.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // ── Search bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (v) => ref
                    .read(exploreFilterNotifierProvider.notifier)
                    .setSearchQuery(v),
                decoration: InputDecoration(
                  hintText: 'Cari nama kos, lokasi, atau sumber...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      ref.watch(userLocationProvider).valueOrNull != null 
                        ? Icons.location_off 
                        : Icons.my_location, 
                      color: AppColors.primary
                    ),
                    tooltip: 'Toggle Lokasi',
                    onPressed: () {
                      ref.read(userLocationProvider.notifier).toggleLocation();
                    },
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
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
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Sort chips (horizontal scroll) ──
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: SortMetric.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final metric = SortMetric.values[i];
                  final isSelected = filter.sortBy == metric;
                  IconData icon;
                  switch (metric) {
                    case SortMetric.terdekat:
                      icon = Icons.location_on_outlined;
                    case SortMetric.hargaRendah:
                      icon = Icons.payments_outlined;
                    case SortMetric.ratingTinggi:
                      icon = Icons.star_outline;
                    case SortMetric.banyakReview:
                      icon = Icons.rate_review_outlined;
                  }
                  return GestureDetector(
                    onTap: () => ref
                        .read(exploreFilterNotifierProvider.notifier)
                        .setSortBy(metric),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.textPrimary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 14,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            metric.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // ── Listing cards ──
            Expanded(
              child: apiAsync.isLoading
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Memuat data kos...',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : listings.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off,
                                  size: 48,
                                  color: AppColors.textHint.withOpacity(0.5)),
                              const SizedBox(height: 12),
                              const Text(
                                'Tidak ada kos ditemukan.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Coba ubah filter pencarian.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: listings.length,
                          itemBuilder: (context, i) => KosCard(
                            listing: listings[i],
                            onTap: () =>
                                context.push('/explore/${listings[i].id}'),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Filter icon that shows a purple dot indicator when filters are active.
class _FilterIconButton extends StatelessWidget {
  const _FilterIconButton({
    required this.hasActiveFilters,
    required this.onTap,
  });

  final bool hasActiveFilters;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: hasActiveFilters
              ? AppColors.primary.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasActiveFilters ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.tune,
              size: 20,
              color: hasActiveFilters
                  ? AppColors.primary
                  : AppColors.textPrimary,
            ),
            if (hasActiveFilters)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
