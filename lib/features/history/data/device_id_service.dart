import 'dart:math';

final String _sessionDeviceId = _generateDeviceId();

/// Returns a session-stable device identifier (UUID v4-like).
/// Generated once per app lifecycle via Dart's lazy top-level initialisation;
/// not persisted across restarts.
String getSessionDeviceId() => _sessionDeviceId;

String _generateDeviceId() {
  final r = Random.secure();
  final b = List.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40; // version 4
  b[8] = (b[8] & 0x3f) | 0x80; // variant
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
      '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}
