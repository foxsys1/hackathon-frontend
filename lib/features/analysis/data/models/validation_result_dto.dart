import 'package:kos_gdgoc/features/analysis/domain/analysis_state.dart';

/// DTO matching the API `DetectedAnomaly` schema.
class DetectedAnomalyDto {
  const DetectedAnomalyDto({
    required this.title,
    required this.description,
    required this.points,
  });

  final String title;
  final String description;
  final int points;

  factory DetectedAnomalyDto.fromJson(Map<String, dynamic> json) {
    return DetectedAnomalyDto(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      points: (json['points'] as num?)?.toInt() ?? 0,
    );
  }

  RedFlag toDomain() => RedFlag(
        title: title,
        description: description,
        icon: _iconForPoints(points),
      );

  static String _iconForPoints(int points) {
    if (points >= 30) return 'warning';
    if (points >= 20) return 'speed';
    return 'info';
  }
}

/// DTO matching the API `PriceComparison` schema.
class PriceComparisonDto {
  const PriceComparisonDto({
    required this.listingPrice,
    this.areaMeanPrice,
    this.areaMedianPrice,
    this.differenceFromMeanPercentage,
  });

  final double listingPrice;
  final double? areaMeanPrice;
  final double? areaMedianPrice;
  final double? differenceFromMeanPercentage;

  factory PriceComparisonDto.fromJson(Map<String, dynamic> json) {
    return PriceComparisonDto(
      listingPrice: (json['listing_price'] as num?)?.toDouble() ?? 0,
      areaMeanPrice: (json['area_mean_price'] as num?)?.toDouble(),
      areaMedianPrice: (json['area_median_price'] as num?)?.toDouble(),
      differenceFromMeanPercentage:
          (json['difference_from_mean_percentage'] as num?)?.toDouble(),
    );
  }

  AreaComparison toDomain() {
    final diff = differenceFromMeanPercentage;
    String selisih = '-';
    String label = '-';
    if (diff != null) {
      final sign = diff >= 0 ? '+' : '';
      final keyword = diff >= 0 ? 'lebih mahal' : 'lebih murah';
      selisih = '$sign${diff.toStringAsFixed(1)}% ($keyword)';
      label = selisih;
    }
    // Build median label
    final medianStr = areaMedianPrice != null
        ? 'Rp ${_formatPrice(areaMedianPrice!)} / bulan'
        : null;
    final meanStr = areaMeanPrice != null
        ? 'Rp ${_formatPrice(areaMeanPrice!)} / bulan'
        : '-';
    return AreaComparison(
      hargaListing: 'Rp ${_formatPrice(listingPrice)} / bulan',
      rataRataArea: meanStr,
      medianArea: medianStr,
      selisih: selisih,
      selisihLabel: label,
    );
  }

  static String _formatPrice(double price) {
    // Simple IDR formatter: 1500000 → "1.500.000"
    final str = price.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return buf.toString();
  }
}

/// DTO matching the API `CommunicationAnalysis` schema.
class CommunicationAnalysisDto {
  const CommunicationAnalysisDto({
    required this.aiRiskScore,
    required this.pressureLevel,
    required this.inconsistenciesFound,
    required this.paymentAnomalyDetected,
    required this.urgencyDetected,
    required this.botTestimonialDetected,
    required this.summary,
    this.isCrossCheckFail = false,
    this.crossCheckDetails,
  });

  final int aiRiskScore;
  final int pressureLevel;
  final bool inconsistenciesFound;
  final bool paymentAnomalyDetected;
  final bool urgencyDetected;
  final bool botTestimonialDetected;
  final bool isCrossCheckFail;
  final String? crossCheckDetails;
  final String summary;

  factory CommunicationAnalysisDto.fromJson(Map<String, dynamic> json) {
    return CommunicationAnalysisDto(
      aiRiskScore: (json['ai_risk_score'] as num?)?.toInt() ?? 0,
      pressureLevel: (json['pressure_level'] as num?)?.toInt() ?? 0,
      inconsistenciesFound: json['inconsistencies_found'] as bool? ?? false,
      paymentAnomalyDetected:
          json['payment_anomaly_detected'] as bool? ?? false,
      urgencyDetected: json['urgency_detected'] as bool? ?? false,
      botTestimonialDetected:
          json['bot_testimonial_detected'] as bool? ?? false,
      isCrossCheckFail: json['is_cross_check_fail'] as bool? ?? false,
      crossCheckDetails: json['cross_check_details'] as String?,
      summary: json['summary'] as String? ?? '',
    );
  }

