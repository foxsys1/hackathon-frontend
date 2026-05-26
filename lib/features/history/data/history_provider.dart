import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kos_gdgoc/core/network/api_service.dart';
import 'package:kos_gdgoc/features/history/data/device_id_service.dart';
import 'package:kos_gdgoc/features/history/data/history_list_item_dto.dart';
import 'package:kos_gdgoc/features/history/domain/history_record.dart';

class HistoryNotifier extends Notifier<List<HistoryRecord>> {
  @override
  List<HistoryRecord> build() => [];

  void addRecord(HistoryRecord record) {
    state = [record, ...state];
  }
}

final historyNotifierProvider =
    NotifierProvider<HistoryNotifier, List<HistoryRecord>>(
  HistoryNotifier.new,
);

/// Fetches the full history list from [GET /api/v1/history].
/// Non-autoDispose so the result is cached; invalidate to force a refresh.
final backendHistoryProvider = FutureProvider<List<HistoryRecord>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final deviceId = getSessionDeviceId();
  final raw = await api.getHistory(deviceId, limit: 50);
  return raw
      .map((json) => HistoryListItemDto.fromJson(json).toDomain())
      .toList();
});
