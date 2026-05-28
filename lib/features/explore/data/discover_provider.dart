import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kos_gdgoc/core/network/api_service.dart';
import 'package:kos_gdgoc/features/explore/data/kos_listing_dto.dart';
import 'package:kos_gdgoc/features/explore/domain/kos_listing.dart';
import 'package:kos_gdgoc/features/explore/data/location_provider.dart';
import 'package:geolocator/geolocator.dart';

const _defaultArea = 'UGM Yogyakarta';
const _maxFetchCount = 20;
const _initialRevealCount = 6;
const _batchRevealCount = 6;
const _cacheTtl = Duration(minutes: 5);
const _diskCacheKeyPrefix = 'discover_cache_';
const _diskCacheTsPrefix = 'discover_cache_ts_';

class _DiscoverCacheEntry {
  const _DiscoverCacheEntry(this.items, this.savedAt);

  final List<Map<String, dynamic>> items;
  final DateTime savedAt;

  bool get isFresh => DateTime.now().difference(savedAt) <= _cacheTtl;
}

final Map<String, _DiscoverCacheEntry> _cacheByArea = {};

String _normalizeAreaKey(String area) {
  final lower = area.trim().toLowerCase();
  return lower.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}

String _diskCacheKey(String area) =>
    '$_diskCacheKeyPrefix${_normalizeAreaKey(area)}';

String _diskCacheTsKey(String area) =>
    '$_diskCacheTsPrefix${_normalizeAreaKey(area)}';

Future<_DiscoverCacheEntry?> _readDiskCache(String area) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_diskCacheKey(area));
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! List) return null;

    final items = <Map<String, dynamic>>[];
    for (final item in decoded) {
      if (item is Map) {
        items.add(item.map((key, value) => MapEntry(key.toString(), value)));
      }
    }

    if (items.isEmpty) return null;
    final ts = prefs.getInt(_diskCacheTsKey(area)) ?? 0;
    final savedAt = ts > 0
        ? DateTime.fromMillisecondsSinceEpoch(ts)
        : DateTime.fromMillisecondsSinceEpoch(0);
    return _DiscoverCacheEntry(items, savedAt);
  } catch (_) {
    return null;
  }
}

Future<void> _persistDiskCache(
  String area,
  List<Map<String, dynamic>> items,
) async {
  if (items.isEmpty) return;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_diskCacheKey(area), jsonEncode(items));
    await prefs.setInt(
      _diskCacheTsKey(area),
      DateTime.now().millisecondsSinceEpoch,
    );
  } catch (_) {}
}

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
// Notifier: fetches a buffer of items then reveals them in small batches
// on demand (call loadMore() when the user scrolls near the bottom).
// ─────────────────────────────────────────────────────────────

class ExploreListingsNotifier extends StateNotifier<ExploreListingsState> {
  ExploreListingsNotifier(this._api, this._ref)
      : super(const ExploreListingsState(isLoadingInitial: true)) {
    _ref.listen<AsyncValue<Position?>>(userLocationProvider, (_, next) {
      _handleLocationUpdate(next);
    }, fireImmediately: true);
    _initFetch();
  }

  final ApiService _api;
  final Ref _ref;

  bool _busy = false;
  Position? _pos;
  int _requestId = 0;

  // ── Buffer variables ──
  int _revealedCount = 0;
  List<Map<String, dynamic>> _buffer = [];

  // ── Initial load ──────────────────────────────────────────

  Future<void> _initFetch() async {
    unawaited(_ref.read(userLocationProvider.future));
    await _refreshBuffer(state.currentArea, preferCache: true);
  }

  // ── Fetch full buffer, then reveal the first batch immediately ──

  Future<void> _refreshBuffer(String area, {bool preferCache = false}) async {
    final requestId = ++_requestId;
    final cached = preferCache ? _cacheByArea[area] : null;

    if (cached != null && cached.items.isNotEmpty) {
      _applyBuffer(cached.items);
      if (cached.isFresh) return;
    }

    if (cached == null && preferCache) {
      final disk = await _readDiskCache(area);
      if (requestId != _requestId) return;
      if (disk != null && disk.items.isNotEmpty) {
        _cacheByArea[area] = disk;
        _applyBuffer(disk.items);
        if (disk.isFresh) return;
      }
    }

    if (state.items.isEmpty) {
      state = state.copyWith(isLoadingInitial: true, hasError: false);
    }

    try {
      // Fetch a bulk amount once because the backend doesn't support pagination/offset yet
      final fresh = await _api.discoverListings(area, limit: _maxFetchCount);
      if (requestId != _requestId) return;
      _cacheByArea[area] = _DiscoverCacheEntry(fresh, DateTime.now());
      unawaited(_persistDiskCache(area, fresh));
      _applyBuffer(fresh);
    } catch (_) {
      if (requestId != _requestId) return;
      if (state.items.isEmpty) {
        state = state.copyWith(
          hasError: true,
          isLoadingInitial: false,
          isLoadingMore: false,
        );
      }
    }
  }

