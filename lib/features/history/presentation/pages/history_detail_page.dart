import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kos_gdgoc/core/theme/app_theme.dart';
import 'package:kos_gdgoc/features/analysis/domain/analysis_state.dart';
import 'package:kos_gdgoc/features/history/data/mock_history_data.dart';
import 'package:kos_gdgoc/features/history/domain/history_record.dart';

class HistoryDetailPage extends StatelessWidget {
  const HistoryDetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final record = mockHistoryRecords.cast<HistoryRecord?>().firstWhere(
          (r) => r!.id == id,
          orElse: () => null,
        );

    if (record == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Hasil')),
        body: const Center(child: Text('Data tidak ditemukan')),
      );
    }

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
                                onTap: () {},
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ActionCard(
                                icon: Icons.share_outlined,
                                title: 'Bagikan Hasil',
                                subtitle: 'Kirim ke teman atau\norang tua',
                                onTap: () {},
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

// ─────────────────────────────────────────────────────────
// Kos Info Header
// ─────────────────────────────────────────────────────────

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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
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

// ─────────────────────────────────────────────────────────
// Risk Score Card
// ─────────────────────────────────────────────────────────

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
    switch (record.riskLevel) {
      case RiskLevel.rendah:
        return AppColors.chipGreen;
      case RiskLevel.sedang:
        return AppColors.chipYellow;
      case RiskLevel.tinggi:
        return AppColors.chipRed;
    }
  }

  Color _chipText() {
    switch (record.riskLevel) {
      case RiskLevel.rendah:
        return AppColors.chipGreenText;
      case RiskLevel.sedang:
        return AppColors.chipYellowText;
      case RiskLevel.tinggi:
        return AppColors.chipRedText;
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
                    valueColor:
                        AlwaysStoppedAnimation<Color>(_scoreColor()),
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
                    borderRadius: BorderRadius.circular(8),
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

// ─────────────────────────────────────────────────────────
// Confidence Card
// ─────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────
// Red Flag Card
// ─────────────────────────────────────────────────────────

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
              Icon(Icons.flag_outlined,
                  size: 20, color: AppColors.chipRedText),
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

// ─────────────────────────────────────────────────────────
// Recommendations Card
// ─────────────────────────────────────────────────────────

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
                    i < _icons.length
                        ? _icons[i]
                        : Icons.check_circle_outline,
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

// ─────────────────────────────────────────────────────────
// Area Comparison Card
// ─────────────────────────────────────────────────────────

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
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

// ─────────────────────────────────────────────────────────
// Disclaimer Card
// ─────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────
// Action Card
// ─────────────────────────────────────────────────────────

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
