import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kos_gdgoc/core/network/api_service.dart';
import 'package:kos_gdgoc/core/theme/app_theme.dart';
import 'package:kos_gdgoc/features/explore/data/kos_listing_dto.dart';
import 'package:kos_gdgoc/features/analysis/data/extracted_image_provider.dart';
import 'package:kos_gdgoc/features/analysis/domain/analysis_state.dart';
import 'package:kos_gdgoc/features/analysis/presentation/widgets/step_progress_bar.dart';

class BasicInfoPage extends ConsumerStatefulWidget {
  const BasicInfoPage({super.key});

  @override
  ConsumerState<BasicInfoPage> createState() => _BasicInfoPageState();
}

class _BasicInfoPageState extends ConsumerState<BasicInfoPage> {
  late final TextEditingController _urlCtrl;
  late final TextEditingController _namaCtrl;
  late final TextEditingController _lokasiCtrl;
  late final TextEditingController _hargaCtrl;
  late final TextEditingController _depositCtrl;
  late final TextEditingController _sumberCtrl;
  late final TextEditingController _deskripsiCtrl;

  bool _isExtracting = false;
  String? _extractError;

  String? _namaError;
  String? _lokasiError;
  String? _hargaError;

  static const _allFasilitas = [
    ('K. Mandi Dalam', Icons.bathtub_outlined),
    ('Kloset Duduk', Icons.chair_outlined),
    ('Air Panas', Icons.hot_tub_outlined),
    ('Kasur', Icons.bed_outlined),
    ('AC', Icons.ac_unit_outlined),
    ('Meja', Icons.table_restaurant_outlined),
    ('TV', Icons.tv_outlined),
    ('Kursi', Icons.event_seat_outlined),
    ('Kipas Angin', Icons.wind_power_outlined),
    ('Lemari', Icons.shelves),
    ('Wifi', Icons.wifi),
    ('Parkir Motor', Icons.two_wheeler_outlined),
  ];

  Set<String> _selectedFasilitas = {};

  @override
  void initState() {
    super.initState();
    final info = ref.read(analysisStateNotifierProvider).basicInfo;
    _urlCtrl = TextEditingController();
    _namaCtrl = TextEditingController(text: info.namaKos);
    _lokasiCtrl = TextEditingController(text: info.lokasi);
    _hargaCtrl = TextEditingController(text: info.hargaPerBulan);
    _depositCtrl = TextEditingController(text: info.deposit);
    _sumberCtrl = TextEditingController(text: info.sumberListing);
    _deskripsiCtrl = TextEditingController(text: info.deskripsi);
    _selectedFasilitas = info.fasilitas.toSet();
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _namaCtrl.dispose();
    _lokasiCtrl.dispose();
    _hargaCtrl.dispose();
    _depositCtrl.dispose();
    _sumberCtrl.dispose();
    _deskripsiCtrl.dispose();
    super.dispose();
  }

  /// Calls the extract-url API and auto-fills the form fields.
  Future<void> _extractFromUrl() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isExtracting = true;
      _extractError = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final raw = await api.extractUrl(url);
      final dto = KosListingDto.fromJson(raw);

