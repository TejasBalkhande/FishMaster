import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fishmaster/controllers/fetchapi.dart';
import 'package:fishmaster/controllers/googleapi.dart';
import 'package:fishmaster/models/Marine/finalmarineData/marine_data.dart';
import 'package:fishmaster/models/WeatherGeneral/finalweatherData/weather_data.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'dart:developer';

class GlobalController extends GetxController {
  final RxBool isLoading = true.obs;
  final RxDouble lat = 0.0.obs;
  final RxDouble long = 0.0.obs;
  final RxInt currentIndex = 0.obs;
  final RxString city = "".obs;
  final RxString state = "".obs;

  RxBool checkLoading() => isLoading;
  RxDouble fetchLat() => lat;
  RxDouble fetchLong() => long;
  RxInt getIndext() => currentIndex;
  RxString getCity() => city;
  RxString getState() => state;

  final marineweatherData = MarineWeatherData().obs;
  final weatherData = WeatherData().obs;

  // ✅ Fixed: Use getter properties instead of missing methods
  WeatherData get weather => weatherData.value;
  MarineWeatherData get marine => marineweatherData.value;

  WeatherData getData() {
    return weatherData.value;
  }

  MarineWeatherData getMarineData() {
    return marineweatherData.value;
  }

  @override
  void onInit() {
    if (isLoading.isTrue) fetchLocation();
    super.onInit();
  }

  fetchLocation() async {
    try {
      bool isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        await Geolocator.openLocationSettings();
        return Future.error("Location services are disabled!");
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        return Future.error("Location permission denied forever!");
      } else if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return Future.error("Location permission denied!");
        }
      }
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      
      log("Raw Position Data: $position");

      lat.value = position.latitude;
      long.value = position.longitude;

      await fetchCityAndState(lat.value, long.value);
      print(city.value);
      print(state.value);

      FetchAPI fetchAPI = FetchAPI();

      try {
        var weather = await fetchAPI.fetchWeatherData(lat.value, long.value);
        if (weather != null) {
          weatherData.value = weather;
          log("Weather Data Fetched Successfully");
        } else {
          log("Error: Failed to fetch weather data.");
        }
      } catch (e) {
        log("Weather API Error: $e");
      }

      try {
        var marine = await fetchAPI.fetchMarineData(lat.value, long.value);
        if (marine != null) {
          marineweatherData.value = marine;
          log("Marine Data Fetched Successfully");
        } else {
          log("Error: Failed to fetch marine data.");
        }
      } catch (e) {
        log("Marine API Error: $e");
      }
      isLoading.value = false;
    } catch (e) {
      log("Error fetching location: $e");
    }
  }
  Future<void> fetchCityAndState(double latitude, double longitude) async { // Replace with your API key
    String url =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$gAPI";

    try {
      final response = await http.get(Uri.parse(url));
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
          print("Fetched Location: City - ${city.value}, State - ${state.value}");
          log("Fetched Location: City - ${city.value}, State - ${state.value}");
        } else {
          print("Error: ${data['status']}");
          log("Error: ${data['status']}");
        }
      } else {
        print("HTTP Request Failed: ${response.statusCode}");
        log("HTTP Request Failed: ${response.statusCode}");
      }
    } catch (e) {
    print("Error fetching city and state: $e");
      log("Error fetching city and state: $e");
    }
  }
}