  void _applyBuffer(List<Map<String, dynamic>> buffer) {
    _buffer = buffer;
    _revealedCount = 0;

    if (_buffer.isEmpty) {
      state = state.copyWith(
        items: const [],
        hasMore: false,
        isLoadingInitial: false,
        isLoadingMore: false,
        hasError: false,
      );
      return;
    }

    final end = (_initialRevealCount < _buffer.length)
        ? _initialRevealCount
        : _buffer.length;
    final items = _buildListings(0, end);
    _revealedCount = end;
    state = state.copyWith(
      items: items,
      hasMore: _revealedCount < _buffer.length,
      isLoadingInitial: false,
      isLoadingMore: false,
      hasError: false,
    );
  }

  // ── Reveal a batch of items from the buffer ───────────────

  Future<void> _revealBatch(int count) async {
    if (_busy) return;
    if (_revealedCount >= _buffer.length) {
      state = state.copyWith(hasMore: false, isLoadingMore: false);
      return;
    }
    _busy = true;
    try {
      final start = _revealedCount;
      final end = (_revealedCount + count <= _buffer.length)
          ? _revealedCount + count
          : _buffer.length;
      final newItems = _buildListings(start, end);
      _revealedCount = end;

      state = state.copyWith(
        items: [...state.items, ...newItems],
        hasMore: _revealedCount < _buffer.length,
        isLoadingMore: false,
        isLoadingInitial: false,
        hasError: false,
      );
    } catch (_) {
      // Skip malformed items
      _revealedCount++;
    } finally {
      _busy = false;
    }
  }

  List<KosListing> _buildListings(int start, int end) {
    final items = <KosListing>[];
    for (var i = start; i < end; i++) {
      try {
        final raw = _buffer[i];
        final item = KosListingDto.fromJson(raw).toDomain(
          i,
          userLat: _pos?.latitude,
          userLng: _pos?.longitude,
        );
        items.add(item);
      } catch (_) {
        // Skip malformed items
      }
    }
    return items;
  }

  void _handleLocationUpdate(AsyncValue<Position?> next) {
    final newPos = next.valueOrNull;
    final hasUnknownDistance = state.items.any((item) => item.distanceKm < 0);
    final same = _pos != null &&
        newPos != null &&
        _pos!.latitude == newPos.latitude &&
        _pos!.longitude == newPos.longitude;

    if (same && !hasUnknownDistance) return;
    if (newPos == null && _pos == null && !hasUnknownDistance) return;
    _pos = newPos;
    _rebuildVisibleItems();
  }

  void _rebuildVisibleItems() {
    if (_buffer.isEmpty || _revealedCount == 0) return;
    final end =
        (_revealedCount <= _buffer.length) ? _revealedCount : _buffer.length;
    final items = _buildListings(0, end);
    state = state.copyWith(items: items);
  }

  // ── Public API ────────────────────────────────────────────

  /// Call this when the user scrolls near the end of the visible list.
  Future<void> loadMore() async {
    if (_busy || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    await _revealBatch(_batchRevealCount);
  }

  /// Trigger a fresh API fetch for a new [area].
  Future<void> searchArea(String area) async {
    final trimmed = area.trim();
    if (trimmed.isEmpty) return;
    if (trimmed == state.currentArea && state.items.isNotEmpty) return;

    _buffer = [];
    _revealedCount = 0;
    _busy = false;
    final cached = _cacheByArea[trimmed];
    state = ExploreListingsState(
      currentArea: trimmed,
      isLoadingInitial: cached == null,
    );

    await _refreshBuffer(trimmed, preferCache: true);
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
    await _refreshBuffer(state.currentArea, preferCache: false);
  }
}

final exploreListingsProvider =
    StateNotifierProvider<ExploreListingsNotifier, ExploreListingsState>(
  (ref) => ExploreListingsNotifier(ref.read(apiServiceProvider), ref),
);
