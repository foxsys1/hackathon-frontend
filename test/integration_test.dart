import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:kos_gdgoc/core/network/api_service.dart';
import 'package:kos_gdgoc/features/analysis/data/analysis_repository_impl.dart';
import 'package:kos_gdgoc/features/analysis/domain/analysis_state.dart';

void main() {
  test('Actual API Integration Test for validateListing', () async {
    final dio = Dio(BaseOptions(
      baseUrl: 'http://103.27.207.136:8000',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 120),
    ));
    final api = ApiService(dio);
    final repo = AnalysisRepositoryImpl(api);

    final state = AnalysisState(
      basicInfo: const BasicInfo(
        namaKos: 'Kos Integration Test',
        lokasi: 'Pogung Baru, Sleman',
        hargaPerBulan: 'Rp 1.600.000',
        deposit: 'Rp 500.000',
        sumberListing: 'Mamikos',
        deskripsi: 'Tempat nyaman bersih',
        fasilitas: ['AC', 'Wifi'],
      ),
      quickCheck: const QuickCheck(
        surveyOrVideoCallAllowed: TriAnswer.ya,
      ),
    );

    print('Calling validateListing API...');
    try {
      final result = await repo.validateListing(state);
      print('API Response: $result');
      expect(result, isNotNull);
      expect(result['anomaly_score'], isNotNull);
      expect(result['status'], isNotNull);
    } on DioException catch (e) {
      print('DioException status: ${e.response?.statusCode}');
      print('DioException response: ${e.response?.data}');
      print('DioException message: ${e.message}');
      rethrow;
    }
    print('Integration Test Successful!');
  });
}