  /// Converts communication red-flags into [RedFlag] domain objects.
  List<RedFlag> toRedFlags() {
    final flags = <RedFlag>[];
    if (paymentAnomalyDetected) {
      flags.add(const RedFlag(
        title: 'Anomali Pembayaran',
        description: 'Terdeteksi pola tidak wajar pada info pembayaran.',
        icon: 'account_balance',
      ));
    }
    if (urgencyDetected) {
      flags.add(const RedFlag(
        title: 'Tekanan Transfer Cepat',
        description: 'Pemilik mendesak pembayaran/DP segera.',
        icon: 'speed',
      ));
    }
    if (botTestimonialDetected) {
      flags.add(const RedFlag(
        title: 'Testimoni Tidak Valid',
        description:
            'Testimoni terdeteksi tidak autentik atau menggunakan bot.',
        icon: 'report',
      ));
    }
    if (inconsistenciesFound) {
      flags.add(const RedFlag(
        title: 'Inkonsistensi Data',
        description:
            'Ditemukan ketidaksesuaian dalam informasi yang diberikan.',
        icon: 'compare_arrows',
      ));
    }
    return flags;
  }
}

/// DTO matching the API `VisualAnalysis` schema.
class VisualAnalysisDto {
  const VisualAnalysisDto({
    required this.roomInteriorDetected,
    required this.watermarkDetected,
    required this.realisticImages,
    required this.summary,
    this.watermarkSource,
    this.metadataMatchRisk = 0,
    this.metadataSummary,
  });

  final bool roomInteriorDetected;
  final bool watermarkDetected;
  final bool realisticImages;
  final String? watermarkSource;
  final int metadataMatchRisk;
  final String? metadataSummary;
  final String summary;

  factory VisualAnalysisDto.fromJson(Map<String, dynamic> json) {
    return VisualAnalysisDto(
      roomInteriorDetected: json['room_interior_detected'] as bool? ?? false,
      watermarkDetected: json['watermark_detected'] as bool? ?? false,
      realisticImages: json['realistic_images'] as bool? ?? true,
      watermarkSource: json['watermark_source'] as String?,
      metadataMatchRisk: (json['metadata_match_risk'] as num?)?.toInt() ?? 0,
      metadataSummary: json['metadata_summary'] as String?,
      summary: json['summary'] as String? ?? '',
    );
  }

  /// Converts visual red-flags into [RedFlag] domain objects.
  List<RedFlag> toRedFlags() {
    final flags = <RedFlag>[];
    if (watermarkDetected) {
      flags.add(RedFlag(
        title: 'Watermark Terdeteksi',
        description: watermarkSource != null
            ? 'Foto memiliki watermark dari "$watermarkSource" – mungkin bukan foto asli.'
            : 'Foto memiliki watermark dari sumber lain.',
        icon: 'image_not_supported',
      ));
    }
    if (!realisticImages) {
      flags.add(const RedFlag(
        title: 'Foto Tidak Realistis',
        description:
            'Foto terlihat tidak autentik atau kemungkinan hasil editan berlebihan.',
        icon: 'hide_image',
      ));
    }
    if (metadataMatchRisk > 50) {
      flags.add(const RedFlag(
        title: 'Risiko Metadata Foto',
        description: 'Metadata foto menunjukkan indikator risiko.',
        icon: 'photo_camera',
      ));
    }
    return flags;
  }
}

/// DTO matching the top-level API `ValidationResult` schema.
class ValidationResultDto {
  const ValidationResultDto({
    this.recordId,
    required this.anomalyScore,
    required this.confidenceScore,
    required this.status,
    required this.detectedAnomalies,
    required this.recommendedActions,
    required this.priceComparison,
    required this.communicationAnalysis,
    required this.visualAnalysis,
    required this.conclusionSummary,
  });

