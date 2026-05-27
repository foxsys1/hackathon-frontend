import 'dart:convert';
import 'dart:io';

import 'package:kos_gdgoc/core/network/api_service.dart';
import 'package:kos_gdgoc/features/history/data/device_id_service.dart';
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
      'device_id': getSessionDeviceId(),
      'listing_name': basic.namaKos.isNotEmpty ? basic.namaKos : 'Kos Listing',
      'area_name': areaName,
      'price': priceInt > 0 ? priceInt : 500000,
      'address_specificity': qc.addressSpecific?.name ?? 'tidakTahu',
      'photos_match_location': qc.photoMatchLocation?.name ?? 'tidakTahu',
      'info_consistency': qc.infoConsistent?.name ?? 'tidakTahu',
      'dp_requested': qc.dpRequestedBeforeSurvey == TriAnswer.ya,
      'pressure_to_transfer': qc.pressureToTransfer == TriAnswer.ya,
      'owner_willing_videocall': qc.surveyOrVideoCallAllowed == TriAnswer.ya,
      'recent_video_provided': qc.willingToProvideVideo?.name ?? 'tidakTahu',
      'bank_account_name_match': qc.identityConsistent?.name ?? 'tidakTahu',
      'payment_details_explained': qc.paymentDetailsClear?.name ?? 'tidakTahu',
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
    for (final path in dc.testimoniScreenshotPaths) {
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
