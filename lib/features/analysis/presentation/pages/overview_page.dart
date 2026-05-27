import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kos_gdgoc/core/theme/app_theme.dart';
import 'package:kos_gdgoc/features/analysis/domain/analysis_state.dart';
import 'package:kos_gdgoc/features/analysis/presentation/widgets/step_progress_bar.dart';

class OverviewPage extends ConsumerWidget {
  const OverviewPage({super.key});

  void _startAnalysis(BuildContext context, WidgetRef ref, BasicInfo basic) {
    final missingFields = <String>[];
    if (basic.namaKos.trim().isEmpty) missingFields.add('Nama Kos');
    if (basic.lokasi.trim().isEmpty) missingFields.add('Lokasi');
    if (basic.hargaPerBulan.trim().isEmpty ||
        !RegExp(r'\d').hasMatch(basic.hargaPerBulan)) {
      missingFields.add('Harga per Bulan');
    }

    if (missingFields.isNotEmpty) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ValidationSheet(
          missingFields: missingFields,
          onFix: () {
            Navigator.pop(context);
            context.push('/analyze');
          },
        ),
      );
      return;
    }

    context.push('/analyze/loading');
  }

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
                    onEdit: () => context.push('/analyze'),
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
                          Icons.location_on_outlined,
                          'Alamat spesifik',
                          _q1Label(qc.addressSpecific),
                          _q1Color(qc.addressSpecific),
                          _q1TextColor(qc.addressSpecific),
                        ),
                        _VerifRow(
                          Icons.photo_camera_outlined,
                          'Foto sesuai lokasi',
                          _triChipLabel(qc.photoMatchLocation),
                          _triChipColor(qc.photoMatchLocation),
                          _triChipTextColor(qc.photoMatchLocation),
                        ),
                        _VerifRow(
                          Icons.info_outline,
                          'Info konsisten',
                          _triChipLabel(qc.infoConsistent),
                          _triChipColor(qc.infoConsistent),
                          _triChipTextColor(qc.infoConsistent),
                        ),
                        _VerifRow(
                          Icons.videocam_outlined,
                          'Survei/Video call diizinkan',
                          _triChipLabel(qc.surveyOrVideoCallAllowed),
                          _triChipColor(qc.surveyOrVideoCallAllowed),
                          _triChipTextColor(qc.surveyOrVideoCallAllowed),
                        ),
                        _VerifRow(
                          Icons.account_balance_wallet_outlined,
                          'DP diminta sebelum survei',
                          _triChipLabel(qc.dpRequestedBeforeSurvey),
                          _triChipColorInverted(qc.dpRequestedBeforeSurvey),
                          _triChipTextColorInverted(qc.dpRequestedBeforeSurvey),
                        ),
                        _VerifRow(
                          Icons.warning_amber_outlined,
                          'Tekanan transfer DP',
                          _triChipLabel(qc.pressureToTransfer),
                          _triChipColorInverted(qc.pressureToTransfer),
                          _triChipTextColorInverted(qc.pressureToTransfer),
                        ),
                        _VerifRow(
                          Icons.video_library_outlined,
                          'Bersedia kirim video terbaru',
                          _q7Label(qc.willingToProvideVideo),
                          _q7Color(qc.willingToProvideVideo),
                          _q7TextColor(qc.willingToProvideVideo),
                        ),
                        _VerifRow(
                          Icons.person_outline,
                          'Identitas konsisten',
                          _triChipLabel(qc.identityConsistent),
                          _triChipColor(qc.identityConsistent),
                          _triChipTextColor(qc.identityConsistent),
                        ),
                        _VerifRow(
                          Icons.receipt_long_outlined,
                          'Rincian pembayaran jelas',
                          _q9Label(qc.paymentDetailsClear),
                          _q9Color(qc.paymentDetailsClear),
                          _q9TextColor(qc.paymentDetailsClear),
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
                onPressed: () => _startAnalysis(context, ref, basic),
                child: const Text('Analisis Risiko'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── TriAnswer helpers ──
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

  // Inverted: Ya = red (bad), Tidak = green (good)
  Color _triChipColorInverted(TriAnswer? val) {
    if (val == null) return AppColors.chipGray;
    switch (val) {
      case TriAnswer.ya:
        return AppColors.chipRed;
      case TriAnswer.tidak:
        return AppColors.chipGreen;
      case TriAnswer.tidakTahu:
        return AppColors.chipYellow;
    }
  }

  Color _triChipTextColorInverted(TriAnswer? val) {
    if (val == null) return AppColors.chipGrayText;
    switch (val) {
      case TriAnswer.ya:
        return AppColors.chipRedText;
      case TriAnswer.tidak:
        return AppColors.chipGreenText;
      case TriAnswer.tidakTahu:
        return AppColors.chipYellowText;
    }
  }

  // ── Q1AddressAnswer helpers ──
  String _q1Label(Q1AddressAnswer? val) {
    if (val == null) return '-';
    switch (val) {
      case Q1AddressAnswer.ya:
        return 'Ya';
      case Q1AddressAnswer.hanyaAlamat:
        return 'Hanya Alamat';
      case Q1AddressAnswer.hanyaArea:
        return 'Hanya Area';
    }
  }

  Color _q1Color(Q1AddressAnswer? val) {
    if (val == null) return AppColors.chipGray;
    switch (val) {
      case Q1AddressAnswer.ya:
        return AppColors.chipGreen;
      case Q1AddressAnswer.hanyaAlamat:
        return AppColors.chipYellow;
      case Q1AddressAnswer.hanyaArea:
        return AppColors.chipRed;
    }
  }

  Color _q1TextColor(Q1AddressAnswer? val) {
    if (val == null) return AppColors.chipGrayText;
    switch (val) {
      case Q1AddressAnswer.ya:
        return AppColors.chipGreenText;
      case Q1AddressAnswer.hanyaAlamat:
        return AppColors.chipYellowText;
      case Q1AddressAnswer.hanyaArea:
        return AppColors.chipRedText;
    }
  }

  // ── Q7VideoAnswer helpers ──
  String _q7Label(Q7VideoAnswer? val) {
    if (val == null) return '-';
    switch (val) {
      case Q7VideoAnswer.ya:
        return 'Ya';
      case Q7VideoAnswer.hanyaVideoLama:
        return 'Video Lama';
      case Q7VideoAnswer.tidak:
        return 'Tidak';
    }
  }

  Color _q7Color(Q7VideoAnswer? val) {
    if (val == null) return AppColors.chipGray;
    switch (val) {
      case Q7VideoAnswer.ya:
        return AppColors.chipGreen;
      case Q7VideoAnswer.hanyaVideoLama:
        return AppColors.chipYellow;
      case Q7VideoAnswer.tidak:
        return AppColors.chipRed;
    }
  }

  Color _q7TextColor(Q7VideoAnswer? val) {
    if (val == null) return AppColors.chipGrayText;
    switch (val) {
      case Q7VideoAnswer.ya:
        return AppColors.chipGreenText;
      case Q7VideoAnswer.hanyaVideoLama:
        return AppColors.chipYellowText;
      case Q7VideoAnswer.tidak:
        return AppColors.chipRedText;
    }
  }

  // ── Q9PaymentAnswer helpers ──
  String _q9Label(Q9PaymentAnswer? val) {
    if (val == null) return '-';
    switch (val) {
      case Q9PaymentAnswer.jelas:
        return 'Jelas';
      case Q9PaymentAnswer.sebagian:
        return 'Sebagian';
      case Q9PaymentAnswer.tidakDijelaskan:
        return 'Tidak Dijelaskan';
      case Q9PaymentAnswer.belumTahap:
        return 'Belum Tahap';
    }
  }

  Color _q9Color(Q9PaymentAnswer? val) {
    if (val == null) return AppColors.chipGray;
    switch (val) {
      case Q9PaymentAnswer.jelas:
        return AppColors.chipGreen;
      case Q9PaymentAnswer.sebagian:
        return AppColors.chipYellow;
      case Q9PaymentAnswer.tidakDijelaskan:
        return AppColors.chipRed;
      case Q9PaymentAnswer.belumTahap:
        return AppColors.chipGray;
    }
  }

  Color _q9TextColor(Q9PaymentAnswer? val) {
    if (val == null) return AppColors.chipGrayText;
    switch (val) {
      case Q9PaymentAnswer.jelas:
        return AppColors.chipGreenText;
      case Q9PaymentAnswer.sebagian:
        return AppColors.chipYellowText;
      case Q9PaymentAnswer.tidakDijelaskan:
        return AppColors.chipRedText;
      case Q9PaymentAnswer.belumTahap:
        return AppColors.chipGrayText;
    }
  }
}

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

class _ValidationSheet extends StatelessWidget {
  const _ValidationSheet({
    required this.missingFields,
    required this.onFix,
  });

  final List<String> missingFields;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.chipRed,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline,
                  color: AppColors.chipRedText, size: 28),
            ),
            const SizedBox(height: 16),
            const Text(
              'Data Belum Lengkap',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lengkapi informasi berikut sebelum memulai analisis:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            ...missingFields.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.circle,
                        size: 6, color: AppColors.chipRedText),
                    const SizedBox(width: 8),
                    Text(
                      f,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.chipRedText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onFix,
              child: const Text('Lengkapi Informasi Dasar'),
            ),
          ],
        ),
      ),
    );
  }
}
