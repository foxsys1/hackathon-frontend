import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kos_gdgoc/core/network/api_service.dart';
import 'package:kos_gdgoc/features/explore/data/kos_listing_dto.dart';
import 'package:kos_gdgoc/features/explore/domain/kos_listing.dart';
import 'package:kos_gdgoc/features/explore/data/location_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'discover_provider.g.dart';

/// The area to fetch listings from. Defaults to UGM Yogyakarta (cron benchmark area).
const _defaultArea = 'UGM Yogyakarta';

/// Async provider that fetches live listings from the backend /discover endpoint.
/// No mock data fallback — shows real backend data only.
@riverpod
Future<List<KosListing>> apiKosListings(ApiKosListingsRef ref) async {
  final api = ref.read(apiServiceProvider);
  
  // 1. Wait for location prompt to finish FIRST
  Position? pos;
  try {
    pos = await ref.watch(userLocationProvider.future);
  } catch (_) {
    pos = null;
  }

  // 2. Fetch API data ONLY AFTER location prompt is resolved
  final raw = await api.discoverListings(_defaultArea, limit: 20);

  return raw
      .asMap()
      .entries
      .map((e) => KosListingDto.fromJson(e.value).toDomain(
            e.key,
            userLat: pos?.latitude,
            userLng: pos?.longitude,
          ))
      .toList();
}
