library region_data;

/// Hierarchical geographic data model for Indonesia.
///
/// Structure: Province → Kabupaten/Kota → Kecamatan → Popular Areas
/// Currently populated for DIY (Yogyakarta Special Region).
/// Designed for easy expansion to all 38 Indonesian provinces.

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

// ─────────────────────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────────────────────

class Province {
  final String id;
  final String name;
  final List<KabupatenKota> kabupatenKota;

  Province({
    required this.id,
    required this.name,
    required this.kabupatenKota,
  });
}

class KabupatenKota {
  final String id;
  final String name;
  final String type; // 'kabupaten' or 'kota'
  final String shortName;
  final String description;
  final List<Kecamatan> kecamatan;
  // Simplified polygon points for map rendering (Lat, Lng)
  final List<LatLng> polygonPoints;
  // Center point for label placement
  final LatLng center;
  // Accent color for this district
  final Color accentColor;

  KabupatenKota({
    required this.id,
    required this.name,
    required this.type,
    required this.shortName,
    required this.description,
    required this.kecamatan,
    required this.polygonPoints,
    required this.center,
    required this.accentColor,
  });

  int get totalKecamatan => kecamatan.length;
  
  List<String> get allAreas => kecamatan.expand((k) => k.popularAreas).toList();
}

class Kecamatan {
  final String id;
  final String name;
  final List<String> popularAreas;
  // Position on map within its parent kabupaten
  final LatLng mapPosition;

  Kecamatan({
    required this.id,
    required this.name,
    required this.mapPosition,
    this.popularAreas = const [],
  });
}

// ─────────────────────────────────────────────────────────────
// Search Helper
// ─────────────────────────────────────────────────────────────

class AreaSearchResult {
  final String displayName;
  final String areaName;
  final String kecamatanName;
  final String kabupatenName;
  final String provinceName;
  final String breadcrumb; // e.g. "DIY > Sleman > Depok > Pogung"

  AreaSearchResult({
    required this.displayName,
    required this.areaName,
    required this.kecamatanName,
    required this.kabupatenName,
    required this.provinceName,
    required this.breadcrumb,
  });
}

/// Search across the entire region hierarchy.
/// Returns matching areas, kecamatan, or kabupaten based on query.
List<AreaSearchResult> searchRegions(String query, {Province? province}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return [];

  final results = <AreaSearchResult>[];
  final provinces = province != null ? [province] : allProvinces;

  for (final prov in provinces) {
    for (final kab in prov.kabupatenKota) {
      // Match kabupaten/kota name
      if (kab.name.toLowerCase().contains(q) ||
          kab.shortName.toLowerCase().contains(q)) {
        results.add(AreaSearchResult(
          displayName: kab.name,
          areaName: kab.shortName,
          kecamatanName: '',
          kabupatenName: kab.name,
          provinceName: prov.name,
          breadcrumb: '${prov.name} > ${kab.shortName}',
        ));
      }

      for (final kec in kab.kecamatan) {
        // Match kecamatan name
        if (kec.name.toLowerCase().contains(q)) {
          results.add(AreaSearchResult(
            displayName: kec.name,
            areaName: kec.name,
            kecamatanName: kec.name,
            kabupatenName: kab.name,
            provinceName: prov.name,
            breadcrumb: '${prov.name} > ${kab.shortName} > ${kec.name}',
          ));
        }

        // Match popular areas
        for (final area in kec.popularAreas) {
          if (area.toLowerCase().contains(q)) {
            results.add(AreaSearchResult(
              displayName: area,
              areaName: area,
              kecamatanName: kec.name,
              kabupatenName: kab.name,
              provinceName: prov.name,
              breadcrumb:
                  '${prov.name} > ${kab.shortName} > ${kec.name} > $area',
            ));
          }
        }
      }
    }
  }

  return results;
}