  final String? recordId;
  final int anomalyScore;
  /// The real confidence score returned by the API (0–100).
  final int confidenceScore;
  final String status;
  final List<DetectedAnomalyDto> detectedAnomalies;
  final List<String> recommendedActions;
  final PriceComparisonDto priceComparison;
  final CommunicationAnalysisDto communicationAnalysis;
  final VisualAnalysisDto visualAnalysis;
  final String conclusionSummary;

  factory ValidationResultDto.fromJson(Map<String, dynamic> json) {
    return ValidationResultDto(
      recordId: json['record_id'] as String?,
      anomalyScore: (json['anomaly_score'] as num?)?.toInt() ?? 0,
      // Use the real API confidence_score — not a derived value.
      confidenceScore: (json['confidence_score'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? '',
      detectedAnomalies: (json['detected_anomalies'] as List<dynamic>? ?? [])
          .map((e) => DetectedAnomalyDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      recommendedActions: (json['recommended_actions'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      priceComparison: PriceComparisonDto.fromJson(
          json['price_comparison'] as Map<String, dynamic>? ?? {}),
      communicationAnalysis: CommunicationAnalysisDto.fromJson(
          json['communication_analysis'] as Map<String, dynamic>? ?? {}),
      visualAnalysis: VisualAnalysisDto.fromJson(
          json['visual_analysis'] as Map<String, dynamic>? ?? {}),
      conclusionSummary: json['conclusion_summary'] as String? ?? '',
    );
  }

  /// Maps this full DTO to the [AnalysisResult] domain model.
  AnalysisResult toDomain() {
    final anomalyFlags = detectedAnomalies.map((a) => a.toDomain()).toList();
    final commFlags = communicationAnalysis.toRedFlags();
    final visualFlags = visualAnalysis.toRedFlags();

    final allFlags = [...anomalyFlags, ...commFlags, ...visualFlags];

    final riskLabel = _labelForScore(anomalyScore);

    // Use the real confidence_score from the API (0–100 → 0.0–1.0).
    final confidence = (confidenceScore / 100.0).clamp(0.0, 1.0);

    return AnalysisResult(
      riskScore: anomalyScore,
      riskLabel: riskLabel,
      riskDescription: conclusionSummary,
      confidenceScore: confidence,
      confidenceHint: _confidenceHint(confidence),
      redFlags: allFlags,
      recommendations: recommendedActions,
      areaComparison: priceComparison.toDomain(),
      chatTemplates: _buildChatTemplates(allFlags),
      // Communication Analysis full data
      communicationRiskScore: communicationAnalysis.aiRiskScore,
      pressureLevel: communicationAnalysis.pressureLevel,
      inconsistenciesFound: communicationAnalysis.inconsistenciesFound,
      paymentAnomalyDetected: communicationAnalysis.paymentAnomalyDetected,
      urgencyDetected: communicationAnalysis.urgencyDetected,
      botTestimonialDetected: communicationAnalysis.botTestimonialDetected,
      isCrossCheckFail: communicationAnalysis.isCrossCheckFail,
      crossCheckDetails: communicationAnalysis.crossCheckDetails,
      communicationSummary: communicationAnalysis.summary,
      // Visual Analysis full data
      roomInteriorDetected: visualAnalysis.roomInteriorDetected,
      watermarkDetected: visualAnalysis.watermarkDetected,
      watermarkSource: visualAnalysis.watermarkSource,
      realisticImages: visualAnalysis.realisticImages,
      metadataMatchRisk: visualAnalysis.metadataMatchRisk,
      metadataSummary: visualAnalysis.metadataSummary,
      visualSummary: visualAnalysis.summary,
      // Metadata
      recordId: recordId,
      status: status,
    );
  }

  static String _labelForScore(int score) {
    if (score >= 70) return 'RISIKO TINGGI';
    if (score >= 40) return 'RISIKO SEDANG';
    return 'RISIKO RENDAH';
  }

  static String _confidenceHint(double confidence) {
    if (confidence >= 0.8) return 'Data lengkap, analisis akurat.';
    if (confidence >= 0.6) return 'Data cukup lengkap untuk analisis.';
    return 'Lengkapi data untuk meningkatkan akurasi analisis.';
  }

  static List<ChatTemplate> _buildChatTemplates(List<RedFlag> flags) {
    final templates = <ChatTemplate>[];
    int number = 1;
    for (final flag in flags.take(3)) {
      templates.add(ChatTemplate(
        number: number++,
        title: 'Soal ${flag.title}',
        body: _chatBodyForFlag(flag),
      ));
    }
    if (templates.isEmpty) {
      templates.add(const ChatTemplate(
        number: 1,
        title: 'Verifikasi Umum',
        body: 'Halo kak, saya tertarik dengan kos yang kak tawarkan. '
            'Sebelum memutuskan, boleh saya minta beberapa info tambahan? '
            'Bisa tolong kirim foto kondisi kamar terbaru, konfirmasi nama pemilik rekening, '
            'dan apakah saya boleh survei langsung ke lokasi? Terima kasih banyak kak 🙏',
      ));
    }
    return templates;
  }

  static String _chatBodyForFlag(RedFlag flag) {
    switch (flag.icon) {
      case 'speed':
        return 'Halo kak, saya ngerti kos ini lagi banyak yang minat. '
            'Tapi saya perlu survei dulu sebelum bisa transfer. '
            'Kalau bisa, boleh kita jadwalin kunjungan ke lokasi minggu ini? '
            'Saya nggak bisa bayar DP sebelum lihat kondisi aslinya. Terima kasih kak 🙏';
      case 'account_balance':
        return 'Halo kak, soal pembayarannya — rekening yang dipakai atas nama siapa ya? '
            'Apakah ada surat perjanjian sewa atau kuitansi resmi yang bisa dikirim? '
            'Saya perlu pastiin dulu sebelum transfer. Semoga kak maklum ya 🙏 Terima kasih!';
      case 'report':
        return 'Halo kak, saya tertarik dengan kosnya. '
            'Boleh minta kontak dari penghuni yang sudah pernah tinggal di sini? '
            'Atau ada testimoni asli yang bisa dibagikan? '
            'Ini penting buat saya sebelum memutuskan. Terima kasih kak 🙏';
      case 'compare_arrows':
        return 'Halo kak, ada beberapa detail yang masih membingungkan saya dari iklannya. '
            'Bisa tolong konfirmasi: fasilitas apa saja yang sudah termasuk, '
            'apakah harga sudah include listrik dan air, dan nama pemilik kos yang bisa dihubungi langsung? '
            'Terima kasih kak 🙏';
      case 'image_not_supported':
      case 'hide_image':
        return 'Halo kak, boleh minta foto atau video terbaru kondisi kamarnya? '
            'Foto di iklan sepertinya bukan dari kos ini langsung. '
            'Kalau bisa video call sebentar untuk lihat kondisi nyatanya, '
            'itu jauh lebih meyakinkan buat saya. Terima kasih kak 🙏';
      case 'photo_camera':
        return 'Halo kak, bisa tolong kirim foto terbaru kamarnya secara langsung? '
            'Saya mau pastiin kondisi kamar sesuai dengan yang di iklan. '
            'Kalau bisa video call juga oke banget! Terima kasih kak 🙏';
      default:
        return 'Halo kak, saya mau nanya soal \'${flag.title.toLowerCase()}\' '
            'yang saya temukan di listing ini.\n\n'
            '${flag.description}\n\n'
            'Boleh dijelasin lebih lanjut supaya saya lebih yakin? '
            'Terima kasih kak 🙏';
    }
  }
}

/// DTO for AI review summary (POST /api/v1/review-summary).
class AIReviewSummaryDto {
  const AIReviewSummaryDto({
    required this.shortSummary,
    required this.positiveHighlights,
    required this.negativeHighlights,
    required this.topicTags,
  });

  final String shortSummary;
  final List<String> positiveHighlights;
  final List<String> negativeHighlights;
  final List<String> topicTags;

  factory AIReviewSummaryDto.fromJson(Map<String, dynamic> json) {
    return AIReviewSummaryDto(
      shortSummary: json['short_summary'] as String? ?? '',
      positiveHighlights: (json['positive_highlights'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      negativeHighlights: (json['negative_highlights'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      topicTags: (json['topic_tags'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
