import 'dart:async'; // Add this import
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:fishmaster/features/auth/auth_service.dart';

class LocationService extends GetxService {
  final AuthService authService = Get.find<AuthService>();
  Timer? _locationTimer;
  final RxBool isTracking = false.obs;

  Future<void> startLocationTracking() async {
    if (isTracking.value) return;

    // Request permission
    await _requestLocationPermission();

    // Start immediate location update
    await _updateLocation();

    // Start periodic updates every 3 minutes
    _locationTimer = Timer.periodic(Duration(minutes: 3), (timer) {
      _updateLocation();
    });

    isTracking.value = true;
    print('Location tracking started');
  }

  Future<void> stopLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
    isTracking.value = false;
    print('Location tracking stopped');
    return Future.value();
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }
  }

  Future<void> _updateLocation() async {
    try {
      if (!authService.isLoggedIn.value) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      await authService.updateLocation(
        position.latitude,
        position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        heading: position.heading,
      );

      print('Location updated: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  @override
  void onClose() {
    stopLocationTracking();
    super.onClose();
  }
}