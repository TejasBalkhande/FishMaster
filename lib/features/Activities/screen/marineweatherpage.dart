import 'package:fishmaster/controllers/global_controller.dart';
import 'package:fishmaster/models/Marine/finalmarineData/marine_data.dart';
import 'package:fishmaster/models/WeatherGeneral/finalweatherData/weather_data.dart';
import 'package:fishmaster/utils/constants/day_date.dart';
import 'package:fishmaster/utils/wind_direction.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class MarinePage extends StatefulWidget {
  const MarinePage({super.key});

  @override
  MarinePageState createState() => MarinePageState();
}

class MarinePageState extends State<MarinePage> {
  final GlobalController globalController = Get.find<GlobalController>();
  String _safeNum(num? value) => value?.toString() ?? '-';
  String _safeInt(int? value) => value?.toString() ?? '-';

  @override
  Widget build(BuildContext context) {
    WeatherData? weather = globalController.getData();
    MarineWeatherData? marineWeather = globalController.getMarineData();
    String city = globalController.getCity().value;
    int timestamp = DateUtil.getCurrentTimestamp();
    String formattedDate = DateUtil.formatTimestamp(timestamp);
    String cloud = '${_safeInt(weather.current?.current.clouds)}%';
    String temp = '${_safeInt(weather.current?.current.temp?.toInt())}°';
    String windSpeed = '${_safeNum(weather.current?.current.windSpeed)} m/s';
    String windDeg =
        _safeNum(marineWeather.current?.current.windWaveDirection);
    String sst =
        '${_safeNum(marineWeather.current?.current.seaSurfaceTemperature)}°C';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Weather',
            style: TextStyle(color: Colors.black, fontSize: 18)),
        backgroundColor: Colors.grey[100],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            SizedBox(height: 10),
            _buildWeatherTemp(temp),
            _buildWeatherHeader(city, formattedDate),
            _buildWeatherCurrent(windSpeed, windDeg, sst, cloud),
            // _buildTitle("Hourly Marine Weather"),
            // _buildWeatherHourly(marineWeather),
            _buildTitle("Tide Pattern"),
            _buildTidePatternChart(marineWeather),
            _buildTitle("Ocean Current Velocity"),
            _buildOceanCurrentChart(marineWeather),
            _buildTitle("Wave Height"),
            _buildWaveChart(marineWeather),
            _buildTitle("Swell Wave Height"),
            _buildSwellWaveHeightChart(marineWeather),
            _buildTitle("Sea Level Height (MSL)"),
            _buildSeaLevelHeightMslChart(marineWeather),
            _buildTitle("Sea Surface Temperature (SST)"),
            _buildTemperatureChart(marineWeather),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataContainer({double height = 220}) {
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '-',
        style: TextStyle(fontSize: 24, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildTitle(String title) {
    return Container(
      margin: const EdgeInsets.only(left: 0, right: 0, bottom: 15, top: 20),
      alignment: Alignment.topCenter,
      child: Text(
        title,
        style: TextStyle(fontSize: 20, color: Colors.grey[700]),
      ),
    );
  }

  Widget _buildWeatherHeader(String city, String formatedDate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 0, right: 20),
          alignment: Alignment.topLeft,
          child: Text(
            city,
            style: const TextStyle(fontSize: 35, height: 0),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 0, right: 20, bottom: 20),
          alignment: Alignment.topLeft,
          child: Text(
            formatedDate,
            style:
                TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherTemp(String temperature) {
    return Row(
      children: [
        Container(
          margin:
              const EdgeInsets.only(left: 0, right: 20, bottom: 20, top: 10),
          alignment: Alignment.topLeft,
          child: Text(
            temperature,
            style: TextStyle(
                fontSize: 65, height: 0.5, fontWeight: FontWeight.w300),
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherCurrent(
      String windSpeed, String windDeg, String seasurfaceTemperature, String cloud) {
    String direction = windDeg != '-'
        ? WindDirectionUtil.getCardinalDirection(double.tryParse(windDeg) ?? 0)
        : '-';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildWeatherInfoCard('Cloud', cloud),
            _buildWeatherInfoCard('Wind Speed', windSpeed),
            _buildWeatherInfoCard('Direction', direction),
            _buildWeatherInfoCard('SST', seasurfaceTemperature),
          ],
        )
      ],
    );
  }

  Widget _buildWeatherInfoCard(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildWaveChart(MarineWeatherData? marineWeather) {
    // Safely get lists with empty lists as fallback
    List<num> waveHeights = marineWeather?.hourly?.hourly.waveHeight ?? [];
    List<String> timeList = marineWeather?.hourly?.hourly.time ?? [];

    if (waveHeights.isEmpty || timeList.isEmpty) {
      return _buildNoDataContainer();
    }

    List<DateTime> parsedTimes =
        timeList.map((t) => DateTime.parse(t)).toList();
    DateTime now = DateTime.now();
    DateTime startTime = now.subtract(const Duration(hours: 3));
    DateTime endTime = now.add(const Duration(hours: 12));

    List<num> filteredWaveHeights = [];
    List<String> filteredTimeList = [];

    for (int i = 0; i < parsedTimes.length; i++) {
      if (parsedTimes[i].isAfter(startTime) &&
          parsedTimes[i].isBefore(endTime)) {
        filteredWaveHeights.add(waveHeights[i]);
        filteredTimeList.add(timeList[i]);
      }
    }

    if (filteredWaveHeights.isEmpty || filteredTimeList.isEmpty) {
      return _buildNoDataContainer();
    }

    double minWaveHeight =
        filteredWaveHeights.reduce((a, b) => a < b ? a : b).toDouble();
    double maxWaveHeight =
        filteredWaveHeights.reduce((a, b) => a > b ? a : b).toDouble();

    double yMin = (minWaveHeight - 0.3).clamp(0.0, double.infinity);
    double yMax = maxWaveHeight + 0.3;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        height: 220,
        width: filteredWaveHeights.length * 50,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: LineChart(
          LineChartData(
            minY: yMin,
            maxY: yMax,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.withAlpha(76),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                );
              },
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  interval: (yMax - yMin) / 4,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        "${value.toStringAsFixed(1)} m",
                        style:
                            const TextStyle(fontSize: 12, color: Colors.black),
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: (filteredTimeList.length / 6).ceilToDouble(),
                  getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    if (index >= 0 && index < filteredTimeList.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat("h a")
                              .format(DateTime.parse(filteredTimeList[index])),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black, height: 2),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                left: BorderSide(color: Colors.black, width: 1),
                bottom: BorderSide(color: Colors.black, width: 1),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(filteredWaveHeights.length, (index) {
                  return FlSpot(
                      index.toDouble(), filteredWaveHeights[index].toDouble());
                }),
                isCurved: true,
                gradient: LinearGradient(
                  colors: [Colors.blueAccent, Colors.lightBlueAccent],
                ),
                barWidth: 4,
                isStrokeCapRound: true,
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Colors.blueAccent.withAlpha(76),
                      Colors.transparent
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildSeaLevelHeightMslChart(MarineWeatherData? marineWeather) {
    List<num> seaLevelHeights = marineWeather?.hourly?.hourly.seaLevelHeightMsl ?? [];
    List<String> timeList = marineWeather?.hourly?.hourly.time ?? [];

    if (seaLevelHeights.isEmpty || timeList.isEmpty) {
      return _buildNoDataContainer();
    }

    List<DateTime> parsedTimes = timeList.map((t) => DateTime.parse(t)).toList();
    DateTime now = DateTime.now();
    DateTime startTime = now.subtract(const Duration(hours: 3));
    DateTime endTime = now.add(const Duration(hours: 12));

    List<num> filteredSeaLevelHeights = [];
    List<String> filteredTimeList = [];

    for (int i = 0; i < parsedTimes.length; i++) {
      if (parsedTimes[i].isAfter(startTime) && parsedTimes[i].isBefore(endTime)) {
        filteredSeaLevelHeights.add(seaLevelHeights[i]);
        filteredTimeList.add(timeList[i]);
      }
    }

    if (filteredSeaLevelHeights.isEmpty || filteredTimeList.isEmpty) {
      return _buildNoDataContainer();
    }

    double minSeaLevel = filteredSeaLevelHeights.reduce((a, b) => a < b ? a : b).toDouble();
    double maxSeaLevel = filteredSeaLevelHeights.reduce((a, b) => a > b ? a : b).toDouble();

    // Add some padding to the Y axis
    double yMin = (minSeaLevel - 0.2).clamp(0.0, double.infinity);
    double yMax = maxSeaLevel + 0.2;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        height: 240,
        width: filteredSeaLevelHeights.length * 50,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: LineChart(
          LineChartData(
            minY: yMin,
            maxY: yMax,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.withAlpha(76),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                );
              },
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 60,
                  interval: (yMax - yMin) / 4,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        "${value.toStringAsFixed(2)} m",
                        style: const TextStyle(fontSize: 12, color: Colors.black),
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: (filteredTimeList.length / 6).ceilToDouble(),
                  getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    if (index >= 0 && index < filteredTimeList.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat("h a").format(DateTime.parse(filteredTimeList[index])),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black, height: 2),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                left: BorderSide(color: Colors.black, width: 1),
                bottom: BorderSide(color: Colors.black, width: 1),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(filteredSeaLevelHeights.length, (index) {
                  return FlSpot(
                    index.toDouble(),
                    filteredSeaLevelHeights[index].toDouble()
                  );
                }),
                isCurved: true,
                gradient: LinearGradient(
                  colors: [Colors.tealAccent, Colors.teal],
                ),
                barWidth: 4,
                isStrokeCapRound: true,
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Colors.tealAccent.withAlpha(76),
                      Colors.transparent
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildSwellWaveHeightChart(MarineWeatherData? marineWeather) {
    // Safely get lists with empty lists as fallback
    List<num> swellWaveHeights = marineWeather?.hourly?.hourly.swellWaveHeight ?? [];
    List<String> timeList = marineWeather?.hourly?.hourly.time ?? [];

    if (swellWaveHeights.isEmpty || timeList.isEmpty) {
      return _buildNoDataContainer();
    }

    List<DateTime> parsedTimes = timeList.map((t) => DateTime.parse(t)).toList();
    DateTime now = DateTime.now();
    DateTime startTime = now.subtract(const Duration(hours: 3));
    DateTime endTime = now.add(const Duration(hours: 12));

    List<num> filteredSwellWaveHeights = [];
    List<String> filteredTimeList = [];

    for (int i = 0; i < parsedTimes.length; i++) {
      if (parsedTimes[i].isAfter(startTime) && parsedTimes[i].isBefore(endTime)) {
        filteredSwellWaveHeights.add(swellWaveHeights[i]);
        filteredTimeList.add(timeList[i]);
      }
    }

    if (filteredSwellWaveHeights.isEmpty || filteredTimeList.isEmpty) {
      return _buildNoDataContainer() ;
    }

    double minSwellWaveHeight = filteredSwellWaveHeights.reduce((a, b) => a < b ? a : b).toDouble();
    double maxSwellWaveHeight = filteredSwellWaveHeights.reduce((a, b) => a > b ? a : b).toDouble();

    double yMin = (minSwellWaveHeight - 0.3).clamp(0.0, double.infinity);
    double yMax = maxSwellWaveHeight + 0.3;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        height: 220,
        width: filteredSwellWaveHeights.length * 50,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: LineChart(
          LineChartData(
            minY: yMin,
            maxY: yMax,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.withAlpha(76),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                );
              },
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  interval: (yMax - yMin) / 4,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        "${value.toStringAsFixed(1)} m",
                        style: const TextStyle(fontSize: 12, color: Colors.black),
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: (filteredTimeList.length / 6).ceilToDouble(),
                  getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    if (index >= 0 && index < filteredTimeList.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat("h a")
                              .format(DateTime.parse(filteredTimeList[index])),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black, height: 2),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                left: BorderSide(color: Colors.black, width: 1),
                bottom: BorderSide(color: Colors.black, width: 1),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(filteredSwellWaveHeights.length, (index) {
                  return FlSpot(
                      index.toDouble(),
                      filteredSwellWaveHeights[index].toDouble()
                  );
                }),
                isCurved: true,
                gradient: LinearGradient(
                  colors: [Colors.purpleAccent, Colors.deepPurpleAccent],
                ),
                barWidth: 4,
                isStrokeCapRound: true,
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurpleAccent.withAlpha(76),
                      Colors.transparent
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemperatureChart(MarineWeatherData? marineWeather) {
    List<num> temperatures =
        marineWeather?.hourly?.hourly.seaSurfaceTemperature ?? [];
    List<String> timeList = marineWeather?.hourly?.hourly.time ?? [];

    if (temperatures.isEmpty || timeList.isEmpty) {
      return _buildNoDataContainer();
    }

    List<DateTime> parsedTimes =
        timeList.map((t) => DateTime.parse(t)).toList();
    DateTime now = DateTime.now();
    DateTime startTime = now.subtract(const Duration(hours: 3));
    DateTime endTime = now.add(const Duration(hours: 12));

    List<num> filteredTemperatures = [];
    List<String> filteredTimeList = [];

    for (int i = 0; i < parsedTimes.length; i++) {
      if (parsedTimes[i].isAfter(startTime) &&
          parsedTimes[i].isBefore(endTime)) {
        filteredTemperatures.add(temperatures[i]);
        filteredTimeList.add(timeList[i]);
      }
    }

    if (filteredTemperatures.isEmpty || filteredTimeList.isEmpty) {
      return _buildNoDataContainer();
    }

    double minTemp =
        filteredTemperatures.reduce((a, b) => a < b ? a : b).toDouble();
    double maxTemp =
        filteredTemperatures.reduce((a, b) => a > b ? a : b).toDouble();

    double yMin = (minTemp - 0.8).clamp(0.0, double.infinity);
    double yMax = maxTemp + 1.5;

    double yInterval = ((yMax - yMin) / 5).clamp(0.5, 2.0);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        height: 240,
        width: filteredTemperatures.length * 50,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: LineChart(
          LineChartData(
            minY: yMin,
            maxY: yMax,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.withAlpha(76),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 60,
                  interval: yInterval,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        "${value.toStringAsFixed(1)}°C",
                        style:
                            const TextStyle(fontSize: 12, color: Colors.black),
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: (filteredTimeList.length / 6).ceilToDouble(),
                  getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    if (index >= 0 && index < filteredTimeList.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat("h a")
                              .format(DateTime.parse(filteredTimeList[index])),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black, height: 2),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                left: BorderSide(color: Colors.black, width: 1),
                bottom: BorderSide(color: Colors.black, width: 1),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(filteredTemperatures.length, (index) {
                  return FlSpot(
                      index.toDouble(), filteredTemperatures[index].toDouble());
                }),
                isCurved: true,
                gradient: LinearGradient(
                  colors: [Colors.orangeAccent, Colors.deepOrangeAccent],
                ),
                barWidth: 4,
                isStrokeCapRound: true,
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Colors.orangeAccent.withAlpha(76),
                      Colors.transparent
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTidePatternChart(MarineWeatherData? marineWeather) {
    List<num> seaLevelHeight =
        marineWeather?.hourly?.hourly.seaLevelHeightMsl ?? [];
    List<String> timeList = marineWeather?.hourly?.hourly.time ?? [];

    if (seaLevelHeight.isEmpty || timeList.isEmpty) {
      return _buildNoDataContainer();
    }

    List<DateTime> parsedTimes =
        timeList.map((t) => DateTime.parse(t)).toList();
    DateTime now = DateTime.now();
    DateTime startTime = now.subtract(const Duration(hours: 3));
    DateTime endTime = now.add(const Duration(hours: 16));

    List<num> filteredTideHeights = [];
    List<String> filteredTimeList = [];
    for (int i = 0; i < parsedTimes.length; i++) {
      if (parsedTimes[i].isAfter(startTime) &&
          parsedTimes[i].isBefore(endTime)) {
        filteredTideHeights.add(seaLevelHeight[i]);
        filteredTimeList.add(timeList[i]);
      }
    }

    if (filteredTideHeights.isEmpty || filteredTimeList.isEmpty) {
      return _buildNoDataContainer();
    }

    double minTide =
        filteredTideHeights.reduce((a, b) => a < b ? a : b).toDouble();
    double maxTide =
        filteredTideHeights.reduce((a, b) => a > b ? a : b).toDouble();

    double yMin = (minTide - 0.2).clamp(0.0, double.infinity);
    double yMax = maxTide + 0.2;

    double yInterval = ((yMax - yMin) / 5).clamp(0.1, 0.5);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        height: 230,
        width: filteredTideHeights.length * 50,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: LineChart(
          LineChartData(
            minY: yMin,
            maxY: yMax,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey.withAlpha(76),
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 60,
                  interval: yInterval,
                  getTitlesWidget: (value, meta) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text("${value.toStringAsFixed(2)} m",
                        style:
                            const TextStyle(fontSize: 12, color: Colors.black)),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: (filteredTimeList.length / 8).ceilToDouble(),
                  getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    if (index >= 0 && index < filteredTimeList.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat("h a")
                              .format(DateTime.parse(filteredTimeList[index])),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black, height: 2),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(
              show: true,
              border: const Border(
                left: BorderSide(color: Colors.black, width: 1),
                bottom: BorderSide(color: Colors.black, width: 1),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(
                    filteredTideHeights.length,
                    (index) => FlSpot(index.toDouble(),
                        filteredTideHeights[index].toDouble())),
                isCurved: true,
                gradient: LinearGradient(
                  colors: [Colors.blueAccent, Colors.blue],
                ),
                barWidth: 4,
                isStrokeCapRound: true,
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Colors.blueAccent.withAlpha(76),
                      Colors.transparent
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOceanCurrentChart(MarineWeatherData? marineWeather) {
    List<num> oceanCurrentVelocity =
        marineWeather?.hourly?.hourly.oceanCurrentVelocity ?? [];
    List<String> timeList = marineWeather?.hourly?.hourly.time ?? [];

    if (oceanCurrentVelocity.isEmpty || timeList.isEmpty) {
      return _buildNoDataContainer();
    }
    List<DateTime> parsedTimes =
        timeList.map((t) => DateTime.parse(t)).toList();
    DateTime now = DateTime.now();
    DateTime startTime = now.subtract(const Duration(hours: 3));
    DateTime endTime = now.add(const Duration(hours: 16));

    List<num> filteredVelocities = [];
    List<String> filteredTimeList = [];
    for (int i = 0; i < parsedTimes.length; i++) {
      if (parsedTimes[i].isAfter(startTime) &&
          parsedTimes[i].isBefore(endTime)) {
        filteredVelocities.add(oceanCurrentVelocity[i]);
        filteredTimeList.add(timeList[i]);
      }
    }

    if (filteredVelocities.isEmpty || filteredTimeList.isEmpty) {
      return _buildNoDataContainer();
    }

    double minVelocity =
        filteredVelocities.reduce((a, b) => a < b ? a : b).toDouble();
    double maxVelocity =
        filteredVelocities.reduce((a, b) => a > b ? a : b).toDouble();

    double yMin = (minVelocity - 0.2).clamp(0.0, maxVelocity + 0.2);
    double yMax = maxVelocity + 0.3;

    double yInterval = ((yMax - yMin) / 5).clamp(0.1, 0.5);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        height: 220,
        width: filteredVelocities.length * 50,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: LineChart(
          LineChartData(
            minY: yMin,
            maxY: yMax,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey.withAlpha(76),
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 70,
                  interval: yInterval,
                  getTitlesWidget: (value, meta) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text("${value.toStringAsFixed(2)} m/s",
                        style:
                            const TextStyle(fontSize: 12, color: Colors.black)),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: (filteredTimeList.length / 8).ceilToDouble(),
                  getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    if (index >= 0 && index < filteredTimeList.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat("h a")
                              .format(DateTime.parse(filteredTimeList[index])),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black, height: 2),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(
              show: true,
              border: const Border(
                left: BorderSide(color: Colors.black, width: 1),
                bottom: BorderSide(color: Colors.black, width: 1),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(
                    filteredVelocities.length,
                    (index) => FlSpot(index.toDouble(),
                        filteredVelocities[index].toDouble())),
                isCurved: true,
                gradient: LinearGradient(
                  colors: [Colors.greenAccent, Colors.green],
                ),
                barWidth: 4,
                isStrokeCapRound: true,
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Colors.greenAccent.withAlpha(76),
                      Colors.transparent
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}