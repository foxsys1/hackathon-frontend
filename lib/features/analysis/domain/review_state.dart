import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kos_gdgoc/features/analysis/data/models/validation_result_dto.dart';

/// Stores the list of raw review strings entered by the user in Deep Check.
final reviewTextsProvider =
    StateNotifierProvider<_ReviewTextsNotifier, List<String>>(
  (_) => _ReviewTextsNotifier(),
);

class _ReviewTextsNotifier extends StateNotifier<List<String>> {
  _ReviewTextsNotifier() : super(const []);

  void add(String text) {
    final t = text.trim();
    if (t.isNotEmpty) state = [...state, t];
  }

  void remove(String text) =>
      state = state.where((t) => t != text).toList();

  void clear() => state = const [];
}

/// Stores the AI review summary returned by /api/v1/review-summary.
final reviewSummaryProvider =
    StateNotifierProvider<_ReviewSummaryNotifier, AIReviewSummaryDto?>(
  (_) => _ReviewSummaryNotifier(),
);

class _ReviewSummaryNotifier extends StateNotifier<AIReviewSummaryDto?> {
  _ReviewSummaryNotifier() : super(null);

  void set(AIReviewSummaryDto summary) => state = summary;
  void clear() => state = null;
}
