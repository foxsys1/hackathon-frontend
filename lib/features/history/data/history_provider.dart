import 'package:flutter_riverpod/flutter_riverpod.dart';
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
