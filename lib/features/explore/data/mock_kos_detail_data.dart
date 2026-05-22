import 'package:kos_gdgoc/features/explore/domain/kos_detail.dart';

/// Mock detail data keyed by kos ID.
final Map<String, KosDetail> mockKosDetails = {
  'kos-001': const KosDetail(
    id: 'kos-001',
    name: 'Kos Putra Senja Ayu',
    location: 'Pogung Baru, Sleman',
    area: 'Pogung',
    pricePerMonth: 1000000,
    imageUrl:
        'https://images.unsplash.com/photo-1555854877-bab0e564b8d5?w=400&h=300&fit=crop',
    rating: 4.6,
    reviewCount: 2,
    distanceKm: 0.8,
    facilities: ['K. Mandi Dalam', 'AC', 'Wifi', 'Kasur', 'Lemari', 'Meja'],
    facilityTags: ['Lokasi', 'Wifi', 'Keamanan'],
    aiSummary:
        'Sebagian besar penghuni merasa kos ini aman dan dekat dengan kampus. Namun beberapa menyebutkan Wifi kadang lambat dan area sekitar bisa cukup brisik malem malem.',
    positiveHighlights: [
      'Aman dan nyaman',
      'Dekat kampus dan fasilitas umum',
      'Ibu kos ramah bgtt',
    ],
    negativeHighlights: [
      'Wifi kadang lemot cuk',
      'Area sekitar terkadang berisik',
      'Parkir terbatas untuk motor/mobil',
    ],
    topikDibahas: ['Lokasi', 'Kenyamanan', 'Kebersihan', 'Wifi'],
    reviews: [
      KosReview(
        id: 'rev-001',
        userName: 'Andi Rahman',
        userRole: 'Mahasiswa',
        rating: 5.0,
        timeAgo: '2 minggu lalu',
        content:
            'Kosnya nyaman bgtt berasa lagi tinggal di hawaii, deket juga dari kampus tercinta fakultas teknik ugm, ibunya juga baikk bgtt namanya bu tarni boloooo',
        tags: ['Lokasi', 'Kenyamanan', 'Kebersihan'],
      ),
      KosReview(
        id: 'rev-002',
        userName: 'Rajwa Fathin',
        userRole: 'Mahasiswa',
        rating: 3.0,
        timeAgo: '3 minggu lalu',
        content:
            'Kosnya kadang rada bau di bagian depannya (ada eek kucing kadang cuk)',
        tags: ['Wifi', 'Lokasi', 'Kenyamanan'],
      ),
    ],
  ),
  'kos-002': const KosDetail(
    id: 'kos-002',
    name: 'Kos Putra Sentanu',
    location: 'Pogung Kidul, Sleman',
    area: 'Pogung',
    pricePerMonth: 1250000,
    imageUrl:
        'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=400&h=300&fit=crop',
    rating: 4.0,
    reviewCount: 15,
    distanceKm: 1.2,
    facilities: ['K. Mandi Dalam', 'AC', 'Wifi', 'Kasur', 'Lemari', 'TV'],
    facilityTags: ['Lokasi', 'Wifi', 'Keamanan'],
    aiSummary:
        'Kos ini memiliki lokasi strategis dan fasilitas yang cukup lengkap. Beberapa penghuni mengeluhkan kebersihan area bersama.',
    positiveHighlights: [
      'Lokasi strategis dekat kampus',
      'Fasilitas kamar lengkap',
      'Harga terjangkau untuk area Pogung',
    ],
    negativeHighlights: [
      'Kebersihan area bersama kurang',
      'Air kadang mati sore hari',
      'Kurang ventilasi di lorong',
    ],
    topikDibahas: ['Lokasi', 'Kebersihan', 'Wifi', 'Kenyamanan'],
    reviews: [
      KosReview(
        id: 'rev-003',
        userName: 'Budi Santoso',
        userRole: 'Mahasiswa',
        rating: 4.0,
        timeAgo: '1 minggu lalu',
        content:
            'Lumayan bagus kosnya, lokasi deket kampus. Cuma kadang air mati sore, tapi overall oke lah.',
        tags: ['Lokasi', 'Kenyamanan'],
      ),
      KosReview(
        id: 'rev-004',
        userName: 'Siti Nurhaliza',
        userRole: 'Mahasiswa',
        rating: 3.5,
        timeAgo: '2 minggu lalu',
        content:
            'Kamarnya oke, tapi lorong gelap dan kurang bersih. Perlu perbaikan pencahayaan.',
        tags: ['Kebersihan', 'Kenyamanan'],
      ),
    ],
  ),
  'kos-003': const KosDetail(
    id: 'kos-003',
    name: 'Kos Putra Janardana',
    location: 'Pogung Baru, Sleman',
    area: 'Pogung',
    pricePerMonth: 2100000,
    imageUrl:
        'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=400&h=300&fit=crop',
    rating: 4.3,
    reviewCount: 28,
    distanceKm: 1.5,
    facilities: [
      'K. Mandi Dalam',
      'AC',
      'Wifi',
      'Kasur',
      'Lemari',
      'TV',
      'Parkir Motor',
      'CCTV',
    ],
    facilityTags: ['Lokasi', 'Kenyamanan', 'Wifi'],
    aiSummary:
        'Kos premium dengan fasilitas lengkap termasuk CCTV dan parkiran. Penghuni umumnya puas tapi harga dinilai di atas rata-rata area.',
    positiveHighlights: [
      'Fasilitas lengkap dan modern',
      'Keamanan terjamin dengan CCTV',
      'Parkir luas dan terorganisir',
    ],
    negativeHighlights: [
      'Harga di atas rata-rata area',
      'Wifi lambat saat peak hours',
      'Tidak ada dapur bersama',
    ],
    topikDibahas: ['Kenyamanan', 'Keamanan', 'Wifi', 'Lokasi'],
    reviews: [
      KosReview(
        id: 'rev-005',
        userName: 'Ahmad Zaki',
        userRole: 'Mahasiswa',
        rating: 4.5,
        timeAgo: '3 hari lalu',
        content:
            'Kos terbaik di area Pogung menurutku. Fasilitas lengkap, cuma agak mahal aja sih.',
        tags: ['Kenyamanan', 'Lokasi'],
      ),
    ],
  ),
  'kos-004': const KosDetail(
    id: 'kos-004',
    name: 'Kos Putri Melati Indah',
    location: 'Condong Catur, Sleman',
    area: 'Condong Catur',
    pricePerMonth: 900000,
    imageUrl:
        'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=400&h=300&fit=crop',
    rating: 4.8,
    reviewCount: 42,
    distanceKm: 2.3,
    facilities: [
      'K. Mandi Dalam',
      'AC',
      'Wifi',
      'Kasur',
      'Lemari',
      'Meja',
      'Parkir Motor',
      'Parkir Mobil',
      'CCTV',
      'Laundry',
    ],
    facilityTags: ['Keamanan', 'Kenyamanan', 'Wifi', 'Lokasi'],
    aiSummary:
        'Kos dengan rating tertinggi di area Condong Catur. Penghuni memuji kebersihan, keamanan 24 jam, dan ibu kos yang sangat ramah.',
    positiveHighlights: [
      'Kebersihan sangat terjaga',
      'Keamanan 24 jam dengan CCTV',
      'Ibu kos ramah dan responsif',
    ],
    negativeHighlights: [
      'Agak jauh dari kampus UGM',
      'Tidak ada dapur bersama',
      'Jam malam ketat',
    ],
    topikDibahas: ['Keamanan', 'Kebersihan', 'Kenyamanan', 'Lokasi'],
    reviews: [
      KosReview(
        id: 'rev-006',
        userName: 'Dina Mariana',
        userRole: 'Mahasiswa',
        rating: 5.0,
        timeAgo: '1 minggu lalu',
        content:
            'Kos terbersih yang pernah aku tinggali! Ibu kosnya perhatian banget, kayak mama sendiri.',
        tags: ['Kebersihan', 'Kenyamanan'],
      ),
    ],
  ),
  'kos-005': const KosDetail(
    id: 'kos-005',
    name: 'Kos Putra Gejayan Residence',
    location: 'Gejayan, Sleman',
    area: 'Gejayan',
    pricePerMonth: 1500000,
    imageUrl:
        'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=400&h=300&fit=crop',
    rating: 3.9,
    reviewCount: 8,
    distanceKm: 0.5,
    facilities: ['K. Mandi Dalam', 'Wifi', 'Kasur', 'Lemari', 'Kipas Angin'],
    facilityTags: ['Lokasi', 'Wifi'],
    aiSummary:
        'Lokasi sangat dekat dengan pusat kuliner dan transportasi. Namun ventilasi kamar perlu perhatian dan fasilitas cukup basic.',
    positiveHighlights: [
      'Lokasi paling strategis di Gejayan',
      'Dekat kuliner dan transportasi',
      'Harga kompetitif untuk lokasi',
    ],
    negativeHighlights: [
      'Ventilasi kamar kurang baik',
      'Fasilitas cukup basic',
      'Tidak ada AC, hanya kipas angin',
    ],
    topikDibahas: ['Lokasi', 'Wifi', 'Kenyamanan'],
    reviews: [
      KosReview(
        id: 'rev-007',
        userName: 'Reza Pratama',
        userRole: 'Mahasiswa',
        rating: 4.0,
        timeAgo: '5 hari lalu',
        content:
            'Lokasi mantap, tinggal jalan kaki ke mana-mana. Tapi kamarnya agak panas kalau siang.',
        tags: ['Lokasi', 'Kenyamanan'],
      ),
    ],
  ),
  'kos-006': const KosDetail(
    id: 'kos-006',
    name: 'Kos Putri Seturan Garden',
    location: 'Seturan, Sleman',
    area: 'Seturan',
    pricePerMonth: 1800000,
    imageUrl:
        'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=400&h=300&fit=crop',
    rating: 4.5,
    reviewCount: 19,
    distanceKm: 3.1,
    facilities: [
      'K. Mandi Dalam',
      'AC',
      'Wifi',
      'Kasur',
      'Lemari',
      'Meja',
      'TV',
      'Dapur',
      'Ruang Tamu',
      'Kulkas',
    ],
    facilityTags: ['Kenyamanan', 'Wifi', 'Lokasi', 'Keamanan'],
    aiSummary:
        'Kos premium dengan lingkungan asri dan tenang. Fasilitas bersama lengkap termasuk dapur dan ruang tamu. Cocok untuk yang mengutamakan kenyamanan.',
    positiveHighlights: [
      'Lingkungan asri dan tenang',
      'Dapur dan ruang tamu bersama',
      'Fasilitas premium lengkap',
    ],
    negativeHighlights: [
      'Agak jauh dari kampus',
      'Harga di atas rata-rata',
      'Parkir mobil terbatas',
    ],
    topikDibahas: ['Kenyamanan', 'Lokasi', 'Keamanan', 'Wifi'],
    reviews: [
      KosReview(
        id: 'rev-008',
        userName: 'Maya Putri',
        userRole: 'Mahasiswa',
        rating: 4.5,
        timeAgo: '4 hari lalu',
        content:
            'Suka banget sama suasananya, adem dan tenang. Dapur bersamanya juga lengkap banget!',
        tags: ['Kenyamanan', 'Lokasi'],
      ),
    ],
  ),
};
