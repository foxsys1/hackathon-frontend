import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kos_gdgoc/core/theme/app_theme.dart';
import 'package:kos_gdgoc/features/history/data/mock_history_data.dart';
import 'package:kos_gdgoc/features/history/domain/history_record.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _searchQuery = '';
  String _sortBy = 'Terbaru';
  int _visibleCount = 6;

  List<HistoryRecord> get _filtered {
    var list = mockHistoryRecords.where((r) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return r.namaKos.toLowerCase().contains(q) ||
          r.lokasi.toLowerCase().contains(q) ||
          r.sumberListing.toLowerCase().contains(q);
    }).toList();
    if (_sortBy == 'Terbaru') {
      list.sort((a, b) => b.analysisDate.compareTo(a.analysisDate));
    } else {
      list.sort((a, b) => a.analysisDate.compareTo(b.analysisDate));
    }
    return list;
  }

  int get _totalAnalisis => mockHistoryRecords.length;
  int get _rendahCount =>
      mockHistoryRecords.where((r) => r.riskLevel == RiskLevel.rendah).length;
  int get _sedangCount =>
      mockHistoryRecords.where((r) => r.riskLevel == RiskLevel.sedang).length;
  int get _tinggiCount =>
      mockHistoryRecords.where((r) => r.riskLevel == RiskLevel.tinggi).length;

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final visible = filtered.take(_visibleCount).toList();
    final hasMore = filtered.length > _visibleCount;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 360;
            final hPad = isNarrow ? 14.0 : 20.0;

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Header
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Riwayat Analisis',
                                style: TextStyle(
                                  fontSize: isNarrow ? 22 : 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Riwayat kos yang sudah Anda analisis.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.filter_list,
                                size: 20, color: AppColors.textPrimary),
                            padding: EdgeInsets.zero,
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Search bar
                    TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Cari nama kos, lokasi, atau sumber...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: AppColors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Activity summary card
                    _ActivitySummaryCard(
                      total: _totalAnalisis,
                      rendah: _rendahCount,
                      sedang: _sedangCount,
                      tinggi: _tinggiCount,
                      isNarrow: isNarrow,
                    ),
                    const SizedBox(height: 24),

                    // Section header
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Ulas Kembali',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        _SortDropdown(
                          value: _sortBy,
                          onChanged: (v) =>
                              setState(() => _sortBy = v ?? _sortBy),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Records list
                    ...visible.map((record) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _HistoryRecordCard(
                            record: record,
                            isNarrow: isNarrow,
                            onTap: () => context.push('/history/${record.id}'),
                          ),
                        )),

                    if (hasMore)
                      Center(
                        child: TextButton.icon(
                          onPressed: () =>
                              setState(() => _visibleCount += 6),
                          icon: const Icon(Icons.expand_more, size: 18),
                          label: const Text('Tampilkan lebih banyak'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ),

                    if (filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'Tidak ada riwayat ditemukan.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Activity Summary Card
// ─────────────────────────────────────────────────────────

class _ActivitySummaryCard extends StatelessWidget {
  const _ActivitySummaryCard({
    required this.total,
    required this.rendah,
    required this.sedang,
    required this.tinggi,
    required this.isNarrow,
  });

  final int total;
  final int rendah;
  final int sedang;
  final int tinggi;
  final bool isNarrow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isNarrow ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Aktivitas',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatItem(
                icon: Icons.assignment_outlined,
                iconColor: AppColors.primary,
                count: total,
                label: 'Total analisis',
                isNarrow: isNarrow,
              ),
              _statDivider(),
              _StatItem(
                icon: Icons.check_circle_outline,
                iconColor: const Color(0xFF10B981),
                count: rendah,
                label: 'Risiko Rendah',
                isNarrow: isNarrow,
              ),
              _statDivider(),
              _StatItem(
                icon: Icons.warning_amber_rounded,
                iconColor: const Color(0xFFF59E0B),
                count: sedang,
                label: 'Risiko Sedang',
                isNarrow: isNarrow,
              ),
              _statDivider(),
              _StatItem(
                icon: Icons.dangerous_outlined,
                iconColor: const Color(0xFFEF4444),
                count: tinggi,
                label: 'Risiko Tinggi',
                isNarrow: isNarrow,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statDivider() => Container(
        width: 1,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: AppColors.divider,
      );
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.count,
    required this.label,
    required this.isNarrow,
  });

  final IconData icon;
  final Color iconColor;
  final int count;
  final String label;
  final bool isNarrow;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: isNarrow ? 16 : 18, color: iconColor),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: isNarrow ? 16 : 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isNarrow ? 9 : 10,
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Sort Dropdown
// ─────────────────────────────────────────────────────────

class _SortDropdown extends StatelessWidget {
  const _SortDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 18, color: AppColors.textSecondary),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          items: const [
            DropdownMenuItem(
              value: 'Terbaru',
              child: Text('Urutkan: Terbaru'),
            ),
            DropdownMenuItem(
              value: 'Terlama',
              child: Text('Urutkan: Terlama'),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// History Record Card
// ─────────────────────────────────────────────────────────

class _HistoryRecordCard extends StatelessWidget {
  const _HistoryRecordCard({
    required this.record,
    required this.isNarrow,
    required this.onTap,
  });

  final HistoryRecord record;
  final bool isNarrow;
  final VoidCallback onTap;

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

  String _formatDate(DateTime d) {
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month]} ${d.year}, $hour.$minute';
  }

  @override
  Widget build(BuildContext context) {
    final imgSize = isNarrow ? 64.0 : 76.0;
    final scoreSize = isNarrow ? 44.0 : 52.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isNarrow ? 10 : 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kos image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: imgSize,
                    height: imgSize,
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

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.namaKos,
                        style: TextStyle(
                          fontSize: isNarrow ? 13 : 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: AppColors.textSecondary),
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
                      const SizedBox(height: 3),
                      Text(
                        record.hargaPerBulan,
                        style: TextStyle(
                          fontSize: isNarrow ? 12 : 13,
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

                const SizedBox(width: 8),

                // Score circle + label
                Column(
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
                              strokeWidth: 4,
                              backgroundColor: AppColors.border.withOpacity(0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  _scoreColor()),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Text(
                            '${record.riskScore}',
                            style: TextStyle(
                              fontSize: isNarrow ? 14 : 16,
                              fontWeight: FontWeight.w800,
                              color: _scoreColor(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _chipBg(),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        record.riskLabel,
                        style: TextStyle(
                          fontSize: isNarrow ? 8 : 9,
                          fontWeight: FontWeight.w700,
                          color: _chipText(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Footer: date + action
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _formatDate(record.analysisDate),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lihat Detail',
                        style: TextStyle(
                          fontSize: isNarrow ? 11 : 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.chevron_right,
                          size: 16, color: AppColors.primary),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
