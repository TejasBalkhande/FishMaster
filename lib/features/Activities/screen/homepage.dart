import 'package:fishmaster/controllers/global_controller.dart';
import 'package:fishmaster/features/Activities/fish_name_string/tamilfish.dart';
import 'package:fishmaster/features/Activities/screen/marineweatherpage.dart';
import 'package:fishmaster/features/Activities/screen/searchPage.dart';
import 'package:fishmaster/models/Marine/finalmarineData/marine_data.dart';
import 'package:fishmaster/utils/constants/day_date.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:fishmaster/models/WeatherGeneral/finalweatherData/weather_data.dart';
import 'fishing_area_nearme.dart';

class Fish {
  final String imageUrl;
  final String name;
  final String distance;

  Fish({required this.imageUrl, required this.name, required this.distance});
}

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  HomepageState createState() => HomepageState();
}

class HomepageState extends State<Homepage> {
  final GlobalController globalController = Get.find<GlobalController>();
  String selectedGear = "Hook & Line";
  String searchText = "";

  List<TamilFish> allFishes = fishList;
  // ignore: unused_field
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    WeatherData weather = globalController.getData();
    MarineWeatherData marineWeather = globalController.getMarineData();
    String city = globalController.getCity().value;
    String state = globalController.getState().value;
    int timestamp = DateUtil.getCurrentTimestamp();
    String formattedDate = DateUtil.formatTimestamp(timestamp);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Image.asset(
          'assets/logos/applogo.png',
          height: 60,
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildUserInfo(
              name: "Fishermen",
              message: "It's a great day to go fishing!",
            ),
            const SizedBox(height: 30),
            _buildLocalWeather(
              location: "$city, $state",
              date: formattedDate,
              temperature:
                  "${weather.current?.current.temp?.toStringAsFixed(1) ?? 'N/A'}°C",
              rainLevel:
                  "${weather.minutely?.minutely.firstOrNull?.precipitation ?? 'N/A'}",
              waveHeight:
                  "${marineWeather.current?.current.waveHeight?.toStringAsFixed(1) ?? 'N/A'} ${marineWeather.currentunits?.currentunits.waveHeight ?? ''}",
              ssT:
                  "${marineWeather.current?.current.seaSurfaceTemperature?.toStringAsFixed(1) ?? 'N/A'} ${marineWeather.currentunits?.currentunits.seaSurfaceTemperature ?? ''}",
              windSpeed:
                  "${weather.current?.current.windSpeed?.toStringAsFixed(1) ?? 'N/A'} m/s",
            ),
            const SizedBox(height: 20),
            _buildSearchBar(context),
            const SizedBox(height: 20),
            _buildGearSelectionAndLocateButton(),
            const SizedBox(height: 20),
            _buildSectionTitle("Available Fishes"),
            const SizedBox(height: 10),
            _buildCarousel(allFishes),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo({required String name, required String message}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Hey! ',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87),
            ),
            Text(
              name,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color.fromRGBO(16, 81, 171, 1.0)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildLocalWeather({
    required String location,
    required String date,
    required String temperature,
    required String rainLevel,
    required String waveHeight,
    required String ssT,
    required String windSpeed,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(16, 81, 171, 1.0),
            blurRadius: 6,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location and Date Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                location,
                style: const TextStyle(
                  fontSize: 20, // Increased font size
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(16, 81, 171, 1.0),
                ),
              ),
              const SizedBox(height: 4), // Spacing between location and date
              Text(
                date,
                style: const TextStyle(
                  fontSize: 16, // Slightly larger for better visibility
                  color: Colors.black,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Temperature and Weather Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.thermostat, color: Colors.red, size: 26),
                  const SizedBox(width: 6),
                  Text(
                    temperature,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.wb_sunny, size: 40, color: Colors.amber),
            ],
          ),

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildWeatherInfo(Icons.water_drop, "Rain", "$rainLevel mm/hr"),
              _buildWeatherInfo(Icons.waves, "Waves", waveHeight),
              _buildWeatherInfo(Icons.thermostat, "SST", ssT),
              _buildWeatherInfo(Icons.air, "Wind", "$windSpeed "),
            ],
          ),

          const SizedBox(height: 16),

          Align(
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MarinePage()),
                );
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Marine Weather",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(16, 81, 171, 1.0),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 22, color: Colors.blue),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherInfo(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 22, color: Color.fromRGBO(16, 81, 171, 1.0)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final List<TamilFish>? selectedFishes = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SearchPage()),
        );
        print("Selected fishes: $selectedFishes");
        if (selectedFishes != null && selectedFishes.isNotEmpty) {
          setState(() {
            searchText =
                selectedFishes.map((fish) => fish.localName).join(", ");
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Color.fromRGBO(16, 81, 171, 1.0).withAlpha(51), blurRadius: 6),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Color.fromRGBO(16, 81, 171, 1.0), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                searchText.isNotEmpty
                    ? searchText
                    : "Search for specific fishes...",
                style: const TextStyle(fontSize: 14, color: Color.fromRGBO(16, 81, 171, 1.0)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGearSelectionAndLocateButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(color: Colors.grey.withAlpha(26), blurRadius: 4)
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedGear,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedGear = newValue!;
                  });
                },
                style: const TextStyle(fontSize: 16, color: Color.fromRGBO(16, 81, 171, 1.0)),
                icon: const Icon(Icons.arrow_drop_down, color: Color.fromRGBO(16, 81, 171, 1.0)),
                isExpanded: true,
                items: [
                  DropdownMenuItem(
                    value: "Hook & Line",
                    child: Row(
                      children: const [
                        FaIcon(FontAwesomeIcons.fish,
                            color: Color.fromRGBO(16, 81, 171, 1.0), size: 20),
                        SizedBox(width: 8),
                        Text("Hook & Line", style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: "Gillnets",
                    child: Row(
                      children: const [
                        Icon(Icons.grid_3x3, color: Color.fromRGBO(16, 81, 171, 1.0), size: 20),
                        SizedBox(width: 8),
                        Text("Gillnets", style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: "Longlines",
                    child: Row(
                      children: const [
                        Icon(Icons.line_weight,
                            color: Color.fromRGBO(16, 81, 171, 1.0), size: 20),
                        SizedBox(width: 8),
                        Text("Longlines", style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: "Trawling",
                    child: Row(
                      children: const [
                        Icon(Icons.directions_boat,
                            color: Color.fromRGBO(16, 81, 171, 1.0), size: 20),
                        SizedBox(width: 8),
                        Text("Trawling", style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: "Purse Seining",
                    child: Row(
                      children: const [
                        Icon(Icons.anchor, color: Color.fromRGBO(16, 81, 171, 1.0), size: 20),
                        SizedBox(width: 8),
                        Text("Purse Seining", style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FishingAreaNearby(
                    selectedGear: selectedGear,
                    selectedFishes: searchText,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromRGBO(16, 81, 171, 1.0),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text(
                  "Fishing Area",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

  }

  Widget _buildSectionTitle(String title) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color:Colors.black87),
      ),
    );
  }

  Widget _buildCarousel(List<TamilFish> fishList) {
    return CarouselSlider.builder(
      itemCount: fishList.length,
      options: CarouselOptions(
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 5),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        height: 180.0,
        enlargeCenterPage: true,
        onPageChanged: (index, reason) => setState(() => _currentIndex = index),
      ),
      itemBuilder: (context, index, realIndex) {
        TamilFish fish = fishList[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 5.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            image: DecorationImage(
              image: AssetImage(fish.imagePath),
              fit: BoxFit.cover,
            ),
          ),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(102),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fish.localName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    fish.scientificName,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
