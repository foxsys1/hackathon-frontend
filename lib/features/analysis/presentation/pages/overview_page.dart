import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kos_gdgoc/core/theme/app_theme.dart';
import 'package:kos_gdgoc/features/analysis/domain/analysis_state.dart';
import 'package:kos_gdgoc/features/analysis/presentation/widgets/step_progress_bar.dart';

class OverviewPage extends ConsumerWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analysisStateNotifierProvider);
    final basic = state.basicInfo;
    final qc = state.quickCheck;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Overview'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: StepProgressBar(currentStep: 3),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ulas Kembali',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tinjau semua informasi dan hasil verifikasi sebelum melanjutkan ke analisis risiko.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Informasi Dasar Card ──
                  _OverviewCard(
                    icon: Icons.verified_outlined,
                    title: 'Informasi Dasar',
                    onEdit: () => context.go('/analyze'),
                    child: Column(
                      children: [
                        _InfoRow('Nama', basic.namaKos),
                        _InfoRow('Lokasi', basic.lokasi),
                        _InfoRow('Harga/bulan', basic.hargaPerBulan),
                        _InfoRow('Deposit', basic.deposit),
                        _InfoRow('Sumber Listing', basic.sumberListing),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Indikator Verifikasi Card ──
                  _OverviewCard(
                    icon: Icons.warning_amber_outlined,
                    title: 'Indikator Verifikasi',
                    onEdit: () => context.push('/analyze/quick-edit'),
                    child: Column(
                      children: [
                        _VerifRow(
                          Icons.photo_camera_outlined,
                          'Kelengkapan Foto/Video',
                          _triChipLabel(qc.hasPhotos),
                          _triChipColor(qc.hasPhotos),
                          _triChipTextColor(qc.hasPhotos),
                        ),
                        _VerifRow(
                          Icons.location_on_outlined,
                          'Alamat lengkap',
                          _triChipLabel(qc.addressSpecific),
                          _triChipColor(qc.addressSpecific),
                          _triChipTextColor(qc.addressSpecific),
                        ),
                        _VerifRow(
                          Icons.person_outline,
                          'Nama sesuai',
                          _triChipLabel(qc.knowsContactName),
                          _triChipColor(qc.knowsContactName),
                          _triChipTextColor(qc.knowsContactName),
                        ),
                        _VerifRow(
                          Icons.videocam_outlined,
                          'Video call tersedia',
                          _triChipLabel(qc.videoCallAvailable),
                          _triChipColor(qc.videoCallAvailable),
                          _triChipTextColor(qc.videoCallAvailable),
                        ),
                        _VerifRow(
                          Icons.assignment_outlined,
                          'Survei diperbolehkan',
                          _triChipLabel(qc.surveyAllowed),
                          _triChipColor(qc.surveyAllowed),
                          _triChipTextColor(qc.surveyAllowed),
                        ),
                        _VerifRow(
                          Icons.payment_outlined,
                          'Tekanan transfer DP',
                          _triChipLabel(qc.transferPressure),
                          _triChipColor(qc.transferPressure),
                          _triChipTextColor(qc.transferPressure),
                        ),
                        _VerifRow(
                          Icons.rate_review_outlined,
                          'Ada testimoni',
                          _triChipLabel(qc.hasTestimony),
                          _triChipColor(qc.hasTestimony),
                          _triChipTextColor(qc.hasTestimony),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Disclaimer ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            color: AppColors.primary, size: 22),
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
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: ElevatedButton(
                onPressed: () => context.push('/analyze/loading'),
                child: const Text('Analisis Risiko'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──
  String _triChipLabel(TriAnswer? val) {
    if (val == null) return '-';
    switch (val) {
      case TriAnswer.ya:
        return 'Ya';
      case TriAnswer.tidak:
        return 'Tidak';
      case TriAnswer.tidakTahu:
        return 'Tidak Tahu';
    }
  }

  Color _triChipColor(TriAnswer? val) {
    if (val == null) return AppColors.chipGray;
    switch (val) {
      case TriAnswer.ya:
        return AppColors.chipGreen;
      case TriAnswer.tidak:
        return AppColors.chipRed;
      case TriAnswer.tidakTahu:
        return AppColors.chipYellow;
    }
  }

  Color _triChipTextColor(TriAnswer? val) {
    if (val == null) return AppColors.chipGrayText;
    switch (val) {
      case TriAnswer.ya:
        return AppColors.chipGreenText;
      case TriAnswer.tidak:
        return AppColors.chipRedText;
      case TriAnswer.tidakTahu:
        return AppColors.chipYellowText;
    }
  }
}

// ─────────────────────────────────────────────────────────
// Reusable widgets
// ─────────────────────────────────────────────────────────

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.icon,
    required this.title,
    required this.onEdit,
    required this.child,
  });

  final IconData icon;
  final String title;
  final VoidCallback onEdit;
  final Widget child;

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
              Icon(icon, color: AppColors.textPrimary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: const Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 3,
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifRow extends StatelessWidget {
  const _VerifRow(
    this.icon,
    this.label,
    this.chipLabel,
    this.chipBg,
    this.chipTextColor,
  );

  final IconData icon;
  final String label;
  final String chipLabel;
  final Color chipBg;
  final Color chipTextColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              chipLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: chipTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