// ─────────────────────────────────────────────────────────────
// Province Data — Yogyakarta Special Region (DIY)
// ─────────────────────────────────────────────────────────────

final _diy = Province(
  id: 'diy',
  name: 'DI Yogyakarta',
  kabupatenKota: [
    // ── Kabupaten Sleman ──
    KabupatenKota(
      id: 'sleman',
      name: 'Kabupaten Sleman',
      type: 'kabupaten',
      shortName: 'Sleman',
      description:
          'Pusat pendidikan dengan UGM, UNY, UII. Area kos terbanyak dan terlengkap.',
      accentColor: const Color(0xFF6366F1), // Indigo
      center: const LatLng(-7.7167, 110.3558),
      polygonPoints: const [
        LatLng(-7.55, 110.22), LatLng(-7.55, 110.30), LatLng(-7.56, 110.42), LatLng(-7.58, 110.50),
        LatLng(-7.65, 110.52), LatLng(-7.72, 110.50), LatLng(-7.76, 110.45), LatLng(-7.78, 110.40),
        LatLng(-7.78, 110.35), LatLng(-7.76, 110.28), LatLng(-7.72, 110.23), LatLng(-7.63, 110.20),
      ],
      kecamatan: [
        Kecamatan(
          id: 'depok',
          name: 'Depok',
          mapPosition: const LatLng(-7.7655, 110.3965),
          popularAreas: const ['Pogung', 'Seturan', 'Babarsari', 'Condong Catur', 'Gejayan', 'Karangwuni', 'Pandega', 'Demangan'],
        ),
        Kecamatan(
          id: 'mlati',
          name: 'Mlati',
          mapPosition: const LatLng(-7.7560, 110.3460),
          popularAreas: const ['Palagan', 'Jombor', 'Sinduadi'],
        ),
        Kecamatan(
          id: 'ngaglik',
          name: 'Ngaglik',
          mapPosition: const LatLng(-7.7115, 110.3960),
          popularAreas: const ['Jakal', 'Kaliurang', 'Jl. Lempongsari'],
        ),
        Kecamatan(
          id: 'gamping',
          name: 'Gamping',
          mapPosition: const LatLng(-7.7790, 110.3250),
          popularAreas: const ['Godean', 'Ringroad Barat'],
        ),
        Kecamatan(
          id: 'ngemplak',
          name: 'Ngemplak',
          mapPosition: const LatLng(-7.7050, 110.4250),
          popularAreas: const ['Jl. Kaliurang KM 10+'],
        ),
        Kecamatan(
          id: 'kalasan',
          name: 'Kalasan',
          mapPosition: const LatLng(-7.7570, 110.4710),
          popularAreas: const ['Prambanan Area'],
        ),
        Kecamatan(
          id: 'pakem',
          name: 'Pakem',
          mapPosition: const LatLng(-7.6560, 110.4150),
          popularAreas: const ['Kaliurang Atas'],
        ),
        Kecamatan(
          id: 'sleman_kec',
          name: 'Sleman',
          mapPosition: const LatLng(-7.7150, 110.3320),
          popularAreas: const ['Tridadi', 'Triharjo'],
        ),
        Kecamatan(
          id: 'godean',
          name: 'Godean',
          mapPosition: const LatLng(-7.7700, 110.2960),
          popularAreas: const ['Godean Kota'],
        ),
        Kecamatan(
          id: 'berbah',
          name: 'Berbah',
          mapPosition: const LatLng(-7.7810, 110.4650),
        ),
        Kecamatan(
          id: 'cangkringan',
          name: 'Cangkringan',
          mapPosition: const LatLng(-7.6200, 110.4400),
        ),
        Kecamatan(
          id: 'tempel',
          name: 'Tempel',
          mapPosition: const LatLng(-7.6660, 110.3000),
        ),
        Kecamatan(
          id: 'turi',
          name: 'Turi',
          mapPosition: const LatLng(-7.6360, 110.3500),
        ),
        Kecamatan(
          id: 'seyegan',
          name: 'Seyegan',
          mapPosition: const LatLng(-7.7150, 110.2800),
        ),
        Kecamatan(
          id: 'minggir',
          name: 'Minggir',
          mapPosition: const LatLng(-7.7400, 110.2570),
        ),
        Kecamatan(
          id: 'moyudan',
          name: 'Moyudan',
          mapPosition: const LatLng(-7.7650, 110.2400),
        ),
        Kecamatan(
          id: 'prambanan',
          name: 'Prambanan',
          mapPosition: const LatLng(-7.7520, 110.4930),
        ),
      ],
    ),

    // ── Kota Yogyakarta ──
    KabupatenKota(
      id: 'kota_yogya',
      name: 'Kota Yogyakarta',
      type: 'kota',
      shortName: 'Kota Yogyakarta',
      description:
          'Pusat kota dengan Malioboro, Kraton, dan kuliner legendaris.',
      accentColor: const Color(0xFFF59E0B), // Amber
      center: const LatLng(-7.7956, 110.3695),
      polygonPoints: const [
        LatLng(-7.765, 110.345), LatLng(-7.765, 110.395), LatLng(-7.785, 110.405),
        LatLng(-7.815, 110.400), LatLng(-7.825, 110.385), LatLng(-7.820, 110.350),
        LatLng(-7.805, 110.338), LatLng(-7.780, 110.338),
      ],
      kecamatan: [
        Kecamatan(
          id: 'gondokusuman',
          name: 'Gondokusuman',
          mapPosition: const LatLng(-7.7830, 110.3850),
          popularAreas: const ['Demangan', 'Baciro', 'Terban'],
        ),
        Kecamatan(
          id: 'danurejan',
          name: 'Danurejan',
          mapPosition: const LatLng(-7.7890, 110.3720),
          popularAreas: const ['Malioboro'],
        ),
        Kecamatan(
          id: 'gedongtengen',
          name: 'Gedongtengen',
          mapPosition: const LatLng(-7.7860, 110.3580),
          popularAreas: const ['Jlagran'],
        ),
        Kecamatan(
          id: 'gondomanan',
          name: 'Gondomanan',
          mapPosition: const LatLng(-7.7980, 110.3700),
          popularAreas: const ['Prawirotaman'],
        ),
        Kecamatan(
          id: 'kraton',
          name: 'Kraton',
          mapPosition: const LatLng(-7.8050, 110.3620),
          popularAreas: const ['Alun-Alun'],
        ),
        Kecamatan(
          id: 'umbulharjo',
          name: 'Umbulharjo',
          mapPosition: const LatLng(-7.8120, 110.3880),
          popularAreas: const ['Giwangan', 'Warungboto'],
        ),
        Kecamatan(
          id: 'kotagede',
          name: 'Kotagede',
          mapPosition: const LatLng(-7.8120, 110.4020),
          popularAreas: const ['Kotagede'],
        ),
        Kecamatan(
          id: 'mergangsan',
          name: 'Mergangsan',
          mapPosition: const LatLng(-7.8070, 110.3750),
          popularAreas: const ['Prawirotaman'],
        ),
        Kecamatan(
          id: 'mantrijeron',
          name: 'Mantrijeron',
          mapPosition: const LatLng(-7.8130, 110.3580),
        ),
        Kecamatan(
          id: 'wirobrajan',
          name: 'Wirobrajan',
          mapPosition: const LatLng(-7.7970, 110.3450),
        ),
        Kecamatan(
          id: 'ngampilan',
          name: 'Ngampilan',
          mapPosition: const LatLng(-7.7950, 110.3550),
        ),
        Kecamatan(
          id: 'pakualaman',
          name: 'Pakualaman',
          mapPosition: const LatLng(-7.7940, 110.3790),
        ),
        Kecamatan(
          id: 'jetis',
          name: 'Jetis',
          mapPosition: const LatLng(-7.7790, 110.3620),
          popularAreas: const ['Tugu Jogja'],
        ),
        Kecamatan(
          id: 'tegalrejo',
          name: 'Tegalrejo',
          mapPosition: const LatLng(-7.7750, 110.3440),
          popularAreas: const ['Pingit'],
        ),
      ],
    ),

    // ── Kabupaten Bantul ──
    KabupatenKota(
      id: 'bantul',
      name: 'Kabupaten Bantul',
      type: 'kabupaten',
      shortName: 'Bantul',
      description:
          'Area selatan Jogja dengan pantai Parangtritis dan sentra kerajinan.',
      accentColor: const Color(0xFF10B981), // Emerald
      center: const LatLng(-7.8889, 110.3333),
      polygonPoints: const [
        LatLng(-7.82, 110.25), LatLng(-7.82, 110.33), LatLng(-7.825, 110.40),
        LatLng(-7.84, 110.43), LatLng(-7.90, 110.44), LatLng(-7.96, 110.42),
        LatLng(-7.99, 110.38), LatLng(-7.98, 110.30), LatLng(-7.96, 110.24),
        LatLng(-7.90, 110.20), LatLng(-7.85, 110.22),
      ],
      kecamatan: [
        Kecamatan(
          id: 'kasihan',
          name: 'Kasihan',
          mapPosition: const LatLng(-7.8200, 110.3350),
          popularAreas: const ['Kasihan', 'Tamantirto', 'ISI Area'],
        ),
        Kecamatan(
          id: 'sewon',
          name: 'Sewon',
          mapPosition: const LatLng(-7.8350, 110.3650),
          popularAreas: const ['Sewon', 'Panggungharjo'],
        ),
        Kecamatan(
          id: 'banguntapan',
          name: 'Banguntapan',
          mapPosition: const LatLng(-7.8200, 110.4050),
          popularAreas: const ['Banguntapan', 'Jl. Wonosari'],
        ),
        Kecamatan(
          id: 'bantul_kec',
          name: 'Bantul',
          mapPosition: const LatLng(-7.8850, 110.3250),
          popularAreas: const ['Bantul Kota'],
        ),
        Kecamatan(
          id: 'sedayu',
          name: 'Sedayu',
          mapPosition: const LatLng(-7.8000, 110.2600),
        ),
        Kecamatan(
          id: 'pajangan',
          name: 'Pajangan',
          mapPosition: const LatLng(-7.8400, 110.2750),
        ),
        Kecamatan(
          id: 'pandak',
          name: 'Pandak',
          mapPosition: const LatLng(-7.8750, 110.2700),
        ),
        Kecamatan(
          id: 'bambanglipuro',
          name: 'Bambanglipuro',
          mapPosition: const LatLng(-7.9100, 110.2900),
        ),
        Kecamatan(
          id: 'pundong',
          name: 'Pundong',
          mapPosition: const LatLng(-7.9300, 110.3200),
        ),
        Kecamatan(
          id: 'kretek',
          name: 'Kretek',
          mapPosition: const LatLng(-7.9650, 110.3000),
          popularAreas: const ['Parangtritis'],
        ),
        Kecamatan(
          id: 'sanden',
          name: 'Sanden',
          mapPosition: const LatLng(-7.9600, 110.2600),
        ),
        Kecamatan(
          id: 'srandakan',
          name: 'Srandakan',
          mapPosition: const LatLng(-7.9400, 110.2450),
        ),
        Kecamatan(
          id: 'piyungan',
          name: 'Piyungan',
          mapPosition: const LatLng(-7.8350, 110.4250),
        ),
        Kecamatan(
          id: 'pleret',
          name: 'Pleret',
          mapPosition: const LatLng(-7.8650, 110.3950),
        ),
        Kecamatan(
          id: 'imogiri',
          name: 'Imogiri',
          mapPosition: const LatLng(-7.9200, 110.3800),
        ),
        Kecamatan(
          id: 'dlingo',
          name: 'Dlingo',
          mapPosition: const LatLng(-7.8900, 110.4300),
        ),
        Kecamatan(
          id: 'jetis_bantul',
          name: 'Jetis',
          mapPosition: const LatLng(-7.8700, 110.3500),
        ),
      ],
    ),

    // ── Kabupaten Kulon Progo ──
    KabupatenKota(
      id: 'kulon_progo',
      name: 'Kabupaten Kulon Progo',
      type: 'kabupaten',
      shortName: 'Kulon Progo',
      description:
          'Area barat Jogja dengan Bandara YIA dan Perbukitan Menoreh.',
      accentColor: const Color(0xFFEC4899), // Pink
      center: const LatLng(-7.8256, 110.1544),
      polygonPoints: const [
        LatLng(-7.60, 110.05), LatLng(-7.63, 110.14), LatLng(-7.70, 110.20),
        LatLng(-7.76, 110.25), LatLng(-7.82, 110.25), LatLng(-7.90, 110.22),
        LatLng(-7.98, 110.18), LatLng(-7.99, 110.10), LatLng(-7.96, 110.05),
        LatLng(-7.88, 110.02), LatLng(-7.75, 110.02), LatLng(-7.65, 110.03),
      ],
      kecamatan: [
        Kecamatan(
          id: 'wates',
          name: 'Wates',
          mapPosition: const LatLng(-7.8600, 110.1530),
          popularAreas: const ['Wates Kota'],
        ),
        Kecamatan(
          id: 'sentolo',
          name: 'Sentolo',
          mapPosition: const LatLng(-7.8200, 110.2000),
        ),
        Kecamatan(
          id: 'pengasih',
          name: 'Pengasih',
          mapPosition: const LatLng(-7.8400, 110.1600),
        ),
        Kecamatan(
          id: 'kokap',
          name: 'Kokap',
          mapPosition: const LatLng(-7.8000, 110.0900),
        ),
        Kecamatan(
          id: 'girimulyo',
          name: 'Girimulyo',
          mapPosition: const LatLng(-7.7500, 110.1000),
        ),
        Kecamatan(
          id: 'nanggulan',
          name: 'Nanggulan',
          mapPosition: const LatLng(-7.7600, 110.1500),
        ),
        Kecamatan(
          id: 'samigaluh',
          name: 'Samigaluh',
          mapPosition: const LatLng(-7.7100, 110.0800),
        ),
        Kecamatan(
          id: 'kalibawang',
          name: 'Kalibawang',
          mapPosition: const LatLng(-7.7000, 110.1400),
        ),
        Kecamatan(
          id: 'temon',
          name: 'Temon',
          mapPosition: const LatLng(-7.9000, 110.0700),
          popularAreas: const ['Bandara YIA'],
        ),
        Kecamatan(
          id: 'panjatan',
          name: 'Panjatan',
          mapPosition: const LatLng(-7.9200, 110.1000),
        ),
        Kecamatan(
          id: 'galur',
          name: 'Galur',
          mapPosition: const LatLng(-7.9400, 110.1300),
        ),
        Kecamatan(
          id: 'lendah',
          name: 'Lendah',
          mapPosition: const LatLng(-7.8800, 110.1800),
        ),
      ],
    ),

    // ── Kabupaten Gunungkidul ──
    KabupatenKota(
      id: 'gunungkidul',
      name: 'Kabupaten Gunungkidul',
      type: 'kabupaten',
      shortName: 'Gunungkidul',
      description:
          'Area timur selatan dengan pantai-pantai indah dan gua alam.',
      accentColor: const Color(0xFF8B5CF6), // Violet
      center: const LatLng(-7.9667, 110.6167),
      polygonPoints: const [
        LatLng(-7.72, 110.48), LatLng(-7.70, 110.58), LatLng(-7.72, 110.68),
        LatLng(-7.78, 110.73), LatLng(-7.85, 110.73), LatLng(-7.95, 110.72),
        LatLng(-8.05, 110.68), LatLng(-8.10, 110.58), LatLng(-8.08, 110.48),
        LatLng(-7.98, 110.44), LatLng(-7.88, 110.42), LatLng(-7.80, 110.44),
      ],
      kecamatan: [
        Kecamatan(
          id: 'wonosari',
          name: 'Wonosari',
          mapPosition: const LatLng(-7.9633, 110.5950),
          popularAreas: const ['Wonosari Kota'],
        ),
        Kecamatan(
          id: 'playen',
          name: 'Playen',
          mapPosition: const LatLng(-7.9450, 110.5600),
        ),
        Kecamatan(
          id: 'patuk',
          name: 'Patuk',
          mapPosition: const LatLng(-7.8300, 110.5100),
        ),
        Kecamatan(
          id: 'gedangsari',
          name: 'Gedangsari',
          mapPosition: const LatLng(-7.7900, 110.5500),
        ),
        Kecamatan(
          id: 'nglipar',
          name: 'Nglipar',
          mapPosition: const LatLng(-7.8200, 110.5800),
        ),
        Kecamatan(
          id: 'karangmojo',
          name: 'Karangmojo',
          mapPosition: const LatLng(-7.9200, 110.6200),
        ),
        Kecamatan(
          id: 'semanu',
          name: 'Semanu',
          mapPosition: const LatLng(-7.9700, 110.6300),
        ),
        Kecamatan(
          id: 'tepus',
          name: 'Tepus',
          mapPosition: const LatLng(-8.0500, 110.6500),
          popularAreas: const ['Pantai Indrayanti'],
        ),
        Kecamatan(
          id: 'tanjungsari',
          name: 'Tanjungsari',
          mapPosition: const LatLng(-8.0700, 110.5800),
          popularAreas: const ['Pantai Baron'],
        ),
        Kecamatan(
          id: 'panggang',
          name: 'Panggang',
          mapPosition: const LatLng(-8.0200, 110.5000),
        ),
        Kecamatan(
          id: 'purwosari',
          name: 'Purwosari',
          mapPosition: const LatLng(-7.9800, 110.4800),
        ),
        Kecamatan(
          id: 'ponjong',
          name: 'Ponjong',
          mapPosition: const LatLng(-7.9500, 110.6600),
        ),
        Kecamatan(
          id: 'rongkop',
          name: 'Rongkop',
          mapPosition: const LatLng(-8.0200, 110.6900),
        ),
        Kecamatan(
          id: 'girisubo',
          name: 'Girisubo',
          mapPosition: const LatLng(-8.0600, 110.7100),
        ),
        Kecamatan(
          id: 'semin',
          name: 'Semin',
          mapPosition: const LatLng(-7.8300, 110.6500),
        ),
        Kecamatan(
          id: 'ngawen',
          name: 'Ngawen',
          mapPosition: const LatLng(-7.7800, 110.6200),
        ),
        Kecamatan(
          id: 'saptosari',
          name: 'Saptosari',
          mapPosition: const LatLng(-8.0400, 110.5500),
        ),
        Kecamatan(
          id: 'paliyan',
          name: 'Paliyan',
          mapPosition: const LatLng(-7.9800, 110.5400),
        ),
      ],
    ),
  ],
);

// ─────────────────────────────────────────────────────────────
// All Provinces Registry
// ─────────────────────────────────────────────────────────────

/// All available provinces. Add more provinces here to expand coverage.
final List<Province> allProvinces = [_diy];

/// Quick access to DIY province (default).
Province get yogyakartaProvince => _diy;

/// Get the default province for initial map display.
Province get defaultProvince => _diy;
