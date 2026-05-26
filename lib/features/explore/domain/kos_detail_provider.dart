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

  // Attempt to build from live API listings.
  final listings = ref.watch(exploreListingsProvider).items;
  try {
    final listing = listings.firstWhere((l) => l.id == kosId);

    // Pull in live rating / reviewCount if already fetched.
    final ratingData = ref.watch(kosRatingProvider(kosId)).valueOrNull;
    final liveRating = ratingData?.$1 ?? listing.rating;
    final liveReviewCount = ratingData?.$2 ?? listing.reviewCount;

    return KosDetail(
      id: listing.id,
      name: listing.name,
      location: listing.location,
      area: listing.area,
      pricePerMonth: listing.pricePerMonth,
      imageUrl: listing.imageUrl,
      rating: liveRating,
      reviewCount: liveReviewCount,
      distanceKm: listing.distanceKm,
      facilities: listing.facilities,
      facilityTags: listing.facilityTags,
      aiSummary: listing.aiSummary,
      positiveHighlights: const [],
      negativeHighlights: const [],
      topikDibahas: listing.facilityTags,
      reviews: const [],
      description: listing.description,
      source: listing.source,
      sourceId: listing.sourceId,
      address: listing.address,
      latitude: listing.latitude,
      longitude: listing.longitude,
      isScraped: listing.isScraped,
      roomFacilities: listing.roomFacilities,
      sharedFacilities: listing.sharedFacilities,
      listingUrl: listing.listingUrl,
      updatedAt: listing.updatedAt,
    );
  } catch (_) {
    return null;
  }
}

/// Fetches the overall_rating and total_reviews for a kos from the reviews API.
/// Returns a tuple (overallRating, totalReviews) or null on failure.
@riverpod
Future<(double, int)?> kosRating(
  KosRatingRef ref,
  String kosId,
) async {
  if (mockKosDetails.containsKey(kosId)) return null;

  final api = ref.read(apiServiceProvider);
  try {
    final detail = ref.read(kosDetailProvider(kosId));
    final fetchId =
        (detail?.sourceId.isNotEmpty == true) ? detail!.sourceId : kosId;
    final response = await api.getKosReviews(fetchId, limit: 1);
    final ratingStr = response['overall_rating'] as String?;
    final totalReviews = (response['total_reviews'] as num?)?.toInt() ?? 0;
    final rating = double.tryParse(ratingStr ?? '') ?? 0.0;
    if (rating == 0.0 && totalReviews == 0) return null;
    return (rating, totalReviews);
  } catch (_) {
    return null;
  }
}

/// Provides the full list of reviews for a given kos.
@riverpod
Future<List<KosReview>> kosReviews(KosReviewsRef ref, String kosId) async {
  if (mockKosDetails.containsKey(kosId)) {
    return mockKosDetails[kosId]?.reviews ?? [];
  }

  final api = ref.read(apiServiceProvider);
  try {
    final detail = ref.read(kosDetailProvider(kosId));
    final fetchId = (detail?.sourceId.isNotEmpty == true) ? detail!.sourceId : kosId;
    final response = await api.getKosReviews(fetchId, limit: 50);
    final reviewsData = response['reviews'] as List<dynamic>? ?? [];
    return reviewsData.map((e) {
      final item = e as Map<String, dynamic>;
      // Parse photo list from API
      final photosRaw = item['photos'] as List<dynamic>? ?? [];
      final photos = photosRaw.map((p) {
        final pm = p as Map<String, dynamic>;
        return ReviewPhoto(
          small: pm['small'] as String? ?? '',
          medium: pm['medium'] as String? ?? '',
          large: pm['large'] as String? ?? '',
        );
      }).toList();
      return KosReview(
        id: 'review-${item.hashCode}',
        userName: item['name'] as String? ?? 'Pengguna',
        userRole: 'Penghuni Kos',
        rating: (item['rating'] as num?)?.toDouble() ?? 5.0,
        timeAgo: item['date'] as String? ?? 'Baru saja',
        content: item['content'] as String? ?? '',
        tags: const [],
        photos: photos,
      );
    }).toList();
  } catch (_) {
    return [];
  }
}

/// Fetches an AI-generated review summary from the backend for a given kos.
/// Uses the review content strings from the local detail data.
/// Returns null when there are no reviews or the API fails.
@riverpod
Future<AIReviewSummaryDto?> kosAiSummary(
  KosAiSummaryRef ref,
  String kosId,
) async {
  List<KosReview> reviewList = [];
  try {
    reviewList = await ref.watch(kosReviewsProvider(kosId).future);
  } catch (_) {}

  if (reviewList.isEmpty) return null;

  final reviews = reviewList.map((r) => r.content).toList();
  try {
    final api = ref.read(apiServiceProvider);
    final raw = await api.getReviewSummary(reviews);
    return AIReviewSummaryDto.fromJson(raw);
  } catch (_) {
    // API unavailable → callers can fall back to local highlights
    return null;
  }
}