      // Auto-fill fields from extracted data.
      setState(() {
        if (dto.listingName.isNotEmpty &&
            dto.listingName != 'Listing Tidak Diketahui') {
          _namaCtrl.text = dto.listingName;
        }
        if (dto.price > 0) {
          _hargaCtrl.text = 'Rp${_formatPrice(dto.price)}';
        }
        // Merge extracted facilities into selection.
        _selectedFasilitas.addAll(dto.roomFacilities);
        _selectedFasilitas.addAll(dto.sharedFacilities);

        // Pre-fill sumber from URL host.
        final host = Uri.tryParse(url)?.host ?? '';
        if (_sumberCtrl.text.isEmpty && host.isNotEmpty) {
          _sumberCtrl.text = host.replaceFirst('www.', '');
        }

        // Pre-fill description if available.
        if (dto.description.isNotEmpty) {
          _deskripsiCtrl.text = dto.description;
        }

        // Pre-fill lokasi: prefer API address, else try to format coords.
        if (dto.address.isNotEmpty) {
          _lokasiCtrl.text = dto.address;
        } else if (dto.latitude != null && dto.longitude != null) {
          _lokasiCtrl.text =
              'Lat ${dto.latitude!.toStringAsFixed(6)}, Lng ${dto.longitude!.toStringAsFixed(6)}';
        }

        // Ensure URL field reflects the listing URL returned by the API.
        if (_urlCtrl.text.isEmpty && dto.listingUrl.isNotEmpty) {
          _urlCtrl.text = dto.listingUrl;
        }

        // Store extracted image URL in a shared provider so history can use it.
        if (dto.imageUrl.isNotEmpty) {
          ref.read(extractedImageProvider.notifier).state = dto.imageUrl;
        }

        _isExtracting = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Data listing berhasil diekstrak!'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _isExtracting = false;
        _extractError =
            'Gagal mengekstrak URL. Pastikan URL valid dan coba lagi.';
      });
    }
  }

  String _formatPrice(int price) {
    final str = price.toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return buf.toString();
  }

  bool _validateForm() {
    final nama = _namaCtrl.text.trim();
    final lokasi = _lokasiCtrl.text.trim();
    final harga = _hargaCtrl.text.trim();

    setState(() {
      _namaError = nama.isEmpty ? 'Nama kos wajib diisi' : null;
      _lokasiError = lokasi.isEmpty ? 'Lokasi wajib diisi' : null;
      if (harga.isEmpty) {
        _hargaError = 'Harga per bulan wajib diisi';
      } else if (!RegExp(r'\d').hasMatch(harga)) {
        _hargaError = 'Masukkan angka yang valid, contoh: Rp1.500.000';
      } else {
        _hargaError = null;
      }
    });

    return _namaError == null && _lokasiError == null && _hargaError == null;
  }

  void _saveAndContinue() {
    if (!_validateForm()) return;

    final notifier = ref.read(analysisStateNotifierProvider.notifier);
    notifier.updateBasicInfo(BasicInfo(
      namaKos: _namaCtrl.text.trim(),
      lokasi: _lokasiCtrl.text.trim(),
      hargaPerBulan: _hargaCtrl.text.trim(),
      deposit: _depositCtrl.text.trim(),
      sumberListing: _sumberCtrl.text.trim(),
      deskripsi: _deskripsiCtrl.text.trim(),
      fasilitas: _selectedFasilitas.toList(),
    ));
    context.push('/analyze/quick');
  }

  @override
  Widget build(BuildContext context) {
    final extractedImage = ref.watch(extractedImageProvider);
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: const Text('Informasi Dasar'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: StepProgressBar(currentStep: 1),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi Dasar',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Lengkapi informasi dasar listing',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── URL Extraction Card ──────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome,
                                color: AppColors.primary, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              'Isi Otomatis dari URL',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tempel link listing Mamikos/Tokopedia untuk mengisi form otomatis.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _urlCtrl,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'https://mamikos.com/room/...',
                                  hintStyle: const TextStyle(fontSize: 12),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                        color:
                                            AppColors.primary.withOpacity(0.3)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                        color:
                                            AppColors.primary.withOpacity(0.3)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 44,
                              child: ElevatedButton(
                                onPressed:
                                    _isExtracting ? null : _extractFromUrl,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(0, 0),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _isExtracting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Isi',
                                        style: TextStyle(fontSize: 13)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (extractedImage.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              height: 120,
                              width: double.infinity,
                              child: Image.network(
                                extractedImage,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppColors.chipGray,
                                  child: const Center(
                                    child: Icon(Icons.broken_image,
                                        color: AppColors.iconDefault),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (_extractError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _extractError!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.chipRedText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _label('Nama Kos'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _namaCtrl,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Kos Putra Bahagia Jogja',
                      errorText: _namaError,
                    ),
                    onChanged: (_) {
                      if (_namaError != null) setState(() => _namaError = null);
                    },
                  ),
                  const SizedBox(height: 20),

                  _label('Lokasi'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _lokasiCtrl,
                    decoration: InputDecoration(
                      hintText:
                          'Contoh: Jl. Kaliurang KM 5, Sleman, Yogyakarta',
                      prefixIcon:
                          const Icon(Icons.location_on_outlined, size: 20),
                      errorText: _lokasiError,
                    ),
                    onChanged: (_) {
                      if (_lokasiError != null)
                        setState(() => _lokasiError = null);
                    },
                  ),
                  const SizedBox(height: 20),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Harga/bulan'),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _hargaCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Contoh: Rp1.500.000',
                                errorText: _hargaError,
                              ),
                              onChanged: (_) {
                                if (_hargaError != null)
                                  setState(() => _hargaError = null);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('DP'),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _depositCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'Contoh: Rp500.000 (jika ada)',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _label('Sumber Listing'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _sumberCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Contoh: Mamikos, OLX, Instagram, WhatsApp',
                    ),
                  ),
                  const SizedBox(height: 20),

                  _label('Deskripsi'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _deskripsiCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText:
                          'Contoh: Kos nyaman dekat UGM, fasilitas lengkap, lingkungan bersih dan aman, cocok untuk mahasiswa.',
                    ),
                  ),
                  const SizedBox(height: 24),

                  _label('Fasilitas Kos'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _allFasilitas.map((f) {
                      final selected = _selectedFasilitas.contains(f.$1);
                      return _FasilitasChip(
                        label: f.$1,
                        icon: f.$2,
                        selected: selected,
                        onTap: () {
                          setState(() {
                            if (selected) {
                              _selectedFasilitas.remove(f.$1);
                            } else {
                              _selectedFasilitas.add(f.$1);
                            }
                          });
                        },
                      );
                    }).toList(),
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

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      );
}

class _FasilitasChip extends StatelessWidget {
  const _FasilitasChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
