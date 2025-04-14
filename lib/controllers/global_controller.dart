import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:fishmaster/controllers/googleapi.dart';
import 'package:fishmaster/models/Marine/finalmarineData/marine_data.dart';
import 'package:fishmaster/models/WeatherGeneral/finalweatherData/weather_data.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:get_storage/get_storage.dart';
import 'package:fishmaster/controllers/marineweatherController/fetchapi_marine.dart';
import 'package:fishmaster/controllers/weatherController/fetchapi_weather.dart';

class GlobalController extends GetxController {
  final isLoading = true.obs;
  final loadingProgress = 0.0.obs;
  final error = RxString(null.toString());
  final lat = 0.0.obs;
  final long = 0.0.obs;
  final city = "".obs;
  final state = "".obs;
  final weatherData = WeatherData().obs;
  final marineData = MarineWeatherData().obs;
  final _storage = GetStorage();
  final _retryCount = 0.obs;

  WeatherData getData() => weatherData.value;
  MarineWeatherData getMarineData() => marineData.value;
  RxDouble fetchLat() => lat;
  RxDouble fetchLong() => long;
  RxString getCity() => city;
  RxString getState() => state;
  RxInt getIndext() => RxInt(0);
  RxBool checkLoading() => isLoading;

  @override
  void onInit() {
    initialize();
    super.onInit();
  }

  Future<void> initialize() async {
    try {
      isLoading.value = true;
      loadingProgress.value = 0.0;
      error.value = null.toString();

      await _loadCachedData();
      loadingProgress.value = 0.2;

      await _getLocation();
      loadingProgress.value = 0.4;

      await _getCityAndState();
      loadingProgress.value = 0.45;

      await _fetchWeatherData();
      loadingProgress.value = 0.8;

      await _fetchMarineData();
      loadingProgress.value = 1.0;

      _cacheData();
    } catch (e) {
      error.value = e.toString();
      _retryCount.value++;
      if (_retryCount.value < 3) {
        await Future.delayed(Duration(seconds: 2));
        await initialize();
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> retry() async {
    _retryCount.value = 0;
    await initialize();
  }

  Future<void> _loadCachedData() async {
    final cached = _storage.read('lastData');
    if (cached != null) {
      lat.value = cached['lat'] ?? lat.value;
      long.value = cached['long'] ?? long.value;
      city.value = cached['city'] ?? city.value;
      state.value = cached['state'] ?? state.value;
    }
  }

  Future<void> _getLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(Duration(seconds: 3));

      lat.value = position.latitude;
      long.value = position.longitude;

      await _getCityAndState();
    } catch (e) {
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        lat.value = lastPosition.latitude;
        long.value = lastPosition.longitude;
      } else {
        throw "Could not get location: $e";
      }
    }
  }

  Future<void> _getCityAndState() async {
    String url =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${lat.value},${long.value}&key=$gAPI";

    try {
      final response =
          await http.get(Uri.parse(url)).timeout(Duration(seconds: 3));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          List components = data['results'][0]['address_components'];

          for (var component in components) {
            List types = component['types'];

            if (types.contains("locality")) {
              city.value = component['long_name'];
            }
            if (types.contains("administrative_area_level_1")) {
              state.value = component['long_name'];
            }
          }
        } else {
          throw "Geocoding API error: ${data['status']}";
        }
      } else {
        throw "HTTP Request Failed: ${response.statusCode}";
      }
    } catch (e) {
      log("Error fetching city and state: $e");
    }
  }

  Future<void> _fetchWeatherData() async {
    try {
      final data = await FetchWeatherAPI()
          .processData(lat.value, long.value)
          .timeout(Duration(seconds: 5));
      if (data == null) throw "Weather data is null";
      weatherData.value = data;
      print("Done1"); // Debugging line to check if data is fetched
    } catch (e) {
      log("Error:$e");
    }
  }

  Future<void> _fetchMarineData() async {
    try {
      final data = await FetchMarineAPI()
          .processData(lat.value, long.value)
          .timeout(Duration(seconds: 5));
      if (data == null) throw "Marine data is null";
      marineData.value = data;
      print("Done2"); // Debugging line to check if data is fetched
    } catch (e) {
      log("Error:$e");
    }
  }

  void _cacheData() {
    _storage.write('lastData', {
      'lat': lat.value,
      'long': long.value,
      'city': city.value,
      'state': state.value,
      'timestamp': DateTime.now().toString(),
    });
    print("Done3"); // Debugging line to check if data is cached
  }
}
