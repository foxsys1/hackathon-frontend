import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kos_gdgoc/core/theme/app_theme.dart';
import 'package:kos_gdgoc/features/explore/domain/explore_filter_state.dart';
import 'package:kos_gdgoc/features/explore/data/mock_kos_data.dart';
import 'package:kos_gdgoc/features/explore/presentation/widgets/location_picker_sheet.dart';
import 'package:kos_gdgoc/features/explore/presentation/widgets/facility_picker_sheet.dart';

class ExploreFilterSheet extends ConsumerStatefulWidget {
  const ExploreFilterSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => const ExploreFilterSheet(),
    );
  }

  @override
  ConsumerState<ExploreFilterSheet> createState() => _ExploreFilterSheetState();
}

class _ExploreFilterSheetState extends ConsumerState<ExploreFilterSheet> {
  late TextEditingController _minCtrl;
  late TextEditingController _maxCtrl;
  late List<String> _locations;
  late List<String> _facilities;
  double? _minRating;
  late SortMetric _sortBy;

  @override
  void initState() {
    super.initState();
    final s = ref.read(exploreFilterNotifierProvider);
    _minCtrl = TextEditingController(text: s.priceMin.toString());
    _maxCtrl = TextEditingController(text: s.priceMax.toString());
    _locations = List.from(s.selectedLocations);
    _facilities = List.from(s.selectedFacilities);
    _minRating = s.minimumRating;
    _sortBy = s.sortBy;
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    final n = ref.read(exploreFilterNotifierProvider.notifier);
    n.setPriceRange(
      int.tryParse(_minCtrl.text) ?? 300000,
      int.tryParse(_maxCtrl.text) ?? 2500000,
    );
    n.setLocations(_locations);
    n.setFacilities(_facilities);
    n.setMinimumRating(_minRating);
    n.setSortBy(_sortBy);
    Navigator.pop(context);
  }

  void _reset() {
    setState(() {
      _minCtrl.text = '300000';
      _maxCtrl.text = '2500000';
      _locations.clear();
      _facilities.clear();
      _minRating = null;
      _sortBy = SortMetric.terdekat;
    });
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
                      borderRadius: BorderRadius.circular(2)),
                )),
                const SizedBox(height: 20),
                const Text('Filter Eksplor',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Scrollable body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Harga ──
                  const Text('Harga',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _priceField(_minCtrl, 'Rp 300.000')),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('–',
                          style: TextStyle(
                              fontSize: 16, color: AppColors.textSecondary)),
                    ),
                    Expanded(child: _priceField(_maxCtrl, 'Rp 2.500.000')),
                  ]),
                  const SizedBox(height: 24),

                  // ── Lokasi ──
                  const Text('Lokasi',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...availableLocations.take(5).map((l) => _locChip(l)),
                      GestureDetector(
                        onTap: () async {
                          final r = await LocationPickerSheet.show(context,
                              currentSelection: _locations);
                          if (r != null)
                            setState(() => _locations
                              ..clear()
                              ..addAll(r));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary),
                          ),
                          child: const Text('+ Lainnya',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Fasilitas Kamar ──
                  const Text('Fasilitas Kamar',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  if (_facilities.isNotEmpty) ...[
                    _facilitySummary(),
                    const SizedBox(height: 10),
                  ],
                  _facilityExpandButton(),
                  const SizedBox(height: 24),

                  // ── Rating Minimum ──
                  const Text('Rating Minimum',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _ratingChip(3.5),
                    _ratingChip(4.0),
                    _ratingChip(4.5),
                  ]),
                  const SizedBox(height: 24),

                  // ── Urutkan ──
                  const Text('Urutkan Berdasarkan',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: SortMetric.values.map(_sortChip).toList()),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Footer
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _reset,
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
                    onPressed: _apply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      minimumSize: const Size(0, 50),
                    ),
                    child: const Text('Terapkan',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper widgets ──

  Widget _priceField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        prefixText: 'Rp  ',
        prefixStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      ),
    );
  }

  Widget _locChip(String loc) {
    final sel = _locations.contains(loc);
    return GestureDetector(
      onTap: () => setState(() {
        sel ? _locations.remove(loc) : _locations.add(loc);
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: sel ? AppColors.primary : AppColors.border,
              width: sel ? 1.5 : 1),
        ),
        child: Text(loc,
            style: TextStyle(
                fontSize: 13,
                fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                color: sel ? AppColors.primary : AppColors.textPrimary)),
      ),
    );
  }

  Widget _facilitySummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.shield_outlined,
              size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_facilities.length} Fasilitas dipilih',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(_facilities.join(', '),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        )),
      ]),
    );
  }

  Widget _facilityExpandButton() {
    final remaining =
        (fasilitasKamar.length + fasilitasBersama.length) - _facilities.length;
    return GestureDetector(
      onTap: () async {
        final r = await FacilityPickerSheet.show(context,
            currentSelection: _facilities);
        if (r != null)
          setState(() => _facilities
            ..clear()
            ..addAll(r));
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.4),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.add, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text('Fasilitas lainnya ($remaining tersedia)',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary)),
        ]),
      ),
    );
  }

  Widget _ratingChip(double rating) {
    final sel = _minRating == rating;
    return GestureDetector(
      onTap: () => setState(() => _minRating = sel ? null : rating),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: sel ? AppColors.primary : AppColors.border,
              width: sel ? 1.5 : 1),
        ),
        child: Text('${rating.toStringAsFixed(1)}+',
            style: TextStyle(
                fontSize: 13,
                fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                color: sel ? AppColors.primary : AppColors.textPrimary)),
      ),
    );
  }

  Widget _sortChip(SortMetric metric) {
    final sel = _sortBy == metric;
    IconData icon;
    switch (metric) {
      case SortMetric.terdekat:
        icon = Icons.location_on_outlined;
      case SortMetric.hargaRendah:
        icon = Icons.payments_outlined;
      case SortMetric.ratingTinggi:
        icon = Icons.star_outline;
      case SortMetric.banyakReview:
        icon = Icons.rate_review_outlined;
    }
    return GestureDetector(
      onTap: () => setState(() => _sortBy = metric),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: sel ? AppColors.primary : AppColors.border,
              width: sel ? 1.5 : 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 14,
              color: sel ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(metric.label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                  color: sel ? AppColors.primary : AppColors.textPrimary)),
        ]),
      ),
    );
  }
}
