# KosCheck — Next Steps (Frontend)

## 1. Enrich Listing Display with New Backend Fields

### Problem
`KosListingDto` currently falls back to a static Unsplash placeholder for `imageUrl` and heuristically infers `location` from the URL slug because the backend does not yet return those fields. Once the backend ships the enriched response (see `NEXT_STEPS.md` §1), update the DTO.

### `lib/features/explore/data/kos_listing_dto.dart`
Update `KosListingDto` to parse and forward the new fields:
```dart
final String? imageUrl;
final String? address;
final String? description;
final String? source;

// in fromJson:
imageUrl: json['image_url'] as String?,
address: json['address'] as String?,
description: json['description'] as String?,
source: json['source'] as String? ?? 'Mamikos',

// in toDomain:
imageUrl: imageUrl ?? 'https://images.unsplash.com/photo-1555854877-bab0e564b8d5?w=400',
location: address ?? _extractLocation(listingUrl),
aiSummary: description ?? '',
```

---

## 2. Riwayat Analisis — Connect History to the API

### Current State
- `history_repository_impl.dart` is an empty TODO.
- `history_provider.dart` holds in-memory mock data only.

### 2a. `ApiService` — Add `getHistory`
```dart
// GET /api/v1/history
Future<List<Map<String, dynamic>>> getHistory({int limit = 20}) async {
  final response = await _dio.get<dynamic>(
    '/api/v1/history',
    queryParameters: {'limit': limit},
  );
  final data = response.data;
  if (data is List) return data.whereType<Map<String, dynamic>>().toList();
  return [];
}
```

### 2b. `HistoryRecordDto` (new file)
Create `lib/features/history/data/history_record_dto.dart`:
```dart
import 'package:kos_gdgoc/features/history/domain/history_record.dart';
import 'package:kos_gdgoc/features/analysis/domain/analysis_state.dart';

class HistoryRecordDto {
  final String id;
  final String listingName;
  final String areaName;
  final double price;
  final int anomalyScore;
  final String status;
  final String conclusionSummary;
  final String? imageUrl;
  final DateTime createdAt;

  HistoryRecordDto.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        listingName = json['listing_name'] as String? ?? '',
        areaName = json['area_name'] as String? ?? '',
        price = (json['price'] as num?)?.toDouble() ?? 0,
        anomalyScore = json['anomaly_score'] as int? ?? 0,
        status = json['status'] as String? ?? '',
        conclusionSummary = json['conclusion_summary'] as String? ?? '',
        imageUrl = json['image_url'] as String?,
        createdAt = DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now();

  HistoryRecord toDomain() {
    final score = anomalyScore;
    final level = score >= 70
        ? RiskLevel.tinggi
        : score >= 40
            ? RiskLevel.sedang
            : RiskLevel.rendah;
    return HistoryRecord(
      id: id,
      namaKos: listingName,
      lokasi: areaName,
      hargaPerBulan: 'Rp${price.toStringAsFixed(0)} / bulan',
      sumberListing: 'Mamikos',
      imageUrl: imageUrl ?? 'https://images.unsplash.com/photo-1555854877-bab0e564b8d5?w=400',
      riskScore: score,
      riskLevel: level,
      analysisDate: createdAt,
      confidenceScore: 0.0,
      confidenceHint: '',
      riskDescription: conclusionSummary,
      redFlags: const [],
      recommendations: const [],
    );
  }
}
```

### 2c. Implement `HistoryRepositoryImpl`
Replace the empty TODO in `lib/features/history/data/history_repository_impl.dart`:
```dart
import 'package:kos_gdgoc/core/network/api_service.dart';
import 'package:kos_gdgoc/features/history/data/history_record_dto.dart';
import 'package:kos_gdgoc/features/history/domain/history_record.dart';

class HistoryRepositoryImpl {
  const HistoryRepositoryImpl(this._api);
  final ApiService _api;

  Future<List<HistoryRecord>> fetchHistory({int limit = 20}) async {
    final raw = await _api.getHistory(limit: limit);
    return raw.map((m) => HistoryRecordDto.fromJson(m).toDomain()).toList();
  }
}
```

### 2d. Update `HistoryProvider` to load from API
Replace `history_provider.dart` with a proper `AsyncNotifier`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kos_gdgoc/core/network/api_service.dart';
import 'package:kos_gdgoc/features/history/data/history_repository_impl.dart';
import 'package:kos_gdgoc/features/history/domain/history_record.dart';

final historyRepositoryProvider = Provider<HistoryRepositoryImpl>(
  (ref) => HistoryRepositoryImpl(ref.watch(apiServiceProvider)),
);

class HistoryNotifier extends AsyncNotifier<List<HistoryRecord>> {
  @override
  Future<List<HistoryRecord>> build() =>
      ref.watch(historyRepositoryProvider).fetchHistory();

  void prepend(HistoryRecord record) {
    final prev = state.valueOrNull ?? [];
    state = AsyncData([record, ...prev]);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.watch(historyRepositoryProvider).fetchHistory(),
    );
  }
}

final historyNotifierProvider =
    AsyncNotifierProvider<HistoryNotifier, List<HistoryRecord>>(
  HistoryNotifier.new,
);
```

### 2e. After successful analysis, prepend to history
In the analysis result page (wherever `AnalysisStateNotifier.setResult` is called), also call:
```dart
// Build a HistoryRecord from the returned ValidationResult + basicInfo
ref.read(historyNotifierProvider.notifier).prepend(record);
```

---

## 3. Optional Nice-to-Have Additions

### User-scoped History (Firebase Auth)
Send the Firebase ID token in every authenticated request:
```dart
// In ApiService / Dio interceptor:
final token = await FirebaseAuth.instance.currentUser?.getIdToken();
options.headers['Authorization'] = 'Bearer $token';
```

### History Detail Screen
Once `GET /api/v1/history/{record_id}` is available on the backend, add a detail route that fetches and displays the full `chat_analysis` and `visual_analysis` payload for a selected history item.
