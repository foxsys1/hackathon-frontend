import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:kos_gdgoc/features/explore/data/mock_kos_detail_data.dart';
import 'package:kos_gdgoc/features/explore/domain/kos_detail.dart';

part 'kos_detail_provider.g.dart';

/// Provides detailed kos data by ID, returns null if not found.
@riverpod
KosDetail? kosDetail(KosDetailRef ref, String kosId) {
  return mockKosDetails[kosId];
}

/// Provides the full list of reviews for a given kos.
@riverpod
List<KosReview> kosReviews(KosReviewsRef ref, String kosId) {
  final detail = mockKosDetails[kosId];
  return detail?.reviews ?? [];
}
