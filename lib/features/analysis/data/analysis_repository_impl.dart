import 'dart:convert';
import 'dart:io';

import 'package:kos_gdgoc/core/network/api_service.dart';
import 'package:kos_gdgoc/features/analysis/domain/analysis_state.dart';

class AnalysisRepositoryImpl {
  const AnalysisRepositoryImpl(this._api);
  final ApiService _api;

  /// Submits the full [AnalysisState] to the backend and returns the raw
  /// [ValidationResult] JSON map.
  Future<Map<String, dynamic>> validateListing(AnalysisState state) async {
    final basic = state.basicInfo;
    final qc = state.quickCheck;
    final dc = state.deepCheck;

    final priceCleaned = basic.hargaPerBulan.replaceAll(RegExp(r'\D'), '');
    final priceInt = int.tryParse(priceCleaned) ?? 0;

    final areaName = basic.lokasi.isNotEmpty ? basic.lokasi : 'UGM Yogyakarta';

    final listingData = jsonEncode({
      'listing_name': basic.namaKos.isNotEmpty ? basic.namaKos : 'Kos Listing',
      'area_name': areaName,
      'price': priceInt > 0 ? priceInt : 500000,
      'owner_willing_videocall': qc.videoCallAvailable == TriAnswer.ya,
      if (qc.namaKontak.isNotEmpty) 'contact_name': qc.namaKontak,
      if (qc.namaRekening.isNotEmpty) 'bank_account_name': qc.namaRekening,
      if (qc.hasPhotos != null) 'photos_provided': qc.hasPhotos!.name,
      if (qc.addressSpecific != null &&
          qc.addressSpecific != TriAnswer.tidakTahu)
        'specific_address_provided': qc.addressSpecific == TriAnswer.ya,
      if (qc.transferPressure != null)
        'urgency_level': qc.transferPressure!.name,
      if (qc.hasTestimony != null && qc.hasTestimony != TriAnswer.tidakTahu)
        'has_testimonials': qc.hasTestimony == TriAnswer.ya,
      'room_facilities': basic.fasilitas,
    });

    File? chatFile;
    if (dc.whatsappChatPaths.isNotEmpty) {
      final path = dc.whatsappChatPaths.first;
      final f = File(path);
      if (await f.exists()) chatFile = f;
    }

    final imageFiles = <File>[];
    for (final path in qc.uploadedPhotoPaths) {
      final f = File(path);
      if (await f.exists()) imageFiles.add(f);
    }

    return _api.validateListing(
      listingData: listingData,
      chatFile: chatFile,
      images: imageFiles.isNotEmpty ? imageFiles : null,
    );
  }

  /// Calls extract-url and returns the raw response map.
  Future<Map<String, dynamic>> extractUrl(String url) => _api.extractUrl(url);
}
