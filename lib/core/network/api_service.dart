import 'package:dio/dio.dart';
import 'package:kos_gdgoc/core/network/dio_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'api_service.g.dart';

@Riverpod(keepAlive: true)
ApiService apiService(ApiServiceRef ref) {
  return ApiService(ref.watch(dioClientProvider));
}

class ApiService {
  ApiService(this._dio);
  final Dio _dio;

  /// Extracts listing metadata from a public kos listing URL.
  Future<Map<String, dynamic>> extractUrl(String url) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/extract-url',
      data: {'url': url},
    );
    return response.data ?? {};
  }

  /// Discovers kos listings for a given area. Returns a raw list of listing maps.
  Future<List<Map<String, dynamic>>> discoverListings(
    String area, {
    int limit = 10,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{'area': area, 'limit': limit};
    if (offset > 0) queryParams['offset'] = offset;
    final response = await _dio.get<dynamic>(
      '/api/v1/discover',
      queryParameters: queryParams,
    );
    final data = response.data;
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    if (data is Map<String, dynamic>) {
      for (final key in ['listings', 'data', 'results']) {
        if (data[key] is List) {
          return (data[key] as List).whereType<Map<String, dynamic>>().toList();
        }
      }
    }
    return [];
  }

  /// Validates a kos listing by sending multipart form data + optional files.
  /// [listingData] – All listing info serialised as a JSON string.
  /// [chatFile] – Optional exported WhatsApp / chat file.
  /// [images] – Optional list of room photo files.
  Future<Map<String, dynamic>> validateListing({
    String? listingData,
    MultipartFile? chatFile,
    List<MultipartFile>? images,
  }) async {
    final formMap = <String, dynamic>{};

    if (listingData != null) formMap['listing_data'] = listingData;

    if (chatFile != null) {
      formMap['chat_file'] = chatFile;
    }

    if (images != null && images.isNotEmpty) {
      formMap['images'] = images;
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/validate-listing',
      data: FormData.fromMap(formMap),
    );
    return response.data ?? {};
  }

  /// Generates a review summary from a list of review strings.
  Future<Map<String, dynamic>> getReviewSummary(
    List<String> reviews,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/review-summary',
      data: {'reviews': reviews},
    );
    return response.data ?? {};
  }

  /// Fetches the validation history list for a given device.
  Future<List<Map<String, dynamic>>> getHistory(
    String deviceId, {
    int limit = 20,
  }) async {
    final response = await _dio.get<dynamic>(
      '/api/v1/history',
      queryParameters: {'device_id': deviceId, 'limit': limit},
    );
    final data = response.data;
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  /// Fetches a single saved validation record by its Firestore document ID.
  Future<Map<String, dynamic>?> getHistoryRecord(String recordId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/history/$recordId',
    );
    return response.data;
  }

  /// Fetches reviews for a given kos from the backend.
  Future<Map<String, dynamic>> getKosReviews(
    String kosId, {
    int limit = 10,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/reviews/$kosId',
      queryParameters: {'limit': limit},
    );
    return response.data ?? {};
  }

  /// Uploads a new review with GPS metadata to verify location
  Future<Map<String, dynamic>> addReview({
    required String kosId,
    required String comment,
    required double userLat,
    required double userLon,
    required double kosLat,
    required double kosLon,
    required MultipartFile photo,
  }) async {
    final formData = FormData.fromMap({
      'kos_id': kosId,
      'comment': comment,
      'user_lat': userLat,
      'user_lon': userLon,
      'kos_lat': kosLat,
      'kos_lon': kosLon,
      'photo': photo,
    });

    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/add-review',
      data: formData,
    );
    return response.data ?? {};
  }

  /// Analyzes reviews to detect scam using AI cross-examination
  Future<Map<String, dynamic>> analyzeReviews({
    required String kosId,
    required List<String> facilities,
    required int price,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/analyze-reviews',
      data: {
        'kos_id': kosId,
        'claims': {
          'fasilitas': facilities,
          'harga': price,
        }
      },
    );
    return response.data ?? {};
  }

  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get<dynamic>('/health');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
