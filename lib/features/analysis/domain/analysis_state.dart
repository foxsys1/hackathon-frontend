import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'analysis_state.freezed.dart';
part 'analysis_state.g.dart';


@freezed
class BasicInfo with _$BasicInfo {
  const factory BasicInfo({
    @Default('') String namaKos,
    @Default('') String lokasi,
    @Default('') String hargaPerBulan,
    @Default('') String deposit,
    @Default('') String sumberListing,
    @Default('') String deskripsi,
    @Default([]) List<String> fasilitas,
  }) = _BasicInfo;
}


/// Tri-state answer: yes / no / tidakTahu (don't know)
enum TriAnswer { ya, tidak, tidakTahu }

@freezed
class QuickCheck with _$QuickCheck {
  const factory QuickCheck({
    // Foto
    @Default(null) TriAnswer? hasPhotos,
    @Default([]) List<String> uploadedPhotoPaths,

    // Alamat
    @Default(null) TriAnswer? addressSpecific,
    @Default('') String googleMapsLink,

    // Kontak
    @Default(null) TriAnswer? knowsContactName,
    @Default('') String namaKontak,

    // Rekening
    @Default(null) TriAnswer? knowsAccountName,
    @Default('') String namaRekening,

    // Video call
    @Default(null) TriAnswer? videoCallAvailable,

    // Survei
    @Default(null) TriAnswer? surveyAllowed,

    // Tekanan transfer
    @Default(null) TriAnswer? transferPressure,

    // Testimoni
    @Default(null) TriAnswer? hasTestimony,
  }) = _QuickCheck;
}


@freezed
class DeepCheck with _$DeepCheck {
  const factory DeepCheck({
    @Default([]) List<String> whatsappChatPaths,
    @Default([]) List<String> testimoniScreenshotPaths,
  }) = _DeepCheck;
}


@freezed
class RedFlag with _$RedFlag {
  const factory RedFlag({
    required String title,
    required String description,
    required String icon,
  }) = _RedFlag;
}

@freezed
class ChatTemplate with _$ChatTemplate {
  const factory ChatTemplate({
    required int number,
    required String title,
    required String body,
  }) = _ChatTemplate;
}

@freezed
class AreaComparison with _$AreaComparison {
  const factory AreaComparison({
    required String hargaListing,
    required String rataRataArea,
    required String selisih,
    required String selisihLabel,
  }) = _AreaComparison;
}

@freezed
class AnalysisResult with _$AnalysisResult {
  const factory AnalysisResult({
    @Default(0) int riskScore,
    @Default('') String riskLabel,
    @Default('') String riskDescription,
    @Default(0) double confidenceScore,
    @Default('') String confidenceHint,
    @Default([]) List<RedFlag> redFlags,
    @Default([]) List<String> recommendations,
    @Default(null) AreaComparison? areaComparison,
    @Default([]) List<ChatTemplate> chatTemplates,
  }) = _AnalysisResult;
}


@freezed
class AnalysisState with _$AnalysisState {
  const factory AnalysisState({
    @Default(BasicInfo()) BasicInfo basicInfo,
    @Default(QuickCheck()) QuickCheck quickCheck,
    @Default(DeepCheck()) DeepCheck deepCheck,
    @Default(null) AnalysisResult? result,
  }) = _AnalysisState;
}


@Riverpod(keepAlive: true)
class AnalysisStateNotifier extends _$AnalysisStateNotifier {
  @override
  AnalysisState build() => const AnalysisState();

  // ── Basic Info ──
  void updateBasicInfo(BasicInfo info) =>
      state = state.copyWith(basicInfo: info);

  // ── Quick Check ──
  void updateQuickCheck(QuickCheck qc) =>
      state = state.copyWith(quickCheck: qc);

  // ── Deep Check ──
  void updateDeepCheck(DeepCheck dc) =>
      state = state.copyWith(deepCheck: dc);

  void addWhatsappChat(String path) => state = state.copyWith(
        deepCheck: state.deepCheck.copyWith(
          whatsappChatPaths: [...state.deepCheck.whatsappChatPaths, path],
        ),
      );

  void removeWhatsappChat(String path) => state = state.copyWith(
        deepCheck: state.deepCheck.copyWith(
          whatsappChatPaths:
              state.deepCheck.whatsappChatPaths.where((p) => p != path).toList(),
        ),
      );

  void addTestimoniScreenshot(String path) => state = state.copyWith(
        deepCheck: state.deepCheck.copyWith(
          testimoniScreenshotPaths: [
            ...state.deepCheck.testimoniScreenshotPaths,
            path,
          ],
        ),
      );

  void removeTestimoniScreenshot(String path) => state = state.copyWith(
        deepCheck: state.deepCheck.copyWith(
          testimoniScreenshotPaths: state.deepCheck.testimoniScreenshotPaths
              .where((p) => p != path)
              .toList(),
        ),
      );

  // ── Result ──
  void setResult(AnalysisResult result) =>
      state = state.copyWith(result: result);

  void reset() => state = const AnalysisState();
}
