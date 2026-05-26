import 'package:kos_gdgoc/features/history/domain/history_record.dart';

/// Maps the backend `HistoryListItem` schema to the [HistoryRecord] domain.
class HistoryListItemDto {
  const HistoryListItemDto({
    required this.id,
    required this.listingName,
    required this.areaName,
    required this.price,
    required this.anomalyScore,
    required this.status,
    required this.conclusionSummary,
    this.imageUrl,
    required this.createdAt,
  });

  final String id;
  final String listingName;
  final String areaName;
  final double price;
  final int anomalyScore;
  final String status;
  final String conclusionSummary;
  final String? imageUrl;
  final DateTime createdAt;

  factory HistoryListItemDto.fromJson(Map<String, dynamic> json) {
    return HistoryListItemDto(
      id: json['id'] as String? ?? '',
      listingName: json['listing_name'] as String? ?? '',
      areaName: json['area_name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      anomalyScore: (json['anomaly_score'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? '',
      conclusionSummary: json['conclusion_summary'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  HistoryRecord toDomain() {
    final riskLevel = anomalyScore >= 70
        ? RiskLevel.tinggi
        : anomalyScore >= 40
            ? RiskLevel.sedang
            : RiskLevel.rendah;

    return HistoryRecord(
      id: id,
      namaKos: listingName,
      lokasi: areaName,
      hargaPerBulan:
          price > 0 ? 'Rp ${_formatPrice(price.toInt())} / bulan' : '-',
      sumberListing: '',
      imageUrl: imageUrl ?? '',
      riskScore: anomalyScore,
      riskLevel: riskLevel,
      analysisDate: createdAt,
      confidenceScore: 0,
      confidenceHint: '',
      riskDescription: conclusionSummary,
      redFlags: const [],
      recommendations: const [],
    );
  }

  static String _formatPrice(int price) {
    final str = price.toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return buf.toString();
  }
}
