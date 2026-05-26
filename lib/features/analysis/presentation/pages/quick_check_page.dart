import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kos_gdgoc/core/theme/app_theme.dart';
import 'package:kos_gdgoc/features/analysis/domain/analysis_state.dart';
import 'package:kos_gdgoc/features/analysis/presentation/widgets/step_progress_bar.dart';

class QuickCheckPage extends ConsumerStatefulWidget {
  const QuickCheckPage({super.key, this.isEditMode = false});

  final bool isEditMode;

  @override
  ConsumerState<QuickCheckPage> createState() => _QuickCheckPageState();
}

class _QuickCheckPageState extends ConsumerState<QuickCheckPage> {
  late QuickCheck _qc;
  late final TextEditingController _mapsCtrl;
  late final TextEditingController _kontakCtrl;
  late final TextEditingController _rekeningCtrl;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _qc = ref.read(analysisStateNotifierProvider).quickCheck;
    _mapsCtrl = TextEditingController(text: _qc.googleMapsLink);
    _kontakCtrl = TextEditingController(text: _qc.namaKontak);
    _rekeningCtrl = TextEditingController(text: _qc.namaRekening);
  }

  @override
  void dispose() {
    _mapsCtrl.dispose();
    _kontakCtrl.dispose();
    _rekeningCtrl.dispose();
    super.dispose();
  }

  void _save() {
    ref.read(analysisStateNotifierProvider.notifier).updateQuickCheck(
          _qc.copyWith(
            googleMapsLink: _mapsCtrl.text,
            namaKontak: _kontakCtrl.text,
            namaRekening: _rekeningCtrl.text,
          ),
        );
  }

  void _goDeepCheck() {
    _save();
    context.push('/analyze/deep');
  }

  void _skipToOverview() {
    _save();
    context.push('/analyze/overview');
  }

  void _saveEdits() {
    _save();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.isEditMode;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Quick Check'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: StepProgressBar(currentStep: 2),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bantu Kami Memahami Listing Anda',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Jawab pertanyaan berikut untuk membantu mengevaluasi tingkat risiko.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),

                  // Q1 — Foto & Video
                  _QuestionCard(
                    number: 1,
                    question: 'Apakah ada foto dan video yang diberikan?',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TriToggle(
                          value: _qc.hasPhotos,
                          labels: const ['Ada', 'Hanya foto saja', 'Tidak'],
                          values: const [TriAnswer.ya, TriAnswer.tidakTahu, TriAnswer.tidak],
                          onChanged: (v) => setState(() => _qc = _qc.copyWith(hasPhotos: v)),
                        ),
                        if (_qc.hasPhotos == TriAnswer.ya ||
                            _qc.hasPhotos == TriAnswer.tidakTahu) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Unggah foto/video (opsional)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Unggah bukti foto/video dari listing (maks. 5 file)',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          _UploadBox(
                            label: 'Pilih foto',
                            subtitle: 'PNG, JPG — Maks. 5 foto',
                            onTap: () async {
                              if (_qc.uploadedPhotoPaths.length >= 5) return;
                              final images = await _picker.pickMultiImage(
                                imageQuality: 80,
                              );
                              if (images.isNotEmpty) {
                                final remaining = 5 - _qc.uploadedPhotoPaths.length;
                                setState(() {
                                  _qc = _qc.copyWith(
                                    uploadedPhotoPaths: [
                                      ..._qc.uploadedPhotoPaths,
                                      ...images.take(remaining).map((x) => x.path),
                                    ],
                                  );
                                });
                              }
                            },
                          ),
                          if (_qc.uploadedPhotoPaths.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _FileChipRow(
                              paths: _qc.uploadedPhotoPaths,
                              onRemove: (p) => setState(() {
                                _qc = _qc.copyWith(
                                  uploadedPhotoPaths:
                                      _qc.uploadedPhotoPaths.where((x) => x != p).toList(),
                                );
                              }),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Q2 — Alamat
                  _QuestionCard(
                    number: 2,
                    question: 'Apakah alamat yang diberikan spesifik dan dapat ditelusuri melalui Maps?',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TriToggle(
                          value: _qc.addressSpecific,
                          labels: const ['Ya', 'Tidak'],
                          values: const [TriAnswer.ya, TriAnswer.tidak],
                          onChanged: (v) => setState(() => _qc = _qc.copyWith(addressSpecific: v)),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Masukkan tautan lokasi dari Google Maps (opsional)',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tambahkan lokasi agar alamat lebih mudah diverifikasi',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _mapsCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Contoh: https://maps.app.goo.gl/xyzABC',
                            prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Q3 — Kontak
                  _QuestionCard(
                    number: 3,
                    question: 'Siapa nama kontak yang anda hubungi?',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TriToggle(
                          value: _qc.knowsContactName,
                          labels: const ['Saya tahu', 'Tidak tahu'],
                          values: const [TriAnswer.ya, TriAnswer.tidakTahu],
                          onChanged: (v) => setState(() => _qc = _qc.copyWith(knowsContactName: v)),
                        ),
                        if (_qc.knowsContactName == TriAnswer.ya) ...[
                          const SizedBox(height: 12),
                          _subLabel('Nama Kontak'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _kontakCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Contoh: Budi Santoso',
                              prefixIcon: Icon(Icons.person_outline, size: 18),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Q4 — Rekening
                  _QuestionCard(
                    number: 4,
                    question: 'Siapa nama yang tertera di rekening bank untuk transfer DP?',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TriToggle(
                          value: _qc.knowsAccountName,
                          labels: const ['Saya tahu', 'Tidak tahu'],
                          values: const [TriAnswer.ya, TriAnswer.tidakTahu],
                          onChanged: (v) => setState(() => _qc = _qc.copyWith(knowsAccountName: v)),
                        ),
                        if (_qc.knowsAccountName == TriAnswer.ya) ...[
                          const SizedBox(height: 12),
                          _subLabel('Nama di Rekening Bank'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _rekeningCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Contoh: Siti Rahayu',
                              prefixIcon: Icon(Icons.account_balance_outlined, size: 18),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Q5 — Video call
                  _QuestionCard(
                    number: 5,
                    question: 'Apakah pemilik bersedia melakukan video call/mengizinkan survei untuk menunjukkan kondisi kamar sebelum transfer DP?',
                    child: _TriToggle(
                      value: _qc.videoCallAvailable,
                      labels: const ['Ya', 'Tidak'],
                      values: const [TriAnswer.ya, TriAnswer.tidak],
                      onChanged: (v) => setState(() => _qc = _qc.copyWith(videoCallAvailable: v)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Q6 — Tekanan transfer
                  _QuestionCard(
                    number: 6,
                    question: 'Apakah pemilik menekan anda untuk melakukan transfer dalam waktu singkat?',
                    child: _TriToggle(
                      value: _qc.transferPressure,
                      labels: const ['Ya', 'Sedikit', 'Tidak'],
                      values: const [TriAnswer.ya, TriAnswer.tidakTahu, TriAnswer.tidak],
                      onChanged: (v) => setState(() => _qc = _qc.copyWith(transferPressure: v)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Q7 — Testimoni
                  _QuestionCard(
                    number: 7,
                    question: 'Apakah ada testimoni dari pengguna sebelumnya?',
                    child: _TriToggle(
                      value: _qc.hasTestimony,
                      labels: const ['Ya', 'Tidak'],
                      values: const [TriAnswer.ya, TriAnswer.tidak],
                      onChanged: (v) => setState(() => _qc = _qc.copyWith(hasTestimony: v)),
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
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: isEdit
                  ? ElevatedButton(
                      onPressed: _saveEdits,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Simpan Perubahan'),
                          SizedBox(width: 8),
                          Icon(Icons.save_outlined, size: 18),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: _goDeepCheck,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.manage_search, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Lanjutkan dengan Deep Check',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: _skipToOverview,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Lanjutkan'),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      );
}


class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.number,
    required this.question,
    required this.child,
  });

  final int number;
  final String question;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.4,
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

class _TriToggle extends StatelessWidget {
  const _TriToggle({
    required this.value,
    required this.labels,
    required this.values,
    required this.onChanged,
  });

  final TriAnswer? value;
  final List<String> labels;
  final List<TriAnswer> values;
  final ValueChanged<TriAnswer> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(labels.length, (i) {
        final selected = value == values[i];
        return GestureDetector(
          onTap: () => onChanged(values[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Text(
              labels[i],
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _UploadBox extends StatelessWidget {
  const _UploadBox({
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary, width: 1.5),
          color: AppColors.primary.withOpacity(0.04),
        ),
        child: Column(
          children: [
            Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileChipRow extends StatelessWidget {
  const _FileChipRow({required this.paths, required this.onRemove});

  final List<String> paths;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: paths.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(paths[i]),
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 72,
                    height: 72,
                    color: AppColors.chipGray,
                    child: const Icon(Icons.image, color: AppColors.iconDefault, size: 28),
                  ),
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () => onRemove(paths[i]),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: AppColors.textPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
