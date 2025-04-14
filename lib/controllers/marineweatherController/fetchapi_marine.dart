import 'dart:convert';
import 'package:fishmaster/controllers/marineweatherController/apiurl.dart';
import 'package:fishmaster/models/Marine/finalmarineData/marine_current.dart';
import 'package:fishmaster/models/Marine/finalmarineData/marine_daily.dart';
import 'package:fishmaster/models/Marine/finalmarineData/marine_dailyunits.dart';
import 'package:fishmaster/models/Marine/finalmarineData/marine_data.dart';
import 'package:fishmaster/models/Marine/finalmarineData/marine_hourly.dart';
import 'package:fishmaster/models/Marine/finalmarineData/marine_hourlyunits.dart';
import 'package:http/http.dart' as http;

import '../../models/Marine/finalmarineData/marine_currentunits.dart';

class FetchMarineAPI {
  MarineWeatherData? marineData;

  Future<MarineWeatherData?> processData(lat, long) async {
    var response = await http.get(Uri.parse(apiURL(lat, long)));
    var jsonString = jsonDecode(response.body);
    marineData = MarineWeatherData(
        MarineDataCurrent.fromJson(jsonString),
        MarineDataHourly.fromJson(jsonString),
        MarineDataDaily.fromJson(jsonString),
        MarineDataCurrentUnits.fromJson(jsonString),
        MarineDataHourlyUnits.fromJson(jsonString),
        MarineDataDailyUnits.fromJson(jsonString));
    return marineData;
  }
}
