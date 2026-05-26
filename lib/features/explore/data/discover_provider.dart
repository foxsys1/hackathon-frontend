import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kos_gdgoc/core/network/api_service.dart';
import 'package:kos_gdgoc/features/explore/data/kos_listing_dto.dart';
import 'package:kos_gdgoc/features/explore/data/mock_kos_data.dart';
import 'package:kos_gdgoc/features/explore/domain/kos_listing.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'discover_provider.g.dart';

/// The area to fetch listings from. Defaults to UGM Yogyakarta (cron benchmark area).
const _defaultArea = 'UGM Yogyakarta';

/// Async provider that fetches live listings from the backend /discover endpoint.
/// Falls back to mock data if the API returns an empty list or throws an error.
@riverpod
Future<List<KosListing>> apiKosListings(ApiKosListingsRef ref) async {
  final api = ref.read(apiServiceProvider);
  try {
    final raw = await api.discoverListings(_defaultArea, limit: 20);
    if (raw.isNotEmpty) {
      return raw
          .asMap()
          .entries
          .map((e) => KosListingDto.fromJson(e.value).toDomain(e.key))
          .toList();
    }
  } catch (_) {
    // Network errors → fall through to mock data
  }
  return List<KosListing>.from(mockKosListings);
}
