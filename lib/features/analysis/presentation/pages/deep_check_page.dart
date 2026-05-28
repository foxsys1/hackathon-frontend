import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kos_gdgoc/core/theme/app_theme.dart';
import 'package:kos_gdgoc/features/analysis/domain/analysis_state.dart';
import 'package:kos_gdgoc/features/analysis/domain/upload_state.dart';

import 'package:kos_gdgoc/features/analysis/presentation/widgets/step_progress_bar.dart';

class DeepCheckPage extends ConsumerStatefulWidget {
  const DeepCheckPage({super.key});

  @override
  ConsumerState<DeepCheckPage> createState() => _DeepCheckPageState();
}

class _DeepCheckPageState extends ConsumerState<DeepCheckPage> {
  late DeepCheck _dc;
  final _picker = ImagePicker();
  bool _waExportExpanded = false;

  @override
  void initState() {
    super.initState();
    _dc = ref.read(analysisStateNotifierProvider).deepCheck;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _saveAndContinue() {
    ref.read(analysisStateNotifierProvider.notifier).updateDeepCheck(_dc);
    context.push('/analyze/overview');
  }

  void _pickWhatsappChat() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'zip'],
      allowMultiple: false,
      withData: kIsWeb,
    );
    if (!mounted) return;
    final file = result?.files.isNotEmpty == true ? result!.files.first : null;
    if (file == null) return;
    if (kIsWeb && file.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File tidak dapat dibaca di web. Coba file lain.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final item = UploadItem(
      id: UploadItem.newId(),
      name: file.name,
      kind: UploadKind.chat,
      bytes: kIsWeb ? file.bytes : null,
      path: kIsWeb ? null : file.path,
    );
    ref.read(uploadStateProvider.notifier).addWhatsappChat(item);

    if (!kIsWeb && file.path != null) {
      setState(() {
        _dc = _dc.copyWith(
          whatsappChatPaths: [..._dc.whatsappChatPaths, file.path!],
        );
      });
    }
  }

  void _pickScreenshot() async {
    final uploads = ref.read(uploadStateProvider);
    if (uploads.testimoniImages.length >= 5) return;
    final images = await _picker.pickMultiImage(imageQuality: 80);
    if (!mounted) return;
    if (images.isEmpty) return;

    final remaining = 5 - uploads.testimoniImages.length;
    final notifier = ref.read(uploadStateProvider.notifier);
    final newPaths = <String>[];

    for (final image in images.take(remaining)) {
      final bytes = kIsWeb ? await image.readAsBytes() : null;
      notifier.addTestimoniImage(
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
        _dc = _dc.copyWith(
          testimoniScreenshotPaths: [
            ..._dc.testimoniScreenshotPaths,
            ...newPaths,
          ],
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploads = ref.watch(uploadStateProvider);
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Deep Check'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: StepProgressBar(currentStep: 2),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info banner
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
                                'Apa itu Deep Check?',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tahap ini membantu kami memastikan keaslian data dan menilai potensi risiko lebih mendalam berdasarkan bukti dan pola komunikasi.',
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
                  const SizedBox(height: 24),

                  // Section 1 — WhatsApp chat export
                  _SectionCard(
                    number: 1,
                    title: 'Export Chat Whatsapp',
                    subtitle: 'Export seluruh chat dengan pemilik kos.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _UploadBox(
                          label: 'Upload file chat Whatsapp',
                          subtitle: '.TXT atau .ZIP — Maks. 20MB per file',
                          onTap: _pickWhatsappChat,
                        ),
                        if (uploads.whatsappChats.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _FileChipRow(
                            items: uploads.whatsappChats,
                            icon: Icons.description_outlined,
                            onRemove: (item) {
                              ref
                                  .read(uploadStateProvider.notifier)
                                  .removeWhatsappChat(item.id);
                              if (!kIsWeb && item.path != null) {
                                setState(() {
                                  _dc = _dc.copyWith(
                                    whatsappChatPaths: _dc.whatsappChatPaths
                                        .where((x) => x != item.path)
                                        .toList(),
                                  );
                                });
                              }
                            },
                          ),
                        ],
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => setState(
                              () => _waExportExpanded = !_waExportExpanded),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.chipGray,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline,
                                    size: 18, color: AppColors.textSecondary),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Cara Export Chat Whatsapp',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Icon(
                                  _waExportExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_waExportExpanded) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.chipGray,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '1. Buka chat WhatsApp dengan pemilik kos\n'
                              '2. Ketuk menu (⋮) di pojok kanan atas\n'
                              '3. Pilih "Lainnya" → "Ekspor chat"\n'
                              '4. Pilih "Tanpa Media"\n'
                              '5. Simpan atau bagikan file .txt',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 2 — Screenshots Testimoni
                  _SectionCard(
                    number: 2,
                    title: 'Screenshot Testimoni Pengguna Lain',
                    subtitle:
                        'Kirim bukti testimoni atau review dari pengguna lain.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _UploadBox(
                          label: 'Upload screenshot',
                          subtitle: 'PNG, JPG — Maks 5 file — 20MB per file',
                          onTap: _pickScreenshot,
                        ),
                        if (uploads.testimoniImages.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _FileChipRow(
                            items: uploads.testimoniImages,
                            isImage: true,
                            onRemove: (item) {
                              ref
                                  .read(uploadStateProvider.notifier)
                                  .removeTestimoniImage(item.id);
                              if (!kIsWeb && item.path != null) {
                                setState(() {
                                  _dc = _dc.copyWith(
                                    testimoniScreenshotPaths: _dc
                                        .testimoniScreenshotPaths
                                        .where((x) => x != item.path)
                                        .toList(),
                                  );
                                });
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: ElevatedButton(
                onPressed: _saveAndContinue,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Lanjutkan'),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final int number;
  final String title;
  final String subtitle;
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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
          const SizedBox(height: 16),
          child,
        ],
      ),
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
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary, width: 1.5),
          color: AppColors.primary.withOpacity(0.04),
        ),
        child: Column(
          children: [
            Icon(Icons.cloud_upload_outlined,
                color: AppColors.primary, size: 30),
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
  const _FileChipRow({
    required this.items,
    required this.onRemove,
    this.icon = Icons.image,
    this.isImage = false,
  });

  final List<UploadItem> items;
  final ValueChanged<UploadItem> onRemove;
  final IconData icon;
  final bool isImage;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(items.length, (i) {
        final item = items[i];
        final imagePreview = item.hasBytes
            ? Image.memory(
                item.bytes!,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 72,
                  height: 72,
                  color: AppColors.chipGray,
                  child: Icon(icon, color: AppColors.iconDefault, size: 28),
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
                      child: Icon(icon, color: AppColors.iconDefault, size: 28),
                    ),
                  )
                : Container(
                    width: 72,
                    height: 72,
                    color: AppColors.chipGray,
                    child: Icon(icon, color: AppColors.iconDefault, size: 28),
                  );
        return SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            children: [
              if (isImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imagePreview,
                )
              else
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.chipGray,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(icon, color: AppColors.iconDefault, size: 28),
                  ),
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
          ),
        );
      }),
    );
  }
}
