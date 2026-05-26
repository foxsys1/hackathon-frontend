import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:kos_gdgoc/features/explore/data/discover_provider.dart';
import 'package:kos_gdgoc/features/explore/domain/kos_listing.dart';

part 'explore_filter_state.freezed.dart';
part 'explore_filter_state.g.dart';

// ── Sort metric enum ──

enum SortMetric {
  terdekat('Terdekat'),
  hargaRendah('Harga rendah'),
  ratingTinggi('Rating tinggi'),
  banyakReview('Banyak Review');

  const SortMetric(this.label);
  final String label;
}

// ── Filter state ──

@freezed
class ExploreFilterState with _$ExploreFilterState {
  const factory ExploreFilterState({
    @Default('') String searchQuery,
    @Default(300000) int priceMin,
    @Default(2500000) int priceMax,
    @Default([]) List<String> selectedLocations,
    @Default([]) List<String> selectedFacilities,
    @Default(null) double? minimumRating,
    @Default(SortMetric.terdekat) SortMetric sortBy,
  }) = _ExploreFilterState;
}

// ── Riverpod notifier ──

@riverpod
class ExploreFilterNotifier extends _$ExploreFilterNotifier {
  @override
  ExploreFilterState build() => const ExploreFilterState();

  void setSearchQuery(String query) =>
      state = state.copyWith(searchQuery: query);

  void setPriceRange(int min, int max) =>
      state = state.copyWith(priceMin: min, priceMax: max);

  void toggleLocation(String location) {
    final current = List<String>.from(state.selectedLocations);
    if (current.contains(location)) {
      current.remove(location);
    } else {
      current.add(location);
    }
    state = state.copyWith(selectedLocations: current);
  }

  void setLocations(List<String> locations) =>
      state = state.copyWith(selectedLocations: locations);

  void toggleFacility(String facility) {
    final current = List<String>.from(state.selectedFacilities);
    if (current.contains(facility)) {
      current.remove(facility);
    } else {
      current.add(facility);
    }
    state = state.copyWith(selectedFacilities: current);
  }

  void setFacilities(List<String> facilities) =>
      state = state.copyWith(selectedFacilities: facilities);

  void setMinimumRating(double? rating) =>
      state = state.copyWith(minimumRating: rating);

  void setSortBy(SortMetric metric) => state = state.copyWith(sortBy: metric);

  void reset() => state = const ExploreFilterState();
}

// ── Derived filtered list provider ──

@riverpod
List<KosListing> filteredKosListings(FilteredKosListingsRef ref) {
  final filter = ref.watch(exploreFilterNotifierProvider);
  // Use live API data only — no mock fallback.
  final apiAsync = ref.watch(apiKosListingsProvider);
  var listings = List<KosListing>.from(
    apiAsync.valueOrNull ?? <KosListing>[],
  );

  // Search filter
  if (filter.searchQuery.isNotEmpty) {
    final q = filter.searchQuery.toLowerCase();
    listings = listings.where((k) {
      return k.name.toLowerCase().contains(q) ||
          k.location.toLowerCase().contains(q) ||
          k.area.toLowerCase().contains(q);
    }).toList();
  }

  // Price range filter
  listings = listings.where((k) {
    return k.pricePerMonth >= filter.priceMin &&
        k.pricePerMonth <= filter.priceMax;
  }).toList();

  // Location filter
  if (filter.selectedLocations.isNotEmpty) {
    listings = listings.where((k) {
      return filter.selectedLocations.contains(k.area);
    }).toList();
  }

  // Facility filter
  if (filter.selectedFacilities.isNotEmpty) {
    listings = listings.where((k) {
      return filter.selectedFacilities.every((f) => k.facilities.contains(f));
    }).toList();
  }

  // Minimum rating filter
  if (filter.minimumRating != null) {
    listings = listings.where((k) {
      return k.rating >= filter.minimumRating!;
    }).toList();
  }

  // Sorting
  switch (filter.sortBy) {
    case SortMetric.terdekat:
      listings.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    case SortMetric.hargaRendah:
      listings.sort((a, b) => a.pricePerMonth.compareTo(b.pricePerMonth));
    case SortMetric.ratingTinggi:
      listings.sort((a, b) => b.rating.compareTo(a.rating));
    case SortMetric.banyakReview:
      listings.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
  }

  return listings;
}
