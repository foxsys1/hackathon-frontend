import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

int _uploadCounter = 0;

String _nextUploadId() {
  _uploadCounter = (_uploadCounter + 1) % 1000000;
  return '${DateTime.now().microsecondsSinceEpoch}_$_uploadCounter';
}

@immutable
class UploadItem {
  const UploadItem({
    required this.id,
    required this.name,
    required this.kind,
    this.bytes,
    this.path,
    this.mimeType,
  });

  final String id;
  final String name;
  final UploadKind kind;
  final Uint8List? bytes;
  final String? path;
  final String? mimeType;

  bool get hasBytes => bytes != null && bytes!.isNotEmpty;
  bool get hasPath => path != null && path!.isNotEmpty;

  static String newId() => _nextUploadId();
}

enum UploadKind { image, chat }

@immutable
class UploadState {
  const UploadState({
    this.quickCheckImages = const [],
    this.whatsappChats = const [],
    this.testimoniImages = const [],
  });

  final List<UploadItem> quickCheckImages;
  final List<UploadItem> whatsappChats;
  final List<UploadItem> testimoniImages;

  UploadState copyWith({
    List<UploadItem>? quickCheckImages,
    List<UploadItem>? whatsappChats,
    List<UploadItem>? testimoniImages,
  }) {
    return UploadState(
      quickCheckImages: quickCheckImages ?? this.quickCheckImages,
      whatsappChats: whatsappChats ?? this.whatsappChats,
      testimoniImages: testimoniImages ?? this.testimoniImages,
    );
  }
}

final uploadStateProvider =
    StateNotifierProvider<UploadStateNotifier, UploadState>(
  (_) => UploadStateNotifier(),
);

class UploadStateNotifier extends StateNotifier<UploadState> {
  UploadStateNotifier() : super(const UploadState());

  void addQuickCheckImage(UploadItem item) {
    state = state.copyWith(
      quickCheckImages: [...state.quickCheckImages, item],
    );
  }

  void removeQuickCheckImage(String id) {
    state = state.copyWith(
      quickCheckImages:
          state.quickCheckImages.where((i) => i.id != id).toList(),
    );
  }

  void addWhatsappChat(UploadItem item) {
    state = state.copyWith(
      whatsappChats: [...state.whatsappChats, item],
    );
  }

  void removeWhatsappChat(String id) {
    state = state.copyWith(
      whatsappChats: state.whatsappChats.where((i) => i.id != id).toList(),
    );
  }

  void addTestimoniImage(UploadItem item) {
    state = state.copyWith(
      testimoniImages: [...state.testimoniImages, item],
    );
  }

  void removeTestimoniImage(String id) {
    state = state.copyWith(
      testimoniImages: state.testimoniImages.where((i) => i.id != id).toList(),
    );
  }

  void clearAll() => state = const UploadState();
}
