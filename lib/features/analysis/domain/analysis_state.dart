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
enum Q1AddressAnswer { ya, hanyaAlamat, hanyaArea }
enum Q7VideoAnswer { ya, hanyaVideoLama, tidak }
enum Q9PaymentAnswer { jelas, sebagian, tidakDijelaskan, belumTahap }

@freezed
class QuickCheck with _$QuickCheck {
  const factory QuickCheck({
    @Default([]) List<String> uploadedPhotoPaths,
    @Default('') String googleMapsLink,
    @Default('') String namaKontak,
    @Default('') String namaRekening,

    // Q1
    @Default(null) Q1AddressAnswer? addressSpecific,
    // Q2
    @Default(null) TriAnswer? photoMatchLocation,
    // Q3
    @Default(null) TriAnswer? infoConsistent,
    // Q4
    @Default(null) TriAnswer? surveyOrVideoCallAllowed,
    // Q5
    @Default(null) TriAnswer? dpRequestedBeforeSurvey,
    // Q6
    @Default(null) TriAnswer? pressureToTransfer,
    // Q7
    @Default(null) Q7VideoAnswer? willingToProvideVideo,
    // Q8
    @Default(null) TriAnswer? identityConsistent,
    // Q9
    @Default(null) Q9PaymentAnswer? paymentDetailsClear,
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
    @Default(null) String? medianArea,
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

    // ── Communication Analysis (full data) ──
    @Default(0) int communicationRiskScore,
    @Default(0) int pressureLevel,
    @Default(false) bool inconsistenciesFound,
    @Default(false) bool paymentAnomalyDetected,
    @Default(false) bool urgencyDetected,
    @Default(false) bool botTestimonialDetected,
    @Default(false) bool isCrossCheckFail,
    @Default(null) String? crossCheckDetails,
    @Default('') String communicationSummary,

    // ── Visual Analysis (full data) ──
    @Default(false) bool roomInteriorDetected,
    @Default(false) bool watermarkDetected,
    @Default(null) String? watermarkSource,
    @Default(false) bool realisticImages,
    @Default(0) int metadataMatchRisk,
    @Default(null) String? metadataSummary,
    @Default('') String visualSummary,

    // ── Extra metadata ──
    @Default(null) String? recordId,
    @Default('') String status,
  }) = _AnalysisResult;
}

@freezed
class AnalysisState with _$AnalysisState {
  const factory AnalysisState({
    @Default(BasicInfo()) BasicInfo basicInfo,
    @Default(QuickCheck()) QuickCheck quickCheck,
    @Default(DeepCheck()) DeepCheck deepCheck,
    @Default(null) AnalysisResult? result,
    @Default(false) bool isLoading,
    @Default(null) String? errorMessage,
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
  void updateDeepCheck(DeepCheck dc) => state = state.copyWith(deepCheck: dc);

  void addWhatsappChat(String path) => state = state.copyWith(
        deepCheck: state.deepCheck.copyWith(
          whatsappChatPaths: [...state.deepCheck.whatsappChatPaths, path],
        ),
      );

  void removeWhatsappChat(String path) => state = state.copyWith(
        deepCheck: state.deepCheck.copyWith(
          whatsappChatPaths: state.deepCheck.whatsappChatPaths
              .where((p) => p != path)
              .toList(),
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
  void setResult(AnalysisResult result) => state =
      state.copyWith(result: result, isLoading: false, errorMessage: null);

  void reset() => state = const AnalysisState();

  // ── Async state helpers ──
  void setLoading(bool loading) =>
      state = state.copyWith(isLoading: loading, errorMessage: null);

  void setError(String error) =>
      state = state.copyWith(isLoading: false, errorMessage: error);

  void clearError() => state = state.copyWith(errorMessage: null);
}
