import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:kos_gdgoc/core/network/api_service.dart';
import 'package:kos_gdgoc/features/history/data/device_id_service.dart';
import 'package:kos_gdgoc/features/analysis/domain/analysis_state.dart';
import 'package:kos_gdgoc/features/analysis/domain/upload_state.dart';

class AnalysisRepositoryImpl {
  const AnalysisRepositoryImpl(this._api);
  final ApiService _api;

  /// Submits the full [AnalysisState] to the backend and returns the raw
  /// [ValidationResult] JSON map.
  Future<Map<String, dynamic>> validateListing(
    AnalysisState state, {
    UploadState? uploads,
    String? imageUrl,
  }) async {
    final basic = state.basicInfo;
    final qc = state.quickCheck;
    final dc = state.deepCheck;
    final uploadState = uploads ?? const UploadState();

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
      'image_url': imageUrl ?? '',
    });

    final chatFile = await _resolveChatFile(uploadState, dc);
    final imageFiles = await _resolveImageFiles(uploadState, qc, dc);

    return _api.validateListing(
      listingData: listingData,
      chatFile: chatFile,
      images: imageFiles.isNotEmpty ? imageFiles : null,
    );
  }

  Future<MultipartFile?> _resolveChatFile(
    UploadState uploads,
    DeepCheck dc,
  ) async {
    if (uploads.whatsappChats.isNotEmpty) {
      return _toMultipart(uploads.whatsappChats.first);
    }

    if (dc.whatsappChatPaths.isNotEmpty) {
      final path = dc.whatsappChatPaths.first;
      if (path.trim().isNotEmpty) {
        return MultipartFile.fromFile(path, filename: _safeBasename(path));
      }
    }

    return null;
  }

  Future<List<MultipartFile>> _resolveImageFiles(
    UploadState uploads,
    QuickCheck qc,
    DeepCheck dc,
  ) async {
    final items = <UploadItem>[
      ...uploads.quickCheckImages,
      ...uploads.testimoniImages,
    ];

    if (items.isNotEmpty) {
      final files = <MultipartFile>[];
      for (final item in items) {
        final f = await _toMultipart(item);
        if (f != null) files.add(f);
      }
      return files;
    }

    final legacyPaths = <String>[
      ...qc.uploadedPhotoPaths,
      ...dc.testimoniScreenshotPaths,
    ];

    final files = <MultipartFile>[];
    for (final path in legacyPaths) {
      final trimmed = path.trim();
      if (trimmed.isEmpty) continue;
      files.add(
        await MultipartFile.fromFile(trimmed, filename: _safeBasename(trimmed)),
      );
    }
    return files;
  }

  Future<MultipartFile?> _toMultipart(UploadItem item) async {
    if (item.hasBytes) {
      final name = _safeFileName(item);
      return MultipartFile.fromBytes(item.bytes!, filename: name);
    }

    if (item.hasPath) {
      final name = _safeFileName(item);
      return MultipartFile.fromFile(item.path!, filename: name);
    }

    return null;
  }

  String _safeFileName(UploadItem item) {
    final name = item.name.trim();
    if (name.isNotEmpty) return name;
    if (!item.hasPath) return 'upload.bin';
    return _safeBasename(item.path!);
  }

  String _safeBasename(String path) {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized.split('/');
    return parts.isNotEmpty ? parts.last : path;
  }

  /// Calls extract-url and returns the raw response map.
  Future<Map<String, dynamic>> extractUrl(String url) => _api.extractUrl(url);
}
