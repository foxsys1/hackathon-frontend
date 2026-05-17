import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kos_gdgoc/core/theme/app_theme.dart';
import 'package:kos_gdgoc/features/analysis/domain/analysis_state.dart';

class AnalyzingPage extends ConsumerStatefulWidget {
  const AnalyzingPage({super.key});

  @override
  ConsumerState<AnalyzingPage> createState() => _AnalyzingPageState();
}

class _AnalyzingPageState extends ConsumerState<AnalyzingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressCtrl;
  late final Animation<double> _progressAnim;
  Timer? _stepTimer;
  int _currentStep = 0;
  bool _cancelled = false;

  static const _steps = [
    'Memeriksa informasi listing...',
    'Menganalisis indikator verifikasi...',
    'Melakukan deep check...',
    'Membandingkan harga area...',
    'Mendeteksi pola risiko...',
    'Menyiapkan hasil analisis...',
  ];

  static const _stepStatuses = [
    _StepStatus.done,
    _StepStatus.processing,
    _StepStatus.processing,
    _StepStatus.waiting,
    _StepStatus.waiting,
    _StepStatus.waiting,
  ];

  List<_StepStatus> _statuses = List.from(_stepStatuses);

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _progressAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut),
    );
    _progressCtrl.addListener(() => setState(() {}));

    _startAnalysis();
  }

  void _startAnalysis() {
    _progressCtrl.forward();

    _stepTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_cancelled) {
        timer.cancel();
        return;
      }
      if (_currentStep < _steps.length - 1) {
        setState(() {
          _statuses[_currentStep] = _StepStatus.done;
          _currentStep++;
          if (_currentStep < _steps.length) {
            _statuses[_currentStep] = _StepStatus.processing;
          }
        });
      } else {
        timer.cancel();
        setState(() {
          _statuses[_currentStep] = _StepStatus.done;
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 3200), () {
      if (!mounted || _cancelled) return;
      _populateMockResult();
      context.go('/analyze/result');
    });
  }

  void _populateMockResult() {
    ref.read(analysisStateNotifierProvider.notifier).setResult(
          const AnalysisResult(
            riskScore: 82,
            riskLabel: 'RISIKO TINGGI',
            riskDescription:
                'Listing ini tidak menunjukkan beberapa indikator risiko. BAHAYAAA disarankan utk verif lebih lanjut',
            confidenceScore: 0.62,
            confidenceHint:
                'Lengkapi data "Tidak Tahu" untuk meningkatkan akurasi analisis',
            redFlags: [
              RedFlag(
                title: 'Tekanan Bayar cepat',
                description:
                    'Pemilik mendesak DP sebelum survei/lihat kos',
                icon: 'speed',
              ),
              RedFlag(
                title: 'Rekening Berbeda',
                description:
                    'Nama rekening tidak sesuai dengan nama pemilik',
                icon: 'account_balance',
              ),
              RedFlag(
                title: 'Harga di Bawah Pasar',
                description:
                    'Harga lebih murah daripada harga rata-rata di area sekitar',
                icon: 'trending_down',
              ),
              RedFlag(
                title: 'Tidak Boleh Survei',
                description:
                    'Pemilik menolak permintaan untuk survei langsung',
                icon: 'block',
              ),
            ],
            recommendations: [
              'Jangan transfer uang apapun dulu',
              'Bandingkan harga dengan listing di Mamikos/Rukita',
              'Paksa jadwal survei langsung ke lokasi',
              'Cek sertifikat ke BPN atau AHU Online',
            ],
            areaComparison: AreaComparison(
              hargaListing: 'Rp 1.500.000 / bulan',
              rataRataArea: 'Rp 1.800.000 / bulan',
              selisih: '-17% (lebih murah)',
              selisihLabel: '-17% (lebih murah)',
            ),
            chatTemplates: [
              ChatTemplate(
                number: 1,
                title: 'Terkait DP sebelum survei',
                body:
                    'Halo kak, terima kasih sebelumnya atas informasinya.\nSaya tertarik dengan kos yang kakak tawarkan. Sebelum saya memutuskan, boleh saya pastikan dulu beberapa hal?\nTerkait pembayaran DP, apakah ada alasan pembayaran perlu dilakukan dalam waktu dekat? Apakah saya bisa melihat kamar/survei terlebih dahulu sebelum melakukan transfer?\nKalau nanti saya sudah bayar DP tapi ternyata tidak cocok setelah survei, apakah DP bisa dikembalikan?',
              ),
              ChatTemplate(
                number: 2,
                title: 'Terkait Harga di bawah rata-rata',
                body:
                    'Halo kak, saya mau tanya terkait harga kosnya.\nHarga yang ditawarkan terlihat lebih murah dibanding beberapa kos lain di area sekitar. Apakah ada alasan khusus, misalnya promo, fasilitas tertentu yang belum termasuk, atau kondisi kamar tertentu?\nApakah harga tersebut sudah termasuk listrik, air, wifi, dan fasilitas lainnya?',
              ),
              ChatTemplate(
                number: 3,
                title: 'Terkait nama rekening yang berbeda',
                body:
                    'Halo kak, saya ingin memastikan keamanan pembayaran sebelum transfer.\nRekening yang digunakan untuk pembayaran apakah atas nama pemilik kos langsung? Kalau berbeda, boleh saya tahu hubungan pemilik rekening dengan pemilik kos?\nBoleh juga minta konfirmasi nama lengkap pemilik kos dan bukti bahwa rekening tersebut memang resmi digunakan untuk pembayaran kos?',
              ),
            ],
          ),
        );
  }

  void _showCancelDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CancelSheet(
        onCancel: () {
          Navigator.pop(context);
          setState(() => _cancelled = true);
          _progressCtrl.stop();
          _stepTimer?.cancel();
          context.go('/analyze/overview');
        },
        onContinue: () => Navigator.pop(context),
      ),
    );
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _stepTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analysisStateNotifierProvider);
    final basic = state.basicInfo;
    final percent = (_progressAnim.value * 100).round();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // AppBar area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _showCancelDialog,
                  ),
                  const Expanded(
                    child: Text(
                      'Menganalisis...',
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // Circular progress
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 160,
                            height: 160,
                            child: CircularProgressIndicator(
                              value: _progressAnim.value,
                              strokeWidth: 10,
                              backgroundColor: AppColors.border.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$percent%',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              const Text(
                                'Sedang diproses',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    const Text(
                      'Menganalisis Listing Anda',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Kami sedang memeriksa data dan\nindikator yang relevan...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Time hint chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.chipGray,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time,
                              size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          const Text(
                            'Biasanya memakan waktu 10-20 detik',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Listing info card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.chipGray,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.home_outlined,
                                  color: AppColors.textSecondary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            basic.namaKos.isEmpty
                                                ? 'Kos Putra Senja Ayu'
                                                : basic.namaKos,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            '#KC-001',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined,
                                            size: 14,
                                            color: AppColors.textSecondary),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            basic.lokasi.isEmpty
                                                ? 'Pogung Baru, Sleman, Yogyakarta'
                                                : basic.lokasi,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 12),

                          // Steps
                          ...List.generate(_steps.length, (i) {
                            return _AnalysisStepRow(
                              label: _steps[i],
                              status: _statuses[i],
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Disclaimer
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
          ],
        ),
      ),
    );
  }
}


