import 'package:kos_gdgoc/features/explore/domain/kos_listing.dart';

class KosListingDto {
  const KosListingDto({
    required this.listingName,
    required this.price,
    required this.roomFacilities,
    required this.sharedFacilities,
    required this.listingUrl,
  });

  final String listingName;
  final int price;
  final List<String> roomFacilities;
  final List<String> sharedFacilities;
  final String listingUrl;

  factory KosListingDto.fromJson(Map<String, dynamic> json) {
    return KosListingDto(
      listingName: json['listing_name'] as String? ?? 'Listing Tidak Diketahui',
      price: (json['price'] as num?)?.toInt() ?? 0,
      roomFacilities: (json['room_facilities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      sharedFacilities: (json['shared_facilities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      listingUrl: json['listing_url'] as String? ?? '',
    );
  }

  KosListing toDomain(int index) {
    final id = 'api-${listingUrl.hashCode.abs()}';

    final location = _extractLocation(listingUrl);
    final area = _extractArea(listingUrl);

    final allFacilities = [...roomFacilities, ...sharedFacilities];

    final facilityTags = allFacilities.take(4).toList();

    return KosListing(
      id: id,
      name: listingName,
      location: location,
      area: area,
      pricePerMonth: price,
      imageUrl:
          'https://images.unsplash.com/photo-1555854877-bab0e564b8d5?w=400&h=300&fit=crop',
      rating: 0.0,
      reviewCount: 0,
      distanceKm: 0.0,
      aiSummary: '',
      facilities: allFacilities,
      facilityTags: facilityTags,
      listingUrl: listingUrl,
    );
  }

  String _extractLocation(String url) {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) return 'Lokasi tidak tersedia';
      final segments = uri.pathSegments;
      if (segments.length >= 2) {
        return segments.last
            .replaceAll('-', ' ')
            .split(' ')
            .map((w) =>
                w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .join(' ');
      }
    } catch (_) {}
    return 'Lokasi tidak tersedia';
  }

  String _extractArea(String url) {
    const areaKeywords = [
      'depok',
      'mlati',
      'pogung',
      'condong',
      'gejayan',
      'seturan',
      'babarsari',
      'jakal',
      'demangan',
      'sleman',
    ];
    final lower = url.toLowerCase();
    for (final kw in areaKeywords) {
      if (lower.contains(kw)) {
        return '${kw[0].toUpperCase()}${kw.substring(1)}';
      }
    }
    return 'Yogyakarta';
  }
}
