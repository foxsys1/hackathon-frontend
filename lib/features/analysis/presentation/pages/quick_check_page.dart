import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kos_gdgoc/core/theme/app_theme.dart';
import 'package:kos_gdgoc/features/analysis/domain/analysis_state.dart';
import 'package:kos_gdgoc/features/analysis/domain/upload_state.dart';
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
    final uploads = ref.watch(uploadStateProvider);

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
                    style:
                        TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),

                  // Foto Upload Section (moved to top)
                  const Text(
                    'Unggah Foto/Video Listing (Opsional)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Unggah bukti foto/video dari listing (maks. 5 file)',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  _UploadBox(
                    label: 'Pilih foto',
                    subtitle: 'PNG, JPG — Maks. 5 foto',
                    onTap: () async {
                      if (uploads.quickCheckImages.length >= 5) return;
                      final images = await _picker.pickMultiImage(
                        imageQuality: 80,
                      );
                      if (!mounted) return;
                      if (images.isEmpty) return;

                      final remaining = 5 - uploads.quickCheckImages.length;
                      final notifier = ref.read(uploadStateProvider.notifier);
                      final newPaths = <String>[];

                      for (final image in images.take(remaining)) {
                        final bytes = kIsWeb ? await image.readAsBytes() : null;
                        notifier.addQuickCheckImage(
                          UploadItem(
                            id: UploadItem.newId(),
                            name: image.name,
                            kind: UploadKind.image,
                            bytes: bytes,
                            path: kIsWeb ? null : image.path,
                          ),
                        );
                        if (!kIsWeb && image.path.isNotEmpty) {
                          newPaths.add(image.path);
                        }
                      }

                      if (!kIsWeb && newPaths.isNotEmpty) {
                        setState(() {
                          _qc = _qc.copyWith(
                            uploadedPhotoPaths: [
                              ..._qc.uploadedPhotoPaths,
                              ...newPaths,
                            ],
                          );
                        });
                      }
                    },
                  ),
                  if (uploads.quickCheckImages.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _FileChipRow(
                      items: uploads.quickCheckImages,
                      onRemove: (item) {
                        ref
                            .read(uploadStateProvider.notifier)
                            .removeQuickCheckImage(item.id);
                        if (!kIsWeb && item.path != null) {
                          setState(() {
                            _qc = _qc.copyWith(
                              uploadedPhotoPaths: _qc.uploadedPhotoPaths
                                  .where((x) => x != item.path)
                                  .toList(),
                            );
                          });
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Q1
                  _QuestionCard(
                    number: 1,
                    question:
                        'Apakah alamat kos yang diberikan spesifik dan dapat ditelusuri melalui Google Maps atau Peta Lainnya?',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _GenericToggle<Q1AddressAnswer>(
                          value: _qc.addressSpecific,
                          labels: const [
                            'Ya, spesifik & bisa di-Maps',
                            'Hanya alamat (tanpa Maps)',
                            'Hanya area (cth: dekat UGM)'
                          ],
                          values: const [
                            Q1AddressAnswer.ya,
                            Q1AddressAnswer.hanyaAlamat,
                            Q1AddressAnswer.hanyaArea
                          ],
                          onChanged: (v) => setState(
                              () => _qc = _qc.copyWith(addressSpecific: v)),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Masukkan tautan lokasi dari Google Maps (opsional)',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _mapsCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Contoh: https://maps.app.goo.gl/xyzABC',
                            prefixIcon:
                                Icon(Icons.location_on_outlined, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Q2
                  _QuestionCard(
                    number: 2,
                    question:
                        'Apakah foto bangunan/kamar yang diberikan sesuai dengan lokasi kos? (Jika dibandingkan melalui Google Maps/ Street View/ Lokasi sekitar)',
                    child: _GenericToggle<TriAnswer>(
                      value: _qc.photoMatchLocation,
                      labels: const [
                        'Ya, sesuai',
                        'Belum bisa dipastikan',
                        'Tidak sesuai'
                      ],
                      values: const [
                        TriAnswer.ya,
                        TriAnswer.tidakTahu,
                        TriAnswer.tidak
                      ],
                      onChanged: (v) => setState(
                          () => _qc = _qc.copyWith(photoMatchLocation: v)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Q3
                  _QuestionCard(
                    number: 3,
                    question:
                        'Apakah informasi fasilitas, harga, dan aturan kos dijelaskan secara konsisten dari awal?',
                    child: _GenericToggle<TriAnswer>(
                      value: _qc.infoConsistent,
                      labels: const [
                        'Ya, konsisten',
                        'Tidak, ada perubahan informasi',
                        'Tidak tahu'
                      ],
                      values: const [
                        TriAnswer.ya,
                        TriAnswer.tidak,
                        TriAnswer.tidakTahu
                      ],
                      onChanged: (v) =>
                          setState(() => _qc = _qc.copyWith(infoConsistent: v)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Q4
                  _QuestionCard(
                    number: 4,
                    question:
                        'Apakah pengelola mengizinkan survei langsung atau video call di lokasi kos?',
                    child: _GenericToggle<TriAnswer>(
                      value: _qc.surveyOrVideoCallAllowed,
                      labels: const ['Ya', 'Tidak'],
                      values: const [TriAnswer.ya, TriAnswer.tidak],
                      onChanged: (v) => setState(() =>
                          _qc = _qc.copyWith(surveyOrVideoCallAllowed: v)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Q5
                  _QuestionCard(
                    number: 5,
                    question:
                        'Jika ya, Apakah pengelola meminta untuk melakukan DP terlebih dahulu?',
                    child: _GenericToggle<TriAnswer>(
                      value: _qc.dpRequestedBeforeSurvey,
                      labels: const ['Ya, diminta DP dulu', 'Tidak'],
                      values: const [TriAnswer.ya, TriAnswer.tidak],
                      onChanged: (v) => setState(
                          () => _qc = _qc.copyWith(dpRequestedBeforeSurvey: v)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Q6
                  _QuestionCard(
                    number: 6,
                    question:
                        'Apakah pengelola menekan Anda untuk segera transfer DP dengan alasan kamar hampir habis atau banyak peminat?',
                    child: _GenericToggle<TriAnswer>(
                      value: _qc.pressureToTransfer,
                      labels: const ['Ya, ada tekanan', 'Tidak'],
                      values: const [TriAnswer.ya, TriAnswer.tidak],
                      onChanged: (v) => setState(
                          () => _qc = _qc.copyWith(pressureToTransfer: v)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Q7
                  _QuestionCard(
                    number: 7,
                    question:
                        'Apakah pengelola bersedia mengirim video terbaru sesuai permintaan?',
                    child: _GenericToggle<Q7VideoAnswer>(
                      value: _qc.willingToProvideVideo,
                      labels: const [
                        'Ya, bersedia',
                        'Hanya video lama',
                        'Tidak bersedia'
                      ],
                      values: const [
                        Q7VideoAnswer.ya,
                        Q7VideoAnswer.hanyaVideoLama,
                        Q7VideoAnswer.tidak
                      ],
                      onChanged: (v) => setState(
                          () => _qc = _qc.copyWith(willingToProvideVideo: v)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Q8
                  _QuestionCard(
                    number: 8,
                    question:
                        'Apakah nomor WhatsApp atau kontak pengelola menggunakan identitas yang konsisten dengan nama yang tertera pada rekening?',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _GenericToggle<TriAnswer>(
                          value: _qc.identityConsistent,
                          labels: const [
                            'Ya, konsisten',
                            'Tidak konsisten',
                            'Tidak tahu / belum bisa dipastikan'
                          ],
                          values: const [
                            TriAnswer.ya,
                            TriAnswer.tidak,
                            TriAnswer.tidakTahu
                          ],
                          onChanged: (v) => setState(
                              () => _qc = _qc.copyWith(identityConsistent: v)),
                        ),
                        if (_qc.identityConsistent == TriAnswer.ya) ...[
                          const SizedBox(height: 16),
                          _subLabel('Nama Kontak'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _kontakCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Contoh: Budi Santoso',
                              prefixIcon: Icon(Icons.person_outline, size: 18),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _subLabel('Nama di Rekening Bank'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _rekeningCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Contoh: Siti Rahayu',
                              prefixIcon: Icon(Icons.account_balance_outlined,
                                  size: 18),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Q9
                  _QuestionCard(
                    number: 9,
                    question:
                        'Apakah pengelola menjelaskan rincian pembayaran sebelum meminta transfer?',
                    child: _GenericToggle<Q9PaymentAnswer>(
                      value: _qc.paymentDetailsClear,
                      labels: const [
                        'Ya, jelas lengkap',
                        'Sebagian dijelaskan',
                        'Tidak dijelaskan, hanya diminta transfer',
                        'Belum sampai tahap pembayaran'
                      ],
                      values: const [
                        Q9PaymentAnswer.jelas,
                        Q9PaymentAnswer.sebagian,
                        Q9PaymentAnswer.tidakDijelaskan,
                        Q9PaymentAnswer.belumTahap
                      ],
                      onChanged: (v) => setState(
                          () => _qc = _qc.copyWith(paymentDetailsClear: v)),
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

class _GenericToggle<T> extends StatelessWidget {
  const _GenericToggle({
    required this.value,
    required this.labels,
    required this.values,
    required this.onChanged,
  });

  final T? value;
  final List<String> labels;
  final List<T> values;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(labels.length, (i) {
        final selected = value == values[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => onChanged(selected ? null : values[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? AppColors.primary : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? Colors.white : Colors.transparent,
                      border: Border.all(
                        color:
                            selected ? Colors.white : const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                    ),
                    child: selected
                        ? Center(
                            child: Icon(
                              Icons.check_rounded,
                              size: 11,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                        color:
                            selected ? Colors.white : const Color(0xFF374151),
                        letterSpacing: 0.0,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
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
            Icon(Icons.cloud_upload_outlined,
                color: AppColors.primary, size: 28),
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
              style:
                  const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileChipRow extends StatelessWidget {
  const _FileChipRow({required this.items, required this.onRemove});

  final List<UploadItem> items;
  final ValueChanged<UploadItem> onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final item = items[i];
          final preview = item.hasBytes
              ? Image.memory(
                  item.bytes!,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 72,
                    height: 72,
                    color: AppColors.chipGray,
                    child: const Icon(
                      Icons.image,
                      color: AppColors.iconDefault,
                      size: 28,
                    ),
                  ),
                )
              : (!kIsWeb && item.path != null)
                  ? Image.file(
                      File(item.path!),
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 72,
                        height: 72,
                        color: AppColors.chipGray,
                        child: const Icon(
                          Icons.image,
                          color: AppColors.iconDefault,
                          size: 28,
                        ),
                      ),
                    )
                  : Container(
                      width: 72,
                      height: 72,
                      color: AppColors.chipGray,
                      child: const Icon(
                        Icons.image,
                        color: AppColors.iconDefault,
                        size: 28,
                      ),
                    );
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: preview,
              ),
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () => onRemove(item),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: AppColors.textPrimary,
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.close, color: Colors.white, size: 14),
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
