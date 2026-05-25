import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kos_gdgoc/core/network/api_service.dart';
import 'package:kos_gdgoc/core/theme/app_theme.dart';
import 'package:kos_gdgoc/features/analysis/data/analysis_repository_impl.dart';
import 'package:kos_gdgoc/features/analysis/data/models/validation_result_dto.dart';
import 'package:kos_gdgoc/features/analysis/domain/analysis_state.dart';
import 'package:kos_gdgoc/features/history/data/history_provider.dart';
import 'package:kos_gdgoc/features/history/domain/history_record.dart';

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

    _runApiCall();
  }

  Future<void> _runApiCall() async {
    // Show the UI for at least 3.2 seconds regardless of API speed.
    final minDisplay = Future<void>.delayed(const Duration(milliseconds: 3200));

    try {
      final analysisState = ref.read(analysisStateNotifierProvider);
      final api = ref.read(apiServiceProvider);
      final repo = AnalysisRepositoryImpl(api);

      // Run API + minimum display time in parallel.
      final results = await Future.wait<dynamic>([
        repo.validateListing(analysisState),
        minDisplay,
      ]);

      if (!mounted || _cancelled) return;

      // Mark all steps done.
      _stepTimer?.cancel();
      setState(() {
        for (int i = 0; i < _statuses.length; i++) {
          _statuses[i] = _StepStatus.done;
        }
      });

      final raw = results[0] as Map<String, dynamic>;
      final result = ValidationResultDto.fromJson(raw).toDomain();
      ref.read(analysisStateNotifierProvider.notifier).setResult(result);

      // Persist result to in-session history.
      final riskLevel = result.riskScore >= 70
          ? RiskLevel.tinggi
          : result.riskScore >= 40
              ? RiskLevel.sedang
              : RiskLevel.rendah;
      final historyRecord = HistoryRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        namaKos: analysisState.basicInfo.namaKos.isNotEmpty
            ? analysisState.basicInfo.namaKos
            : 'Kos Tidak Diketahui',
        lokasi: analysisState.basicInfo.lokasi,
        hargaPerBulan: analysisState.basicInfo.hargaPerBulan.isNotEmpty
            ? analysisState.basicInfo.hargaPerBulan
            : '-',
        sumberListing: analysisState.basicInfo.sumberListing,
        imageUrl: '',
        riskScore: result.riskScore,
        riskLevel: riskLevel,
        analysisDate: DateTime.now(),
        confidenceScore: result.confidenceScore,
        confidenceHint: result.confidenceHint,
        riskDescription: result.riskDescription,
        redFlags: result.redFlags,
        recommendations: result.recommendations,
        areaComparison: result.areaComparison,
      );
      ref.read(historyNotifierProvider.notifier).addRecord(historyRecord);

      context.go('/analyze/result');
    } catch (e) {
      await minDisplay; // Still wait for minimum display even on error.
      if (!mounted || _cancelled) return;
      _stepTimer?.cancel();
      _showApiError(_friendlyError(e));
    }
  }

  String _friendlyError(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      if (status == 422) {
        final detail = e.response?.data?['detail'];
        if (detail != null) {
          return 'Data tidak valid (422): $detail';
        }
        return 'Data tidak valid (422). Periksa kelengkapan informasi dan coba lagi.';
      }
      if (status != null) {
        return 'Server error ($status). Coba lagi beberapa saat.';
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Koneksi timeout. Periksa internet Anda dan coba lagi.';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      }
    }
    return 'Terjadi kesalahan tidak terduga. Coba lagi.';
  }

  void _showApiError(String message) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ErrorSheet(
        message: message,
        onDismiss: () {
          Navigator.pop(context);
          context.go('/analyze/overview');
        },
      ),
    );
  }

  void _showCancelDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
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
                              backgroundColor:
                                  AppColors.border.withOpacity(0.3),
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

class _ErrorSheet extends StatelessWidget {
  const _ErrorSheet({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

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
              child: Icon(Icons.error_outline,
                  color: AppColors.chipRedText, size: 28),
            ),
            const SizedBox(height: 16),
            const Text(
              'Analisis Gagal',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onDismiss,
              child: const Text('Kembali ke Overview'),
            ),
          ],
        ),
      ),
    );
  }
}
