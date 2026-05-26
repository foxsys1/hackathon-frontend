import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'location_provider.g.dart';

@riverpod
class UserLocation extends _$UserLocation {
  bool _isTurnedOff = false;

  @override
  FutureOr<Position?> build() async {
    if (_isTurnedOff) return null;

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied by user.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permission denied forever.');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
    } catch (e) {
      print('Geolocator initial request error: $e');
      return null;
    }
  }

  /// Explicitly toggle location on/off
  Future<void> toggleLocation() async {
    _isTurnedOff = !_isTurnedOff;
    if (_isTurnedOff) {
      state = const AsyncData(null);
    } else {
      // Re-trigger the build logic to fetch location again
      ref.invalidateSelf();
    }
  }
}
