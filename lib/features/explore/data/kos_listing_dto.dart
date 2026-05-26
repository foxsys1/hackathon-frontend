import 'package:kos_gdgoc/features/explore/domain/kos_listing.dart';
import 'package:geolocator/geolocator.dart';class KosListingDto {
  const KosListingDto({
    required this.id,
    required this.listingName,
    required this.price,
    required this.roomFacilities,
    required this.sharedFacilities,
    required this.listingUrl,
    required this.imageUrl,
    required this.description,
    required this.source,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.isScraped,
    required this.updatedAt,
    this.aiSummary,
  });

  final String id;
  final String listingName;
  final int price;
  final List<String> roomFacilities;
  final List<String> sharedFacilities;
  final String listingUrl;
  final String imageUrl;
  final String description;
  final String source;
  final String address;
  final double? latitude;
  final double? longitude;
  final bool isScraped;
  final DateTime? updatedAt;
  final String? aiSummary;

  factory KosListingDto.fromJson(Map<String, dynamic> json) {
    // Parse coordinates
    double? lat;
    double? lng;
    final coords = json['coordinates'];
    if (coords is Map<String, dynamic>) {
      lat = (coords['lat'] as num?)?.toDouble();
      lng = (coords['lng'] as num?)?.toDouble();
    }

    return KosListingDto(
      id: json['id'] as String? ?? '',
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
      imageUrl: json['image_url'] as String? ?? '',
      description: json['description'] as String? ?? '',
      source: json['source'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: lat,
      longitude: lng,
      isScraped: json['is_scraped'] as bool? ?? false,
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
      aiSummary: json['ai_summary'] as String?,
    );
  }

  KosListing toDomain(int index, {double? userLat, double? userLng}) {
    final domainId = id.isNotEmpty ? id : 'api-${listingUrl.hashCode.abs()}';

    final location =
        address.isNotEmpty ? address : _extractLocation(listingUrl);
    final area = _extractArea(listingUrl);

    final allFacilities = [...roomFacilities, ...sharedFacilities];
    final facilityTags = allFacilities.take(4).toList();

    // Use a short description snippet as AI summary for the card if API doesn't provide one
    final summarySnippet = aiSummary ?? (description.length > 120
        ? '${description.substring(0, 120)}...'
        : description);

    double calculatedDistance = -1.0;
    if (userLat != null && userLng != null && latitude != null && longitude != null) {
      final distMeters = Geolocator.distanceBetween(
        userLat, userLng, latitude!, longitude!
      );
      calculatedDistance = distMeters / 1000.0;
    }

    return KosListing(
      id: domainId,
      name: listingName,
      location: location,
      area: area,
      pricePerMonth: price,
      imageUrl: imageUrl,
      rating: 0.0,
      reviewCount: 0,
      distanceKm: calculatedDistance,
      aiSummary: summarySnippet,
      facilities: allFacilities,
      facilityTags: facilityTags,
      listingUrl: listingUrl,
      description: description,
      source: source,
      address: address,
      latitude: latitude,
      longitude: longitude,
      isScraped: isScraped,
      roomFacilities: roomFacilities,
      sharedFacilities: sharedFacilities,
      updatedAt: updatedAt,
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
