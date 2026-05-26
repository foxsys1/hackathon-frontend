import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kos_gdgoc/core/network/api_service.dart';
import 'package:kos_gdgoc/features/explore/data/kos_listing_dto.dart';
import 'package:kos_gdgoc/features/explore/domain/kos_listing.dart';
import 'package:kos_gdgoc/features/explore/data/location_provider.dart';
import 'package:geolocator/geolocator.dart';

const _defaultArea = 'UGM Yogyakarta';
const _maxFetchCount = 20;

// ─────────────────────────────────────────────────────────────
// State model for progressive listings
// ─────────────────────────────────────────────────────────────

class ExploreListingsState {
  const ExploreListingsState({
    this.items = const [],
    this.isLoadingInitial = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.hasError = false,
    this.currentArea = _defaultArea,
  });

  final List<KosListing> items;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final bool hasMore;
  final bool hasError;
  final String currentArea;

  ExploreListingsState copyWith({
    List<KosListing>? items,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    bool? hasMore,
    bool? hasError,
    String? currentArea,
  }) =>
      ExploreListingsState(
        items: items ?? this.items,
        isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        hasError: hasError ?? this.hasError,
        currentArea: currentArea ?? this.currentArea,
      );
}

// ─────────────────────────────────────────────────────────────
// Notifier: fetches a buffer of items then reveals them one-by-one
// on demand (call loadMore() when the user scrolls near the bottom).
// ─────────────────────────────────────────────────────────────

class ExploreListingsNotifier extends StateNotifier<ExploreListingsState> {
  ExploreListingsNotifier(this._api, this._ref)
      : super(const ExploreListingsState(isLoadingInitial: true)) {
    _initFetch();
  }

  final ApiService _api;
  final Ref _ref;

  bool _busy = false;
  Position? _pos;
  
  // ── Buffer variables ──
  int _revealedCount = 0;
  List<Map<String, dynamic>> _buffer = [];

  // ── Initial load ──────────────────────────────────────────

  Future<void> _initFetch() async {
    try {
      _pos = await _ref.read(userLocationProvider.future);
    } catch (_) {
      _pos = null;
    }
    await _refreshBuffer(state.currentArea);
    state = state.copyWith(isLoadingInitial: false);
  }

  // ── Fetch full buffer, then reveal first item immediately ──

  Future<void> _refreshBuffer(String area) async {
    try {
      // Fetch a bulk amount once because the backend doesn't support pagination/offset yet
      _buffer = await _api.discoverListings(area, limit: _maxFetchCount);
      _revealedCount = 0;
      
      if (_buffer.isEmpty) {
        state = state.copyWith(hasMore: false, isLoadingInitial: false);
        return;
      }
      
      // Reveal the first item right away so the screen isn't blank
      await _revealNext();
    } catch (_) {
      state = state.copyWith(hasError: true, isLoadingInitial: false);
    }
  }

  // ── Reveal one item from the buffer ───────────────────────

  Future<void> _revealNext() async {
    if (_busy) return;
    if (_revealedCount >= _buffer.length) {
      state = state.copyWith(hasMore: false);
      return;
    }
    _busy = true;
    try {
      final raw = _buffer[_revealedCount];
      final item = KosListingDto.fromJson(raw).toDomain(
        _revealedCount,
        userLat: _pos?.latitude,
        userLng: _pos?.longitude,
      );
      _revealedCount++;
      state = state.copyWith(
        items: [...state.items, item],
        hasMore: _revealedCount < _buffer.length,
        isLoadingMore: false,
      );
    } catch (_) {
      // Skip malformed items
      _revealedCount++;
    } finally {
      _busy = false;
    }
  }

  // ── Public API ────────────────────────────────────────────

  /// Call this when the user scrolls near the end of the visible list.
  Future<void> loadMore() async {
    if (_busy || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    await _revealNext();
  }

  /// Trigger a fresh API fetch for a new [area].
  Future<void> searchArea(String area) async {
    final trimmed = area.trim();
    if (trimmed.isEmpty) return;
    if (trimmed == state.currentArea && state.items.isNotEmpty) return;

    _buffer = [];
    _revealedCount = 0;
    _busy = false;

    state = ExploreListingsState(
      currentArea: trimmed,
      isLoadingInitial: true,
    );

    await _refreshBuffer(trimmed);
    state = state.copyWith(isLoadingInitial: false);
  }

  /// Refresh the current area from scratch.
  Future<void> refresh() async {
    _buffer = [];
    _revealedCount = 0;
    _busy = false;
    state = ExploreListingsState(
      currentArea: state.currentArea,
      isLoadingInitial: true,
    );
    await _refreshBuffer(state.currentArea);
    state = state.copyWith(isLoadingInitial: false);
  }
}

final exploreListingsProvider =
    StateNotifierProvider<ExploreListingsNotifier, ExploreListingsState>(
  (ref) => ExploreListingsNotifier(ref.read(apiServiceProvider), ref),
);