enum _StepStatus { waiting, processing, done }

class _AnalysisStepRow extends StatelessWidget {
  const _AnalysisStepRow({required this.label, required this.status});

  final String label;
  final _StepStatus status;

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    IconData icon;
    String statusLabel;
    Color statusColor;

    switch (status) {
      case _StepStatus.done:
        icon = Icons.check_circle;
        iconColor = const Color(0xFF10B981);
        statusLabel = 'Selesai';
        statusColor = const Color(0xFF10B981);
      case _StepStatus.processing:
        icon = Icons.autorenew;
        iconColor = AppColors.primary;
        statusLabel = 'Proses';
        statusColor = AppColors.primary;
      case _StepStatus.waiting:
        icon = Icons.radio_button_unchecked;
        iconColor = AppColors.border;
        statusLabel = 'Menunggu';
        statusColor = AppColors.textSecondary;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: status == _StepStatus.waiting
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _CancelSheet extends StatelessWidget {
  const _CancelSheet({required this.onCancel, required this.onContinue});

  final VoidCallback onCancel;
  final VoidCallback onContinue;

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
            const Text(
              'Batalkan Analisis?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Apakah anda ingin membatalkan analisis?\nProses yang sedang berjalan akan dihentikan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Anda dapat memulai analisis ulang nanti dari halaman sebelumnya',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.chipRedText,
                side: const BorderSide(color: AppColors.chipRedText),
              ),
              child: const Text('Batalkan Analisis'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: onContinue,
              child: const Text('Lanjutkan Analisis'),
            ),
          ],
        ),
      ),
    );
  }
}
