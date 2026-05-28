import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the latest extracted `image_url` from the `extract-url` API so
/// other pages (history, analyzing) can read it when persisting records.
final extractedImageProvider = StateProvider<String>((ref) => '');
