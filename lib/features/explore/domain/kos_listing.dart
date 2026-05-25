import 'package:freezed_annotation/freezed_annotation.dart';

part 'kos_listing.freezed.dart';

/// A single Kos (boarding house) listing displayed in the Explore feed.
@freezed
class KosListing with _$KosListing {
  const factory KosListing({
    required String id,

    /// Display name, e.g. "Kos Putra Senja Ayu"
    required String name,

    /// Full address, e.g. "Pogung Baru, Sleman"
    required String location,

    /// Area slug used for location-based filtering, e.g. "Pogung"
    required String area,

    /// Monthly price in IDR, e.g. 1000000
    required int pricePerMonth,

    /// Network image URL for the listing thumbnail
    required String imageUrl,

    /// Average rating (1.0–5.0)
    required double rating,

    /// Number of reviews
    required int reviewCount,

    /// Distance from the user in km
    required double distanceKm,

    /// AI-generated review summary text
    required String aiSummary,

    /// Full facility list used for filtering, e.g. ["K. Mandi Dalam", "AC", "Wifi"]
    required List<String> facilities,

    /// Display-only category chips shown on the card, e.g. ["Lokasi", "Wifi", "Keamanan"]
    required List<String> facilityTags,

    /// Source URL from the discover API (empty for mock data)
    @Default('') String listingUrl,
  }) = _KosListing;
}
