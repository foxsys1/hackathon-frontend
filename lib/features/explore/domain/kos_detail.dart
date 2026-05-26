import 'package:freezed_annotation/freezed_annotation.dart';

part 'kos_detail.freezed.dart';

/// Full detail model for a single Kos, extending listing data with
/// AI summary highlights and recent reviews.
@freezed
class KosDetail with _$KosDetail {
  const factory KosDetail({
    required String id,
    required String name,
    required String location,
    required String area,
    required int pricePerMonth,
    required String imageUrl,
    required double rating,
    required int reviewCount,
    required double distanceKm,
    required List<String> facilities,
    required List<String> facilityTags,

    /// Full AI summary paragraph
    required String aiSummary,

    /// Positive highlight bullet points
    required List<String> positiveHighlights,

    /// Negative highlight bullet points
    required List<String> negativeHighlights,

    /// Most discussed topic tags across reviews
    required List<String> topikDibahas,

    /// Recent reviews
    required List<KosReview> reviews,

    /// Full listing description from backend
    @Default('') String description,

    /// Data source, e.g. "Mamikos"
    @Default('') String source,

    /// Street address
    @Default('') String address,

    /// Latitude coordinate
    @Default(null) double? latitude,

    /// Longitude coordinate
    @Default(null) double? longitude,

    /// Whether the listing was scraped
    @Default(false) bool isScraped,

    /// Room-specific facilities
    @Default([]) List<String> roomFacilities,

    /// Shared facilities
    @Default([]) List<String> sharedFacilities,

    /// Source listing URL
    @Default('') String listingUrl,

    /// Last updated from backend
    @Default(null) DateTime? updatedAt,
  }) = _KosDetail;
}

/// A single user review.
@freezed
class KosReview with _$KosReview {
  const factory KosReview({
    required String id,
    required String userName,
    required String userRole,
    required double rating,
    required String timeAgo,
    required String content,

    /// Category tags the reviewer associated with
    required List<String> tags,
  }) = _KosReview;
}
