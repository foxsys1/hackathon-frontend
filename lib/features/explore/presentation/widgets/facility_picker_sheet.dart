import 'package:flutter/material.dart';
import 'package:kos_gdgoc/core/theme/app_theme.dart';
import 'package:kos_gdgoc/features/explore/data/mock_kos_data.dart';

class FacilityPickerSheet extends StatefulWidget {
  const FacilityPickerSheet({super.key, required this.initialSelection});
  final List<String> initialSelection;

  static Future<List<String>?> show(BuildContext context,
      {required List<String> currentSelection}) {
    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FacilityPickerSheet(initialSelection: currentSelection),
    );
  }

  @override
  State<FacilityPickerSheet> createState() => _FacilityPickerSheetState();
}

class _FacilityPickerSheetState extends State<FacilityPickerSheet> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.initialSelection);
  }

  void _toggle(String f) {
    setState(() {
      _selected.contains(f) ? _selected.remove(f) : _selected.add(f);
    });
  }

  IconData _icon(String f) {
    const map = {
      'K. Mandi Dalam': Icons.shower_outlined,
      'Meja': Icons.desk_outlined,
      'Kloset Duduk': Icons.chair_outlined,
      'AC': Icons.ac_unit_outlined,
      'Lemari': Icons.checkroom_outlined,
      'Kasur': Icons.bed_outlined,
      'TV': Icons.tv_outlined,
      'Kipas Angin': Icons.wind_power_outlined,
      'Cermin': Icons.crop_square_outlined,
      'Parkir Motor': Icons.two_wheeler_outlined,
      'Parkir Mobil': Icons.directions_car_outlined,
      'Dapur': Icons.kitchen_outlined,
      'Ruang Tamu': Icons.weekend_outlined,
      'Laundry': Icons.local_laundry_service_outlined,
      'CCTV': Icons.videocam_outlined,
      'Area Merokok': Icons.smoking_rooms_outlined,
      'Kulkas': Icons.kitchen_outlined,
      'Wifi': Icons.wifi,
      'Dispenser Air Minum': Icons.water_drop_outlined,
    };
    return map[f] ?? Icons.check_box_outline_blank;
  }

  Widget _chip(String f) {
    final sel = _selected.contains(f);
    return GestureDetector(
      onTap: () => _toggle(f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: sel ? AppColors.primary : AppColors.border,
            width: sel ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon(f),
                size: 14,
                color: sel ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(f,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                  color: sel ? AppColors.primary : AppColors.textPrimary,
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Fasilitas Lainnya',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                const Text('Pilih fasilitas yang tersedia di kos',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // Scrollable chips
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Fasilitas Kamar',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: fasilitasKamar.map(_chip).toList()),
                  const SizedBox(height: 24),
                  const Text('Fasilitas Bersama',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: fasilitasBersama.map(_chip).toList()),
                  const SizedBox(height: 20),
                  if (_selected.isNotEmpty) _summaryCard(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // Footer
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _selected.clear()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        minimumSize: const Size(0, 50),
                      ),
                      child: const Text('Reset',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, _selected),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        minimumSize: const Size(0, 50),
                      ),
                      child: const Text('Simpan',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check_circle_outline,
                size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_selected.length} Fasilitas dipilih',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(_selected.join(', '),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
