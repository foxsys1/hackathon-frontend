import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kos_gdgoc/core/theme/app_theme.dart';
import 'package:kos_gdgoc/features/analysis/domain/analysis_state.dart';
import 'package:kos_gdgoc/features/analysis/presentation/widgets/step_progress_bar.dart';

class BasicInfoPage extends ConsumerStatefulWidget {
  const BasicInfoPage({super.key});

  @override
  ConsumerState<BasicInfoPage> createState() => _BasicInfoPageState();
}

class _BasicInfoPageState extends ConsumerState<BasicInfoPage> {
  late final TextEditingController _namaCtrl;
  late final TextEditingController _lokasiCtrl;
  late final TextEditingController _hargaCtrl;
  late final TextEditingController _depositCtrl;
  late final TextEditingController _sumberCtrl;
  late final TextEditingController _deskripsiCtrl;

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
    _namaCtrl.dispose();
    _lokasiCtrl.dispose();
    _hargaCtrl.dispose();
    _depositCtrl.dispose();
    _sumberCtrl.dispose();
    _deskripsiCtrl.dispose();
    super.dispose();
  }

  void _saveAndContinue() {
    final notifier = ref.read(analysisStateNotifierProvider.notifier);
    notifier.updateBasicInfo(BasicInfo(
      namaKos: _namaCtrl.text,
      lokasi: _lokasiCtrl.text,
      hargaPerBulan: _hargaCtrl.text,
      deposit: _depositCtrl.text,
      sumberListing: _sumberCtrl.text,
      deskripsi: _deskripsiCtrl.text,
      fasilitas: _selectedFasilitas.toList(),
    ));
    context.push('/analyze/quick');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
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

                  _label('Nama Kos'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _namaCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Kos Putra Senja Ayu',
                    ),
                  ),
                  const SizedBox(height: 20),

                  _label('Lokasi'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _lokasiCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Pogung Baru Blok AIV No.10, Sleman',
                      prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
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
                              decoration: const InputDecoration(
                                hintText: 'Rp1.500.000',
                              ),
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
                                hintText: 'Rp1.500.000',
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
                      hintText: 'Mamikos',
                    ),
                  ),
                  const SizedBox(height: 20),

                  _label('Deskripsi'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _deskripsiCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Kos Eksklusif dekat kampus bla bla bladhd',
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
          color: selected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.white,
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
