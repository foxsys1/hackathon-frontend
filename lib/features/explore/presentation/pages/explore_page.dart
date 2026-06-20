import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kos_gdgoc/core/theme/app_theme.dart';
import 'package:kos_gdgoc/features/explore/data/discover_provider.dart';
import 'package:kos_gdgoc/features/explore/data/location_provider.dart';
import 'package:kos_gdgoc/features/explore/domain/explore_filter_state.dart';
import 'package:kos_gdgoc/features/explore/domain/kos_listing.dart';
import 'package:kos_gdgoc/features/explore/presentation/widgets/explore_filter_sheet.dart';
import 'package:kos_gdgoc/features/explore/presentation/widgets/interactive_map_selector.dart';
import 'package:kos_gdgoc/core/presentation/widgets/web3_button.dart';
import 'package:kos_gdgoc/features/explore/presentation/widgets/kos_card.dart';

class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage> {
  final _scrollController = ScrollController();
  final _nameSearchCtrl = TextEditingController();
  bool _isAreaSelectorOpen = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _nameSearchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      ref.read(exploreListingsProvider.notifier).loadMore();
    }
  }

  void _onAreaSelectedFromMap(String areaName) {
    setState(() {
      _isAreaSelectorOpen = false;
    });
    ref.read(exploreListingsProvider.notifier).searchArea(areaName);
  }

  void _onNameSearchChanged(String value) {
    ref.read(exploreFilterNotifierProvider.notifier).setSearchQuery(value);
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(exploreFilterNotifierProvider);
    final listings = ref.watch(filteredKosListingsProvider);
    final exploreState = ref.watch(exploreListingsProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeInOutCubic,
        switchOutCurve: Curves.easeInOutCubic,
        transitionBuilder: (child, animation) {
          final isMap = child.key == const ValueKey('mapSelector');
          final slideBegin = isMap
              ? const Offset(0.0, 0.05)
              : const Offset(0.0, -0.05);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: slideBegin,
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        child: _isAreaSelectorOpen
            ? InteractiveMapSelector(
                key: const ValueKey('mapSelector'),
                onAreaSelected: _onAreaSelectedFromMap,
                onBack: () => setState(() => _isAreaSelectorOpen = false),
              )
            : _buildListingsView(context, filter, listings, exploreState),
      ),
    );
  }

  Widget _buildListingsView(
    BuildContext context,
    ExploreFilterState filter,
    List<KosListing> listings,
    ExploreListingsState exploreState,
  ) {
    return SafeArea(
      key: const ValueKey('listingsView'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
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
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Area: ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Text(
                                    exploreState.currentArea,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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

            // ── Name Search bar & Change Area button ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameSearchCtrl,
                      onChanged: _onNameSearchChanged,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Cari Nama Kos...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        suffixIcon: _nameSearchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                color: AppColors.textSecondary,
                                tooltip: 'Hapus pencarian nama',
                                onPressed: () {
                                  _nameSearchCtrl.clear();
                                  _onNameSearchChanged('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.transparent),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Web3Button(
                    onPressed: () => setState(() => _isAreaSelectorOpen = true),
                    color: AppColors.primary,
                    borderRadius: 24,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.map_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Area',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
                  return Web3Button(
                    onPressed: () => ref
                        .read(exploreFilterNotifierProvider.notifier)
                        .setSortBy(metric),
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: 20,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
                              fontWeight: FontWeight.w700,
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

  Widget build(BuildContext context) {
    return Web3Button(
      onPressed: onTap,
      color: hasActiveFilters
          ? AppColors.primary.withOpacity(0.1)
          : Colors.white,
      borderRadius: 12,
      child: SizedBox(
        width: 42,
        height: 42,
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
