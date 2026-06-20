import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kos_gdgoc/core/network/api_service.dart';
import 'package:kos_gdgoc/core/theme/app_theme.dart';
import 'package:kos_gdgoc/features/analysis/data/models/validation_result_dto.dart';
import 'package:kos_gdgoc/features/analysis/domain/analysis_state.dart';
import 'package:kos_gdgoc/features/history/data/history_provider.dart';
import 'package:kos_gdgoc/features/history/domain/history_record.dart';

class HistoryDetailPage extends ConsumerStatefulWidget {
  const HistoryDetailPage({super.key, required this.id});

  final String id;

  @override
  ConsumerState<HistoryDetailPage> createState() => _HistoryDetailPageState();
}

class _HistoryDetailPageState extends ConsumerState<HistoryDetailPage> {
  HistoryRecord? _record;
  bool _isLoading = false;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    _loadRecord();
  }

  Future<void> _loadRecord() async {
    // Check the in-session store first (fastest path, has richest data).
    final sessionRecord = ref
        .read(historyNotifierProvider)
        .cast<HistoryRecord?>()
        .firstWhere((r) => r!.id == widget.id, orElse: () => null);

    if (sessionRecord != null) {
      _record =
          sessionRecord; // direct assignment is safe in initState sync path
      return;
    }

    // Fall back to GET /api/v1/history/{record_id}.
    setState(() {
      _isLoading = true;
      _notFound = false;
    });
    try {
      final api = ref.read(apiServiceProvider);
      final raw = await api.getHistoryRecord(widget.id);
      if (!mounted) return;
      if (raw != null) {
        setState(() {
          _record = _parseDetailRecord(raw);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _notFound = true;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _notFound = true;
      });
    }
  }

  /// Parses the full saved payload returned by GET /api/v1/history/{id}.
  /// The backend stores { form_data: {...}, result: {...}, created_at: ... }.
  HistoryRecord _parseDetailRecord(Map<String, dynamic> raw) {
    final formData = raw['form_data'] as Map<String, dynamic>? ?? {};
    final resultRaw = raw['result'] as Map<String, dynamic>? ?? raw;
    final dto = ValidationResultDto.fromJson(resultRaw);
    final analysis = dto.toDomain();
    final riskScore = dto.anomalyScore;
    final riskLevel = riskScore >= 70
        ? RiskLevel.tinggi
        : riskScore >= 40
            ? RiskLevel.sedang
            : RiskLevel.rendah;
    final createdAt =
        DateTime.tryParse(raw['created_at'] as String? ?? '') ?? DateTime.now();
    final price = (formData['price'] as num?)?.toDouble() ?? 0;

    return HistoryRecord(
      id: raw['id'] as String? ?? widget.id,
      namaKos: formData['listing_name'] as String? ?? '',
      lokasi: formData['area_name'] as String? ?? '',
      hargaPerBulan: price > 0 ? 'Rp ${_fmtPrice(price.toInt())} / bulan' : '-',
      sumberListing: formData['source'] as String? ?? '',
      imageUrl: formData['image_url'] as String? ??
          'https://images.unsplash.com/photo-1555854877-bab0e564b8d5?w=400&h=300&fit=crop',
      riskScore: riskScore,
      riskLevel: riskLevel,
      analysisDate: createdAt,
      confidenceScore: analysis.confidenceScore,
      confidenceHint: analysis.confidenceHint,
      riskDescription: analysis.riskDescription,
      redFlags: analysis.redFlags,
      recommendations: analysis.recommendations,
      areaComparison: analysis.areaComparison,
      communicationSummary: analysis.communicationSummary,
      visualSummary: analysis.visualSummary,
      communicationRiskScore: analysis.communicationRiskScore,
      pressureLevel: analysis.pressureLevel,
      inconsistenciesFound: analysis.inconsistenciesFound,
      paymentAnomalyDetected: analysis.paymentAnomalyDetected,
      urgencyDetected: analysis.urgencyDetected,
      botTestimonialDetected: analysis.botTestimonialDetected,
      isCrossCheckFail: analysis.isCrossCheckFail,
      crossCheckDetails: analysis.crossCheckDetails,
      roomInteriorDetected: analysis.roomInteriorDetected,
      realisticImages: analysis.realisticImages,
      watermarkDetected: analysis.watermarkDetected,
      watermarkSource: analysis.watermarkSource,
      metadataMatchRisk: analysis.metadataMatchRisk,
      metadataSummary: analysis.metadataSummary,
    );
  }

  static String _fmtPrice(int price) {
    final str = price.toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return buf.toString();
  }

  void _showChatTemplateSheet(BuildContext context, HistoryRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HistoryChatTemplateSheet(record: record),
    );
  }

  void _shareResult(BuildContext context, HistoryRecord record) {
    final flags = record.redFlags.map((f) => '• ${f.title}').join('\n');
    final recs = record.recommendations.map((r) => '• $r').join('\n');
    final shareText = '=== Hasil KosCheck ===\n'
        'Kos: ${record.namaKos}\n'
        'Lokasi: ${record.lokasi}\n'
        'Harga: ${record.hargaPerBulan}\n'
        'Risk Score: ${record.riskScore}/100 (${record.riskLabel})\n\n'
        'Red Flag yang ditemukan:\n${flags.isNotEmpty ? flags : "Tidak ada"}\n\n'
        'Rekomendasi:\n${recs.isNotEmpty ? recs : "Tidak ada"}\n\n'
        '--- Dibuat dengan KosCheck App ---';
    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ringkasan hasil analisis disalin ke clipboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        appBar: AppBar(title: const Text('Detail Hasil')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_notFound || _record == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Hasil')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.history_outlined,
                  size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              const Text(
                'Data tidak ditemukan',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _loadRecord,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final record = _record!;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // Custom AppBar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Detail Hasil',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 360;
                  final hPad = isNarrow ? 14.0 : 20.0;

                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // Kos Info Header
                        _KosInfoHeader(record: record, isNarrow: isNarrow),
                        const SizedBox(height: 20),

                        // Risk Score Card
                        _RiskScoreCard(record: record, isNarrow: isNarrow),
                        const SizedBox(height: 20),

                        // Confidence Score
                        _ConfidenceCard(record: record),
                        const SizedBox(height: 20),

                        // Red Flags
                        if (record.redFlags.isNotEmpty) ...[
                          _RedFlagCard(redFlags: record.redFlags),
                          const SizedBox(height: 20),
                        ],

                        // Communication Analysis
                        _CommunicationAnalysisCard(record: record),
                        const SizedBox(height: 20),

                        // Visual Analysis
                        _VisualAnalysisCard(record: record),
                        const SizedBox(height: 20),

                        // Recommendations
                        if (record.recommendations.isNotEmpty) ...[
                          _RecommendationsCard(
                            recommendations: record.recommendations,
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Area Comparison
                        if (record.areaComparison != null) ...[
                          _AreaComparisonCard(
                            comparison: record.areaComparison!,
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Disclaimer
                        _DisclaimerCard(),
                        const SizedBox(height: 24),

                        // Action buttons row
                        Row(
                          children: [
                            Expanded(
                              child: _ActionCard(
                                icon: Icons.chat_bubble_outline,
                                title: 'Lihat Template\nChat',
                                subtitle: 'Siap digunakan',
                                onTap: () =>
                                    _showChatTemplateSheet(context, record),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ActionCard(
                                icon: Icons.share_outlined,
                                title: 'Bagikan Hasil',
                                subtitle: 'Kirim ke teman atau\norang tua',
                                onTap: () => _shareResult(context, record),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom button
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/analyze'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text(
                      'Analisis Ulang',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KosInfoHeader extends StatelessWidget {
  const _KosInfoHeader({required this.record, required this.isNarrow});
  final HistoryRecord record;
  final bool isNarrow;

  String _formatDate(DateTime d) {
    final months = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month]} ${d.year}, $hour.$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isNarrow ? 12 : 16),
      decoration: AppDecorations.card(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: isNarrow ? 60 : 72,
                  height: isNarrow ? 60 : 72,
                  color: AppColors.chipGray,
                  child: Image.network(
                    record.imageUrl,
                    headers: kIsWeb
                        ? null
                        : const {'Referer': 'https://mamikos.com/'},
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.home_outlined,
                          color: AppColors.iconDefault, size: 28),
                    ),
                  ),
                ),
              ),
              SizedBox(width: isNarrow ? 10 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.namaKos,
                      style: TextStyle(
                        fontSize: isNarrow ? 14 : 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            record.lokasi,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.hargaPerBulan,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      record.sumberListing,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Dianalisis pada ${_formatDate(record.analysisDate)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RiskScoreCard extends StatelessWidget {
  const _RiskScoreCard({required this.record, required this.isNarrow});
  final HistoryRecord record;
  final bool isNarrow;

  Color _scoreColor() {
    switch (record.riskLevel) {
      case RiskLevel.rendah:
        return const Color(0xFF10B981);
      case RiskLevel.sedang:
        return const Color(0xFFF59E0B);
      case RiskLevel.tinggi:
        return const Color(0xFFEF4444);
    }
  }

  Color _chipBg() {
    return Colors.white;
  }

  Color _chipText() {
    switch (record.riskLevel) {
      case RiskLevel.rendah:
        return const Color(0xFF10B981);
      case RiskLevel.sedang:
        return const Color(0xFFF59E0B);
      case RiskLevel.tinggi:
        return const Color(0xFFEF4444);
    }
  }

  List<Color> _gradientColors() {
    switch (record.riskLevel) {
      case RiskLevel.rendah:
        return [const Color(0xFFD1FAE5), const Color(0xFFA7F3D0)];
      case RiskLevel.sedang:
        return [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)];
      case RiskLevel.tinggi:
        return [const Color(0xFFFEE2E2), const Color(0xFFFECACA)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final scoreSize = isNarrow ? 80.0 : 90.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradientColors(),
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.all(isNarrow ? 16 : 20),
      child: Row(
        children: [
          SizedBox(
            width: scoreSize,
            height: scoreSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: scoreSize,
                  height: scoreSize,
                  child: CircularProgressIndicator(
                    value: record.riskScore / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withOpacity(0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(_scoreColor()),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${record.riskScore}',
                      style: TextStyle(
                        fontSize: isNarrow ? 24 : 28,
                        fontWeight: FontWeight.w800,
                        color: _scoreColor(),
                      ),
                    ),
                    Text(
                      '/ 100',
                      style: TextStyle(
                        fontSize: 11,
                        color: _scoreColor().withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: isNarrow ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Risk Score',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _chipBg(),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _chipText().withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: _chipText(),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          record.riskLabel.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _chipText(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  record.riskDescription,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfidenceCard extends StatelessWidget {
  const _ConfidenceCard({required this.record});
  final HistoryRecord record;

  @override
  Widget build(BuildContext context) {
    final pct = (record.confidenceScore * 100).round();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined,
                  size: 20, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Confidence Score',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '$pct%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Tingkat kelengkapan data untuk analisis yang akurat',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: record.confidenceScore,
              minHeight: 8,
              backgroundColor: AppColors.border.withOpacity(0.3),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    record.confidenceHint,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Communication Analysis Card
// ════════════════════════════════════════════════════════════════════

class _CommunicationAnalysisCard extends StatelessWidget {
  const _CommunicationAnalysisCard({required this.record});
  final HistoryRecord record;

  Widget _buildBooleanRow(String label, bool value,
      {bool invertColors = false}) {
    final bool isPositive = invertColors ? !value : value;
    final color =
        isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final bg = isPositive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
    final icon =
        isPositive ? Icons.check_circle_outline : Icons.cancel_outlined;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  value ? 'Ya' : 'Tidak',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.chat_outlined, size: 20, color: AppColors.textPrimary),
              SizedBox(width: 8),
              Text(
                'Analisis Komunikasi',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (record.communicationSummary.isNotEmpty) ...[
            Text(
              record.communicationSummary,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Risk Score',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${record.communicationRiskScore} / 100',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: record.communicationRiskScore >= 70
                            ? const Color(0xFFDC2626)
                            : record.communicationRiskScore >= 40
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pressure Level',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${record.pressureLevel} / 100',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: record.pressureLevel >= 70
                            ? const Color(0xFFDC2626)
                            : record.pressureLevel >= 40
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _buildBooleanRow('Ada inkonsistensi?', record.inconsistenciesFound,
              invertColors: true),
          _buildBooleanRow('Anomali pembayaran?', record.paymentAnomalyDetected,
              invertColors: true),
          _buildBooleanRow('Desakan transfer?', record.urgencyDetected,
              invertColors: true),
          _buildBooleanRow('Testimoni bot?', record.botTestimonialDetected,
              invertColors: true),
          _buildBooleanRow('Gagal cross-check?', record.isCrossCheckFail,
              invertColors: true),
          if (record.crossCheckDetails != null &&
              record.crossCheckDetails!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.chipYellow.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: AppColors.chipYellowText),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      record.crossCheckDetails!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.chipYellowText,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Visual Analysis Card
// ════════════════════════════════════════════════════════════════════

class _VisualAnalysisCard extends StatelessWidget {
  const _VisualAnalysisCard({required this.record});
  final HistoryRecord record;

  Widget _buildBooleanRow(String label, bool value,
      {bool invertColors = false}) {
    final bool isPositive = invertColors ? !value : value;
    final color =
        isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final bg = isPositive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
    final icon =
        isPositive ? Icons.check_circle_outline : Icons.cancel_outlined;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  value ? 'Ya' : 'Tidak',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.image_search_outlined,
                  size: 20, color: AppColors.textPrimary),
              SizedBox(width: 8),
              Text(
                'Analisis Visual',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (record.visualSummary.isNotEmpty) ...[
            Text(
              record.visualSummary,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
          ],
          _buildBooleanRow('Interior terdeteksi?', record.roomInteriorDetected),
          _buildBooleanRow('Foto realistis?', record.realisticImages),
          _buildBooleanRow('Ada watermark?', record.watermarkDetected,
              invertColors: true),
          if (record.watermarkSource != null &&
              record.watermarkSource!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Sumber Watermark: ${record.watermarkSource}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Risiko Metadata Foto',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${record.metadataMatchRisk} / 100',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: record.metadataMatchRisk >= 70
                            ? const Color(0xFFDC2626)
                            : record.metadataMatchRisk >= 40
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (record.metadataSummary != null &&
              record.metadataSummary!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.chipYellow.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: AppColors.chipYellowText),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      record.metadataSummary!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.chipYellowText,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RedFlagCard extends StatelessWidget {
  const _RedFlagCard({required this.redFlags});
  final List<RedFlag> redFlags;

  IconData _iconFor(String name) {
    switch (name) {
      case 'speed':
        return Icons.speed;
      case 'account_balance':
        return Icons.account_balance_outlined;
      case 'trending_down':
        return Icons.trending_down;
      case 'block':
        return Icons.block;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined, size: 20, color: AppColors.chipRedText),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Ringkasan Red Flag',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.chipRedText,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.chipRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${redFlags.length} ditemukan',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.chipRedText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...redFlags.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.chipRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _iconFor(f.icon),
                      size: 16,
                      color: AppColors.chipRedText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          f.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationsCard extends StatelessWidget {
  const _RecommendationsCard({required this.recommendations});
  final List<String> recommendations;

  static const _icons = [
    Icons.money_off_outlined,
    Icons.compare_arrows_outlined,
    Icons.calendar_today_outlined,
    Icons.verified_user_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tips_and_updates_outlined,
                  size: 20, color: AppColors.textPrimary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Apa yang sebaiknya dilakukan?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(recommendations.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    i < _icons.length ? _icons[i] : Icons.check_circle_outline,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      recommendations[i],
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _AreaComparisonCard extends StatelessWidget {
  const _AreaComparisonCard({required this.comparison});
  final AreaComparison comparison;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart_outlined,
                  size: 20, color: AppColors.textPrimary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Perbandingan harga area',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _CompRow('Harga Listing', comparison.hargaListing),
          _CompRow('Rata-rata Area', comparison.rataRataArea),
          if (comparison.medianArea != null)
            _CompRow('Median Area', comparison.medianArea!),
          const Divider(height: 20),
          Row(
            children: [
              const Text(
                'Selisih',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  comparison.selisihLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.chipYellow.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 16, color: AppColors.chipYellowText),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Harga terlalu murah bisa menjadi Red Flag. Benchmark berdasarkan harga rata-rata Area',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompRow extends StatelessWidget {
  const _CompRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Disclaimer',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'KosCheck tidak menyatakan listing pasti aman atau pasti penipuan. Hasil ini membantu anda mengenali indikator risiko dan melakukan verifikasi tambahan sebelum membuat keputusan.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// History Chat Template Bottom Sheet
// ════════════════════════════════════════════════════════════════════

class _HistoryChatTemplateSheet extends StatelessWidget {
  const _HistoryChatTemplateSheet({required this.record});
  final HistoryRecord record;

  List<ChatTemplate> _buildTemplates() {
    final templates = <ChatTemplate>[];

    // Opening greeting — always shown first
    templates.add(const ChatTemplate(
      number: 1,
      title: 'Sapaan Awal',
      body: 'Halo Kak, saya tertarik dengan kos ini. Boleh  bertanya beberapa '
          'hal terkait sistem pembayaran, fasilitas, aturan jam malam, dan '
          'kebijakan tamu? Terima kasih sebelumnya',
    ));

    // Standard question templates — always shown
    templates.addAll(const [
      ChatTemplate(
        number: 2,
        title: 'Sistem Pembayaran',
        body: 'Versi sopan:\n'
            '"Mohon maaf, untuk sistem pembayarannya bagaimana, ya, '
            'Kak/Bu/Pak? Apakah jatuh temponya di tanggal yang sama setiap '
            'bulan, dan apakah ada biaya deposit di awal?"\n\n'
            'Versi santai:\n'
            '"Kak, mau tanya untuk sistem pembayarannya gimana, ya? '
            'Biasanya dibayar tiap tanggal berapa dan ada biaya depositnya '
            'gak, ya?"',
      ),
      ChatTemplate(
        number: 3,
        title: 'Fasilitas Kamar & Tagihan Bulanan',
        body: 'Versi sopan:\n'
            '"Untuk biaya bulanan tersebut, apakah sudah termasuk '
            '(include) listrik, air, Wi-Fi, dan AC, atau ada biaya '
            'terpisah? Lalu untuk fasilitas di dalam kamar, apakah sudah '
            'disediakan kasur, lemari, dan meja?"\n\n'
            'Versi santai:\n'
            '"Biaya kostnya udah include listrik, air, Wi-Fi, sama AC '
            'belum, ya? Terus di dalam kamar udah dapet fasilitas seperti '
            'kasur, lemari, dan meja juga?"',
      ),
      ChatTemplate(
        number: 4,
        title: 'Fasilitas Bersama & Aturan Memasak',
        body: 'Versi sopan:\n'
            '"Apakah di kos ini diperbolehkan untuk memasak? Serta apakah '
            'ada fasilitas bersama yang bisa digunakan, seperti dapur, '
            'kulkas, dispenser, atau mesin cuci?"\n\n'
            'Versi santai:\n'
            '"Di sini boleh masak gak, ya? Terus ada fasilitas bersama '
            'yang bisa dipakai bareng-bareng gak, Kak? Seperti dapur, '
            'kulkas, dispenser, atau mesin cuci."',
      ),
      ChatTemplate(
        number: 5,
        title: 'Jam Malam & Akses Kunci',
        body: 'Versi sopan:\n'
            '"Untuk aturan jam malamnya bagaimana, ya, Pak/Bu? Apakah '
            'penghuni kos diberikan kunci gerbang/akses sendiri untuk '
            'mengantisipasi jika pulang larut malam?"\n\n'
            'Versi santai:\n'
            '"Di kos ini ada jam malamnya gak, Kak? Kalau pulang malam, '
            'apakah dapet kunci gerbang/akses sendiri biar gak kekunci di '
            'luar?"',
      ),
      ChatTemplate(
        number: 6,
        title: 'Aturan Menerima Tamu',
        body: 'Versi sopan:\n'
            '"Bagaimana dengan kebijakan terkait tamu berkunjung? Apakah '
            'diperbolehkan masuk ke area kamar, menginap, atau dibatasi '
            'hanya sampai di ruang tamu saja?"\n\n'
            'Versi santai:\n'
            '"Kak, untuk aturan menerima tamu gimana, ya? Apakah boleh '
            'main sampai kamar, boleh menginap, atau cuma dibatasi sampai '
            'ruang tamu aja?"',
      ),
      ChatTemplate(
        number: 7,
        title: 'Biaya Perbaikan & Perawatan (Maintenance)',
        body: 'Versi sopan:\n'
            '"Jika ke depannya ada fasilitas kamar yang rusak atau '
            'memerlukan servis (seperti AC atau lampu), apakah biayanya '
            'ditanggung oleh pemilik kos atau oleh penghuni?"\n\n'
            'Versi santai:\n'
            '"Kalau nanti ada fasilitas kamar yang rusak atau butuh servis '
            '(misal AC kurang dingin), itu biayanya ditanggung pemilik kos '
            'atau kita sendiri, ya?"',
      ),
    ]);

    return templates;
  }

  @override
  Widget build(BuildContext context) {
    final templates = _buildTemplates();
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.chat_bubble_outline,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Template Chat',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Langsung salin dan kirim ke pemilik kos',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Template cards — scrollable
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: templates.map((t) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.scaffoldBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${t.number}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  t.title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(
                                      ClipboardData(text: t.body));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('\'${t.title}\' disalin!'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Salin',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.copy,
                                        size: 14, color: AppColors.primary),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              t.body,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Copy all button
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final allText = templates
                      .map((t) => '${t.title}:\n${t.body}')
                      .join('\n\n---\n\n');
                  Clipboard.setData(ClipboardData(text: allText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Semua template berhasil disalin!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Salin Semua Template'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
