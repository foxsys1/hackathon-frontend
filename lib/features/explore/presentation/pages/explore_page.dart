import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kos_gdgoc/core/theme/app_theme.dart';
import 'package:kos_gdgoc/features/explore/data/discover_provider.dart';
import 'package:kos_gdgoc/features/explore/data/location_provider.dart';
import 'package:kos_gdgoc/features/explore/domain/explore_filter_state.dart';
import 'package:kos_gdgoc/features/explore/presentation/widgets/explore_filter_sheet.dart';
import 'package:kos_gdgoc/features/explore/presentation/widgets/kos_card.dart';

class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage> {
  final _scrollController = ScrollController();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  /// When the user scrolls within 300 px of the bottom, reveal the next item.
  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      ref.read(exploreListingsProvider.notifier).loadMore();
    }
  }

  /// Debounce search: update local text filter immediately, then trigger
  /// an API area-search after 800 ms of silence.
  void _onSearchChanged(String value) {
    // Instant local filter by name / location
    ref
        .read(exploreFilterNotifierProvider.notifier)
        .setSearchQuery(value);

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      if (value.trim().length >= 3) {
        ref.read(exploreListingsProvider.notifier).searchArea(value.trim());
      } else if (value.trim().isEmpty) {
        // Restore default area when search is cleared
        ref.read(exploreListingsProvider.notifier).searchArea('UGM Yogyakarta');
      }
    });
  }

  void _onSearchSubmit(String value) {
    _debounce?.cancel();
    if (value.trim().isNotEmpty) {
      ref.read(exploreListingsProvider.notifier).searchArea(value.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(exploreFilterNotifierProvider);
    final listings = ref.watch(filteredKosListingsProvider);
    final exploreState = ref.watch(exploreListingsProvider);

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
                          exploreState.currentArea,
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

            // ── Error indicator ──
            if (exploreState.hasError)
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
                          'Tidak bisa terhubung ke server. Periksa koneksi internet Anda.',
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
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                onSubmitted: _onSearchSubmit,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Cari lokasi, nama kos, atau area...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchCtrl.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          color: AppColors.textSecondary,
                          tooltip: 'Hapus pencarian',
                          onPressed: () {
                            _searchCtrl.clear();
                            _onSearchChanged('');
                          },
                        ),
                      IconButton(
                        icon: Icon(
                          ref.watch(userLocationProvider).valueOrNull != null
                              ? Icons.location_off
                              : Icons.my_location,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        tooltip: 'Toggle Lokasi',
                        onPressed: () {
                          ref
                              .read(userLocationProvider.notifier)
                              .toggleLocation();
                        },
                      ),
                    ],
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
                          Icon(icon,
                              size: 14,
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
              child: exploreState.isLoadingInitial && listings.isEmpty
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
                            'Mencari kos terbaik...',
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
                                  color:
                                      AppColors.textHint.withOpacity(0.5)),
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
                                'Coba ubah filter atau area pencarian.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          // +1 for the bottom loader
                          itemCount: listings.length +
                              (exploreState.isLoadingMore ||
                                      exploreState.hasMore
                                  ? 1
                                  : 0),
                          itemBuilder: (context, i) {
                            // Bottom loader / "load next" trigger
                            if (i == listings.length) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: exploreState.isLoadingMore
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    AppColors.primary),
                                          ),
                                        )
                                      : TextButton.icon(
                                          onPressed: () => ref
                                              .read(exploreListingsProvider
                                                  .notifier)
                                              .loadMore(),
                                          icon: const Icon(
                                              Icons.expand_more,
                                              size: 18),
                                          label:
                                              const Text('Muat lebih banyak'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppColors.primary,
                                          ),
                                        ),
                                ),
                              );
                            }
                            return KosCard(
                              listing: listings[i],
                              onTap: () => context
                                  .push('/explore/${listings[i].id}'),
                            );
                          },
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
