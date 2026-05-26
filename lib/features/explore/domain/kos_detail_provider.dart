import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:kos_gdgoc/core/network/api_service.dart';
import 'package:kos_gdgoc/features/analysis/data/models/validation_result_dto.dart';
import 'package:kos_gdgoc/features/explore/data/discover_provider.dart';
import 'package:kos_gdgoc/features/explore/data/mock_kos_detail_data.dart';
import 'package:kos_gdgoc/features/explore/domain/kos_detail.dart';

part 'kos_detail_provider.g.dart';

/// Provides detailed kos data by ID, returns null if not found.
/// For IDs from the live /discover API, builds a KosDetail from the listing.
@riverpod
KosDetail? kosDetail(KosDetailRef ref, String kosId) {
  if (mockKosDetails.containsKey(kosId)) {
    return mockKosDetails[kosId];
  }

  // Attempt to build from live API listings (e.g. IDs prefixed with 'api-').
  final listings = ref.watch(apiKosListingsProvider).valueOrNull ?? [];
  try {
    final listing = listings.firstWhere((l) => l.id == kosId);
    return KosDetail(
      id: listing.id,
      name: listing.name,
      location: listing.location,
      area: listing.area,
      pricePerMonth: listing.pricePerMonth,
      imageUrl: listing.imageUrl,
      rating: listing.rating,
      reviewCount: listing.reviewCount,
      distanceKm: listing.distanceKm,
      facilities: listing.facilities,
      facilityTags: listing.facilityTags,
      aiSummary: listing.aiSummary,
      positiveHighlights: const [],
      negativeHighlights: const [],
      topikDibahas: listing.facilityTags,
      reviews: const [],
    );
  } catch (_) {
    return null;
  }
}

/// Provides the full list of reviews for a given kos.
@riverpod
List<KosReview> kosReviews(KosReviewsRef ref, String kosId) {
  final detail = mockKosDetails[kosId];
  return detail?.reviews ?? [];
}

/// Fetches an AI-generated review summary from the backend for a given kos.
/// Uses the review content strings from the local detail data.
/// Returns null when there are no reviews or the API fails.
@riverpod
Future<AIReviewSummaryDto?> kosAiSummary(
  KosAiSummaryRef ref,
  String kosId,
) async {
  final detail = ref.watch(kosDetailProvider(kosId));
  if (detail == null || detail.reviews.isEmpty) return null;

  final reviews = detail.reviews.map((r) => r.content).toList();
  try {
    final api = ref.read(apiServiceProvider);
    final raw = await api.getReviewSummary(reviews);
    return AIReviewSummaryDto.fromJson(raw);
  } catch (_) {
    // API unavailable → callers can fall back to local highlights
    return null;
  }
}
