import 'package:kos_gdgoc/features/analysis/domain/analysis_state.dart';

/// Risk level categories based on score ranges.
enum RiskLevel {
  rendah, // 0–39
  sedang, // 40–69
  tinggi, // 70–100
}

/// A single past analysis record displayed in the history list.
class HistoryRecord {
  const HistoryRecord({
    required this.id,
    required this.namaKos,
    required this.lokasi,
    required this.hargaPerBulan,
    required this.sumberListing,
    required this.imageUrl,
    required this.riskScore,
    required this.riskLevel,
    required this.analysisDate,
    required this.confidenceScore,
    required this.confidenceHint,
    required this.redFlags,
    required this.recommendations,
    this.areaComparison,
    this.riskDescription = '',
    this.communicationSummary = '',
    this.visualSummary = '',
    this.communicationRiskScore = 0,
    this.pressureLevel = 0,
    this.inconsistenciesFound = false,
    this.paymentAnomalyDetected = false,
    this.urgencyDetected = false,
    this.botTestimonialDetected = false,
    this.isCrossCheckFail = false,
    this.crossCheckDetails,
    this.roomInteriorDetected = false,
    this.realisticImages = false,
    this.watermarkDetected = false,
    this.watermarkSource,
    this.metadataMatchRisk = 0,
    this.metadataSummary,
  });

  final String id;
  final String namaKos;
  final String lokasi;
  final String hargaPerBulan;
  final String sumberListing;
  final String imageUrl;
  final int riskScore;
  final RiskLevel riskLevel;
  final DateTime analysisDate;
  final double confidenceScore;
  final String confidenceHint;
  final String riskDescription;
  final List<RedFlag> redFlags;
  final List<String> recommendations;
  final AreaComparison? areaComparison;
  
  final String communicationSummary;
  final String visualSummary;
  final int communicationRiskScore;
  final int pressureLevel;
  final bool inconsistenciesFound;
  final bool paymentAnomalyDetected;
  final bool urgencyDetected;
  final bool botTestimonialDetected;
  final bool isCrossCheckFail;
  final String? crossCheckDetails;
  
  final bool roomInteriorDetected;
  final bool realisticImages;
  final bool watermarkDetected;
  final String? watermarkSource;
  final int metadataMatchRisk;
  final String? metadataSummary;

  String get riskLabel {
    switch (riskLevel) {
      case RiskLevel.rendah:
        return 'Risiko Rendah';
      case RiskLevel.sedang:
        return 'Risiko Sedang';
      case RiskLevel.tinggi:
        return 'Risiko Tinggi';
    }
  }
}
