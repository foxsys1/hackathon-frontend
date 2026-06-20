import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:kos_gdgoc/core/theme/app_theme.dart';
import 'package:kos_gdgoc/features/explore/data/region_data.dart';

/// A premium interactive map selector for choosing areas in Yogyakarta.
///
/// Uses flutter_map + OpenStreetMap tiles for real geographic display.
/// Features a Sui-inspired glassmorphic design with:
/// - Real map tiles with zoom/pan
/// - Animated district polygon overlays
/// - Type-ahead search for subdistricts
/// - Hierarchical drill-down: Province → Kabupaten → Kecamatan → Area
/// - Smooth fly-to animations and glow effects
class InteractiveMapSelector extends StatefulWidget {
  final Function(String) onAreaSelected;
  final VoidCallback? onBack;

  const InteractiveMapSelector({
    super.key,
    required this.onAreaSelected,
    this.onBack,
  });

  @override
  State<InteractiveMapSelector> createState() => _InteractiveMapSelectorState();
}

class _InteractiveMapSelectorState extends State<InteractiveMapSelector>
    with TickerProviderStateMixin {
  // ── State ──
  late Province _province;
  KabupatenKota? _selectedKab;
  final _searchController = TextEditingController();
  List<AreaSearchResult> _searchResults = [];
  bool _isSearchFocused = false;

  // ── Map controller ──
  final MapController _mapController = MapController();

  // ── Animation controllers ──
  late AnimationController _pulseCtrl;
  late AnimationController _selectionCtrl;
  late AnimationController _infoCardCtrl;
  late AnimationController _searchGlowCtrl;
  late AnimationController _overlayFadeCtrl;

  // ── Default map center (Yogyakarta) ──
  static const _yogyaCenter = LatLng(-7.7956, 110.3695);
  static const _defaultZoom = 10.0;
  static const _districtZoom = 12.5;

  @override
  void initState() {
    super.initState();
    _province = defaultProvince;

    // Pulse for markers
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Selection glow
    _selectionCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Info card slide
    _infoCardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    // Search glow
    _searchGlowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Overlay fade in
    _overlayFadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _selectionCtrl.dispose();
    _infoCardCtrl.dispose();
    _searchGlowCtrl.dispose();
    _overlayFadeCtrl.dispose();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ── Search ──
  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() {
      _searchResults = searchRegions(query, province: _province);
    });
  }

  void _onSearchResultTap(AreaSearchResult result) {
    _searchController.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _searchResults = [];
      _isSearchFocused = false;
    });
    widget.onAreaSelected(result.areaName);
  }

  // ── District tap ──
  void _onDistrictTap(KabupatenKota kab) {
    setState(() {
      if (_selectedKab?.id == kab.id) {
        _selectedKab = null;
        _infoCardCtrl.reverse();
        _selectionCtrl.reverse();
        _animatedMapMove(_yogyaCenter, _defaultZoom);
      } else {
        _selectedKab = kab;
        _selectionCtrl.forward(from: 0);
        _infoCardCtrl.forward(from: 0);
        _animatedMapMove(kab.center, _districtZoom);
      }
    });
  }

  void _onAreaChipTap(String areaName) {
    widget.onAreaSelected(areaName);
  }

  // ── Animated map move (fly-to effect) ──
  void _animatedMapMove(LatLng destCenter, double destZoom) {
    final currentCenter = _mapController.camera.center;
    final currentZoom = _mapController.camera.zoom;

    final latTween = Tween<double>(
      begin: currentCenter.latitude,
      end: destCenter.latitude,
    );
    final lngTween = Tween<double>(
      begin: currentCenter.longitude,
      end: destCenter.longitude,
    );
    final zoomTween = Tween<double>(
      begin: currentZoom,
      end: destZoom,
    );

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    final curve = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutCubic,
    );

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(curve), lngTween.evaluate(curve)),
        zoomTween.evaluate(curve),
      );
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF8F6FF),
      child: Stack(
        children: [
          // ── Map ──
          _buildMap(),

          // ── Top gradient overlay ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 180,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFF8F6FF).withOpacity(0.95),
                      const Color(0xFFF8F6FF).withOpacity(0.7),
                      const Color(0xFFF8F6FF).withOpacity(0.0),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom gradient overlay ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 120,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color(0xFFF8F6FF).withOpacity(0.95),
                      const Color(0xFFF8F6FF).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Header + Search (glass overlay) ──
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildSearchBar(),
                // ── Search results overlay ──
                if (_searchResults.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildSearchResults(),
                  ),
                const Spacer(),
                // ── Bottom info card ──
                _buildInfoCard(),
              ],
            ),
          ),

          // ── Zoom controls ──
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + (_selectedKab != null ? 260 : 24),
            child: AnimatedBuilder(
              animation: _overlayFadeCtrl,
              builder: (context, child) => Opacity(
                opacity: _overlayFadeCtrl.value,
                child: child,
              ),
              child: _buildZoomControls(),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Header
  // ─────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: widget.onBack ?? () => Navigator.of(context).maybePop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.divider.withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Area',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _province.name,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Province indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 14,
                  color: AppColors.primary.withOpacity(0.8),
                ),
                const SizedBox(width: 4),
                Text(
                  '${_province.kabupatenKota.length} Wilayah',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Search Bar
  // ─────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: AnimatedBuilder(
        animation: _searchGlowCtrl,
        builder: (context, child) {
          final glowOpacity =
              _isSearchFocused ? 0.15 + (_searchGlowCtrl.value * 0.1) : 0.0;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (_isSearchFocused)
                  BoxShadow(
                    color: AppColors.primary.withOpacity(glowOpacity),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          );
        },
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          onTap: () => setState(() => _isSearchFocused = true),
          onTapOutside: (_) {
            if (_searchResults.isEmpty) {
              setState(() => _isSearchFocused = false);
            }
          },
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Cari kecamatan, area, atau kampus...',
            hintStyle: TextStyle(
              color: AppColors.textHint.withOpacity(0.7),
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 20,
              color: _isSearchFocused
                  ? AppColors.primary
                  : AppColors.textHint,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: AppColors.textSecondary,
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                      setState(() => _isSearchFocused = false);
                      FocusScope.of(context).unfocus();
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.95),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.divider.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Search Results Overlay
  // ─────────────────────────────────────────────────────────

  Widget _buildSearchResults() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _searchResults.length.clamp(0, 10),
          separatorBuilder: (_, __) => Divider(
            height: 1,
            indent: 52,
            color: AppColors.divider.withOpacity(0.3),
          ),
          itemBuilder: (context, i) {
            final result = _searchResults[i];
            return _SearchResultTile(
              result: result,
              onTap: () => _onSearchResultTap(result),
            );
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Map (flutter_map with OpenStreetMap)
  // ─────────────────────────────────────────────────────────

  Widget _buildMap() {
    return AnimatedBuilder(
      animation: Listenable.merge([_selectionCtrl, _pulseCtrl]),
      builder: (context, _) {
        return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _yogyaCenter,
            initialZoom: _defaultZoom,
            minZoom: 8.0,
            maxZoom: 18.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
            onTap: (_, __) {
              // Deselect district when tapping empty area
              if (_selectedKab != null) {
                setState(() {
                  _selectedKab = null;
                  _infoCardCtrl.reverse();
                  _selectionCtrl.reverse();
                });
                _animatedMapMove(_yogyaCenter, _defaultZoom);
              }
            },
          ),
          children: [
            // ── Map tiles (OpenStreetMap with custom styling) ──
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.koscheck.app',
              tileBuilder: _buildStyledTile,
            ),

            // ── District polygon overlays ──
            PolygonLayer(
              polygons: _province.kabupatenKota.map((kab) {
                final isSelected = _selectedKab?.id == kab.id;
                final isDimmed = _selectedKab != null && !isSelected;
                final pulseVal = _pulseCtrl.value;
                final selectionVal = _selectionCtrl.value;

                return Polygon(
                  points: kab.polygonPoints,
                  color: isDimmed
                      ? kab.accentColor.withOpacity(0.04)
                      : isSelected
                          ? kab.accentColor.withOpacity(0.12 + pulseVal * 0.04)
                          : kab.accentColor.withOpacity(0.08),
                  borderColor: isDimmed
                      ? kab.accentColor.withOpacity(0.10)
                      : isSelected
                          ? kab.accentColor.withOpacity(0.55 + selectionVal * 0.15)
                          : kab.accentColor.withOpacity(0.30),
                  borderStrokeWidth: isSelected ? 3.0 : 1.5,
                  isFilled: true,
                );
              }).toList(),
            ),

            // ── District center markers (labels) ──
            MarkerLayer(
              markers: _province.kabupatenKota.map((kab) {
                final isSelected = _selectedKab?.id == kab.id;
                return Marker(
                  point: kab.center,
                  width: 130,
                  height: 50,
                  child: GestureDetector(
                    onTap: () => _onDistrictTap(kab),
                    child: _DistrictLabel(
                      kab: kab,
                      isSelected: isSelected,
                      pulseValue: _pulseCtrl.value,
                    ),
                  ),
                );
              }).toList(),
            ),

            // ── Kecamatan pins (when district is selected) ──
            if (_selectedKab != null)
              MarkerLayer(
                markers: _selectedKab!.kecamatan
                    .where((k) => k.popularAreas.isNotEmpty)
                    .map((kec) {
                  return Marker(
                    point: kec.mapPosition,
                    width: 120,
                    height: 36,
                    child: _KecamatanPin(
                      kecamatan: kec,
                      pulseValue: _pulseCtrl.value,
                      onTap: () => _onAreaChipTap(kec.name),
                    ),
                  );
                }).toList(),
              ),
          ],
        );
      },
    );
  }

  /// Applies a subtle desaturated/warm style to the map tiles
  Widget _buildStyledTile(BuildContext context, Widget tileWidget, TileImage tile) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.85, 0.10, 0.05, 0, 10,
        0.05, 0.85, 0.10, 0, 8,
        0.05, 0.08, 0.82, 0, 15,
        0,    0,    0,    1, 0,
      ]),
      child: tileWidget,
    );
  }

  // ─────────────────────────────────────────────────────────
  // Zoom Controls
  // ─────────────────────────────────────────────────────────

  Widget _buildZoomControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ZoomButton(
          icon: Icons.add_rounded,
          onTap: () {
            final currentZoom = _mapController.camera.zoom;
            _animatedMapMove(_mapController.camera.center, currentZoom + 1);
          },
        ),
        const SizedBox(height: 4),
        _ZoomButton(
          icon: Icons.remove_rounded,
          onTap: () {
            final currentZoom = _mapController.camera.zoom;
            _animatedMapMove(_mapController.camera.center, currentZoom - 1);
          },
        ),
        const SizedBox(height: 4),
        _ZoomButton(
          icon: Icons.my_location_rounded,
          onTap: () {
            _selectedKab = null;
            _infoCardCtrl.reverse();
            _selectionCtrl.reverse();
            _animatedMapMove(_yogyaCenter, _defaultZoom);
            setState(() {});
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // Bottom Info Card
  // ─────────────────────────────────────────────────────────

  Widget _buildInfoCard() {
    return AnimatedBuilder(
      animation: _infoCardCtrl,
      builder: (context, _) {
        final slideValue = CurvedAnimation(
          parent: _infoCardCtrl,
          curve: Curves.easeOutCubic,
        ).value;

        if (slideValue < 0.01 || _selectedKab == null) {
          return const SizedBox.shrink();
        }

        final kab = _selectedKab!;

        return Transform.translate(
          offset: Offset(0, 140 * (1 - slideValue)),
          child: Opacity(
            opacity: slideValue,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: kab.accentColor.withOpacity(0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: kab.accentColor.withOpacity(0.10),
                    blurRadius: 32,
                    offset: const Offset(0, -6),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      // Animated icon container
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (context, child) {
                          return Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  kab.accentColor.withOpacity(0.12 + _pulseCtrl.value * 0.05),
                                  kab.accentColor.withOpacity(0.18 + _pulseCtrl.value * 0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: kab.accentColor.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              kab.type == 'kota'
                                  ? Icons.location_city_rounded
                                  : Icons.terrain_rounded,
                              size: 20,
                              color: kab.accentColor,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              kab.shortName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${kab.totalKecamatan} Kecamatan',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Explore all CTA
                      GestureDetector(
                        onTap: () => widget.onAreaSelected(kab.shortName),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                kab.accentColor,
                                kab.accentColor.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: kab.accentColor.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Eksplor',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded,
                                  size: 15, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    kab.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withOpacity(0.9),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Popular area chips
                  if (kab.allAreas.isNotEmpty) ...[
                    Text(
                      'AREA POPULER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary.withOpacity(0.5),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: kab.allAreas.take(8).map((area) {
                        return GestureDetector(
                          onTap: () => _onAreaChipTap(area),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: kab.accentColor.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: kab.accentColor.withOpacity(0.15),
                              ),
                            ),
                            child: Text(
                              area,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: kab.accentColor,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════
// Search Result Tile
// ═════════════════════════════════════════════════════════════

class _SearchResultTile extends StatelessWidget {
  final AreaSearchResult result;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.result,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.displayName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    result.breadcrumb,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint.withOpacity(0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.north_east_rounded,
              size: 14,
              color: AppColors.primary.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// District Label Widget (Sui-style glassmorphic)
// ═════════════════════════════════════════════════════════════

class _DistrictLabel extends StatelessWidget {
  final KabupatenKota kab;
  final bool isSelected;
  final double pulseValue;

  const _DistrictLabel({
    required this.kab,
    required this.isSelected,
    required this.pulseValue,
  });

  @override
  Widget build(BuildContext context) {
    final glowOpacity = isSelected ? 0.2 + (pulseValue * 0.1) : 0.0;

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.95)
              : Colors.white.withOpacity(0.88),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? kab.accentColor.withOpacity(0.5)
                : Colors.white.withOpacity(0.6),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: kab.accentColor.withOpacity(glowOpacity),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.12 : 0.08),
              blurRadius: isSelected ? 16 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isSelected ? 8 : 6,
              height: isSelected ? 8 : 6,
              decoration: BoxDecoration(
                color: kab.accentColor,
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: kab.accentColor.withOpacity(0.5),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              kab.shortName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? kab.accentColor : AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// Kecamatan Pin Widget (animated drop-in)
// ═════════════════════════════════════════════════════════════

class _KecamatanPin extends StatelessWidget {
  final Kecamatan kecamatan;
  final double pulseValue;
  final VoidCallback onTap;

  const _KecamatanPin({
    required this.kecamatan,
    required this.pulseValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final idleBob = math.sin(pulseValue * math.pi) * 2;

    return Center(
      child: Transform.translate(
        offset: Offset(0, idleBob),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.30),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08 + pulseValue * 0.06),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 11,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    kecamatan.name,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// Zoom Button Widget
// ═════════════════════════════════════════════════════════════

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ZoomButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.divider.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: AppColors.textPrimary.withOpacity(0.7),
        ),
      ),
    );
  }
}
