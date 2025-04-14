import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:fishmaster/features/Activities/fish_name_string/tamilfish.dart';
import '../compass/compass_widget.dart';
import '../compass/location_utils.dart';

class FishingAreaNearby extends StatefulWidget {
  final String selectedGear;
  final String selectedFishes;

  const FishingAreaNearby({super.key, required this.selectedGear, required this.selectedFishes});

  @override
  FishingAreaNearbyState createState() => FishingAreaNearbyState();
}

class FishingAreaNearbyState extends State<FishingAreaNearby> {


  bool _showHeatmap = true;
  LatLng? _userLocation;
  LatLng? _markerLocation;
  Set<Polyline> _polylines = {};
  double _distance = 0.0;
  GoogleMapController? _mapController;
  final Set<Circle> _circles = {};
  final Set<Marker> _markers = {}; // Markers set for fish occurrences
  final Random _random = Random();
  bool _isLoading = true;
  String _currentEffortZone = "Location Not Available";


  Map<String, Map<String, int>> _gearTimeLimits = {}; // Holds time limits from JSON

  int lowEffortTimer = 0;
  int mediumEffortTimer = 0;
  int highEffortTimer = 0;
  Timer? _effortTimer;





  // Add a state variable to track if fishing has started
  bool _startedFishing = false;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(13.1039, 80.2901),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _loadFishingEffortData();
    // Start fetching occurrences after converting local names to scientific names.
    fetchAllOccurrences();
    _loadPorts();
    _getUserLocation();
    _startLocationUpdates();
    _loadGearTimeLimits();
    _updateCurrentZone();
  }

  void _updateCurrentZone() {
    if (_userLocation != null) {
      setState(() {
        _currentEffortZone = getCurrentEffortZone();
      });
    }
  }


  void _updatePolyline() {
    if (_userLocation != null && _markerLocation != null) {
      setState(() {
        _polylines = {
          Polyline(
            polylineId: PolylineId('fishing-line'),
            points: [_userLocation!, _markerLocation!],
            color: Colors.deepPurple,
            width: 3,
          ),
        };
      });
    }
  }

  void _loadGearTimeLimits() async {
    String jsonString = await rootBundle.loadString('assets/gear_time.json');
    Map<String, dynamic> jsonData = jsonDecode(jsonString);

    setState(() {
      _gearTimeLimits = jsonData.map((key, value) =>
          MapEntry(key, Map<String, int>.from(value)));
    });
  }

  void _checkTimeExceeded() {
    if (_gearTimeLimits.isEmpty || widget.selectedGear.isEmpty) return;

    final gearLimits = _gearTimeLimits[widget.selectedGear];
    if (gearLimits == null) return;

    if (_currentEffortZone == "Low Effort Zone 🔴") {
      final limit = gearLimits["Low Effort Zone 🔴"] ?? 99999;
      if (lowEffortTimer >= limit * 3600) {
        _showTimeExceededAlert();
      } else if (lowEffortTimer >= (limit * 3600) - 300) { // 5 minute warning
        _showTimeLimitWarning(limit, lowEffortTimer, "Low Effort Zone 🔴");
      }
    }
    else if (_currentEffortZone == "Medium Effort Zone 🟡") {
      final limit = gearLimits["Medium Effort Zone 🟡"] ?? 99999;
      if (mediumEffortTimer >= limit * 3600) {
        _showTimeExceededAlert();
      } else if (mediumEffortTimer >= (limit * 3600) - 300) { // 5 minute warning
        _showTimeLimitWarning(limit, mediumEffortTimer, "Medium Effort Zone 🟡");
      }
    }
    else if (_currentEffortZone == "High Effort Zone 🟢") {
      final limit = gearLimits["High Effort Zone 🟢"] ?? 99999;
      if (highEffortTimer >= limit * 3600) {
        _showTimeExceededAlert();
      } else if (highEffortTimer >= (limit * 3600) - 300) { // 5 minute warning
        _showTimeLimitWarning(limit, highEffortTimer, "High Effort Zone 🟢");
      }
    }
  }

  void _showTimeExceededAlert() {
    _showAlert(
      title: "Time Limit Exceeded",
      message: "You have exceeded the allowed fishing time in $_currentEffortZone. "
          "Please move to a different zone or stop fishing.",
      color: Colors.red,
      icon: Icons.timer_off,
    );
  }

  void _showTimeLimitWarning(int limit, int currentTime, String zone) {
    final remaining = (limit * 3600) - currentTime;
    final minutes = (remaining / 60).ceil();

    _showAlert(
      title: "Time Limit Approaching",
      message: "You have $minutes minutes remaining in $zone. "
          "Time limit: $limit hours.",
      color: Colors.orange,
      icon: Icons.timer,
    );
  }

  void _showAlert({
    required String title,
    required String message,
    required Color color,
    required IconData icon,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(width: 10),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }



  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  Widget _buildTimerRow(String label, String time, Color color, double fontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2), // Reduce spacing between rows
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.timer, color: color, size: 16), // Smaller icon
              SizedBox(width: 6), // Reduce spacing between icon and text
              Text(
                label,
                style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500, color: color),
              ),
            ],
          ),
          Text(
            time,
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  void _startFishing() {
    if (_userLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Waiting for GPS location...")),
      );
      return;
    }

    setState(() {
      _startedFishing = true;
      _currentEffortZone = getCurrentEffortZone(); // Ensure zone is set before starting
    });
    _updatePolyline();

    _effortTimer?.cancel(); // Cancel any existing timer
    _effortTimer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      setState(() {
        if (_currentEffortZone == "Low Effort Zone 🔴") {
          lowEffortTimer++;
        } else if (_currentEffortZone == "Medium Effort Zone 🟡") {
          mediumEffortTimer++;
        } else if (_currentEffortZone == "High Effort Zone 🟢") {
          highEffortTimer++;
        }
      });
      _checkTimeExceeded(); // Check time limits every second
    });
  }





  void _startLocationUpdates() {
    Geolocator.getPositionStream(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((Position position) {
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _currentEffortZone = getCurrentEffortZone();
        if (_startedFishing) {
          _updatePolyline();
          _checkTimeExceeded();
        }
      });

    });
  }

  Future<void> _getUserLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
          ),);
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
    }
  }






  double _calculateDistance(LatLng start, LatLng end) {
    const double R = 6371e3; // Earth radius in meters
    double lat1 = start.latitude * pi / 180;
    double lat2 = end.latitude * pi / 180;
    double deltaLat = (end.latitude - start.latitude) * pi / 180;
    double deltaLon = (end.longitude - start.longitude) * pi / 180;

    double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) *
            sin(deltaLon / 2) * sin(deltaLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c / 1000; // Returns distance in km
  }

  void _onMapTapped(LatLng tappedPoint) {
    setState(() {
      _markerLocation = tappedPoint;


      // Clear previous marker if needed and add a new one
      _markers.removeWhere(
              (marker) => marker.markerId.value == "selected-location");
      _markers.add(
        Marker(
          markerId: MarkerId("selected-location"),
          position: tappedPoint,
          infoWindow: InfoWindow(title: "Selected Location"),
        ),
      );

      // Calculate distance if user location is available
      if (_userLocation != null) {
        _distance = _calculateDistance(_userLocation!, tappedPoint);
      }
    });
    if (_startedFishing) {
      _updatePolyline(); // Update polyline if marker is moved after starting
    }
  }

  String getCurrentEffortZone() {
    if (_userLocation == null) return "Location Not Available";

    for (var circle in _circles) {
      double distance = _calculateDistance(_userLocation!, circle.center);

      if (distance <= circle.radius / 1000) { // Convert radius from meters to km
        if (circle.fillColor == Colors.red.withAlpha(76)) {
          return "Low Effort Zone 🔴";
        } else if (circle.fillColor == Colors.yellow.withAlpha(76)) {
          return "Medium Effort Zone 🟡";
        } else if (circle.fillColor == Colors.green.withAlpha(76)) {
          return "High Effort Zone 🟢";
        }
      }
    }
    return "No Fishing Zone ❌";
  }


  // Convert the selectedFishes string (local names) into a list of scientific names
  List<String> getScientificNames(String selectedFishes) {
    // Split by comma and trim spaces
    List<String> localNames =
    selectedFishes.split(',').map((s) => s.trim()).toList();
    List<String> scientificNames = [];

    for (String local in localNames) {
      // Filter fishList for the matching fish (ignoring case)
      final matches = fishList
          .where((fish) => fish.localName.toLowerCase() == local.toLowerCase());
      if (matches.isNotEmpty) {
        scientificNames.add(matches.first.scientificName);
      }
    }
    return scientificNames;
  }

  // Fetch occurrence data for one species from GBIF API and add markers
  // Helper function to get local name from scientific name
  String getLocalName(String scientificName) {
    final matches = fishList.where(
          (fish) => fish.scientificName.toLowerCase() == scientificName.toLowerCase(),
    );
    if (matches.isNotEmpty) {
      return matches.first.localName;
    }
    return scientificName; // Fallback if no match found
  }

  Future<void> fetchOccurrencesForSpecies(String species) async {
    final url =
        'https://api.gbif.org/v1/occurrence/search?scientificName=$species&limit=100000000';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        int counter = 0;
        for (var record in results) {
          if (record.containsKey('decimalLatitude') &&
              record.containsKey('decimalLongitude')) {
            double lat = (record['decimalLatitude'] as num).toDouble();
            double lon = (record['decimalLongitude'] as num).toDouble();
            Marker marker = Marker(
              markerId: MarkerId('$species-$counter'),
              position: LatLng(lat, lon),
              infoWindow: InfoWindow(title: getLocalName(species)),
            );
            setState(() {
              _markers.add(marker);
            });
            counter++;
          }
        }
      } else {
        debugPrint(
            'Error fetching occurrences for $species: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Exception fetching occurrences for $species: $e');
    }
  }

  // Loop through all scientific names and fetch their occurrence data
  Future<void> fetchAllOccurrences() async {
    List<String> scientificNames = getScientificNames(widget.selectedFishes);
    for (String species in scientificNames) {
      await fetchOccurrencesForSpecies(species);
    }
  }

  Future<void> _loadPorts() async {
    try {
      String jsonString = await rootBundle.loadString('assets/ports.json');
      List<dynamic> portList = json.decode(jsonString);

      BitmapDescriptor portIcon = await BitmapDescriptor.asset(
        ImageConfiguration(size: Size(8, 8)),
        'assets/port_icon.png',
      );

      Set<Marker> portMarkers = portList.map((port) {
        return Marker(
          markerId: MarkerId(port['id'].toString()),
          position: LatLng(port['lat'], port['lon']),
          icon: portIcon,
          infoWindow: InfoWindow(title: port['name']),
        );
      }).toSet();

      setState(() {
        _markers.addAll(portMarkers);
      });
    } catch (e) {
      debugPrint("Error loading ports: $e");
    }
  }

  Future<void> _loadFishingEffortData() async {
    try {
      final String jsonString =
      await rootBundle.loadString('assets/response4.json');
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      final List<dynamic> entries = jsonData['entries'];
      final List<dynamic> fishingData =
      entries[0]['public-global-fishing-effort:v3.0'];

      Set<Circle> circles = {};

      for (var item in fishingData) {
        double lat = (item['lat'] as num).toDouble();
        double lon = (item['lon'] as num).toDouble();
        double hours = (item['hours'] as num).toDouble();

        // Slight random offset for visual variety
        lat += _random.nextDouble() * 0.002 - 0.001;
        lon += _random.nextDouble() * 0.002 - 0.001;

        Color baseColor;
        if (hours < 6) {
          baseColor = Colors.red;
        } else if (hours >= 6 && hours <= 20) {
          baseColor = Colors.yellow;
        } else {
          baseColor = Colors.green;
        }

        // Create multiple circles per fishing effort record for a heatmap effect
        for (int i = 0; i < 3; i++) {
          double factor = (i + 1) * 1.5;
          double opacity = 255*(0.3 - (i * 0.1)).clamp(0.1, 0.3);

          circles.add(
            Circle(
              circleId: CircleId('$lat,$lon-$i'),
              center: LatLng(lat, lon),
              radius: (500 + (hours * 40)) * factor,
              fillColor: baseColor.withAlpha(opacity.toInt()),

              strokeColor: Colors.transparent,
            ),
          );
        }
      }

      setState(() {
        _circles.addAll(circles);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading fishing effort data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // The rest of your code for recommendations, UI, etc. remains unchanged.
  Map<String, dynamic> getFishingRecommendation(String gear) {
    switch (gear) {
      case "Hook & Line":
        return {
          "High Effort Area": "Not recommended",
          "Medium Effort Area": "6 hours",
          "Low Effort Area": "12 hours",
          "icon": FontAwesomeIcons.fish,
          "color": Colors.green,
        };
      case "Gillnets":
        return {
          "High Effort Area": "3 hours",
          "Medium Effort Area": "7 hours",
          "Low Effort Area": "10 hours",
          "icon": FontAwesomeIcons.fish,
          "color": Colors.yellow,
        };
      case "Longlines":
        return {
          "High Effort Area": "4 hours",
          "Medium Effort Area": "8 hours",
          "Low Effort Area": "10 hours",
          "icon": FontAwesomeIcons.fish,
          "color": Colors.orange,
        };
      case "Purse Seining":
        return {
          "High Effort Area": "5 hours",
          "Medium Effort Area": "7 hours",
          "Low Effort Area": "8 hours",
          "icon": FontAwesomeIcons.fish,
          "color": Colors.deepOrange,
        };
      case "Trawling":
        return {
          "High Effort Area": "2 hours",
          "Medium Effort Area": "5 hours",
          "Low Effort Area": "7 hours",
          "icon": FontAwesomeIcons.fish,
          "color": Colors.red,
        };
      default:
        return {
          "High Effort Area": "",
          "Medium Effort Area": "",
          "Low Effort Area": "",
          "icon": FontAwesomeIcons.fish,
          "color": Colors.blueGrey,
          "message": "Select a Gear to see fishing time recommendations."
        };
    }
  }

  Widget buildRecommendationMessage(Map<String, dynamic> recommendation) {
    if (recommendation.containsKey("message")) {
      return Text(
        recommendation["message"],
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      );
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
        children: [
          TextSpan(
            text: "High Effort Zone 🟢: ",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: recommendation["High Effort Area"] + "\n\n"),
          TextSpan(
            text: "Medium Effort Zone 🟡: ",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: recommendation["Medium Effort Area"] + "\n\n"),
          TextSpan(
            text: "Low Effort Zone 🔴: ",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: recommendation["Low Effort Area"]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {


    double? targetBearing;
    if (_userLocation != null && _markerLocation != null) {
      targetBearing = calculateBearing(_userLocation!, _markerLocation!);
    }


    final recommendation = getFishingRecommendation(widget.selectedGear);
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/logos/applogo.png',
          height: 50,
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: _initialPosition,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  circles: _showHeatmap ? _circles : {},
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  onTap: _onMapTapped,
                ),
                if (_markerLocation != null && _userLocation != null)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CompassWidget(bearing: targetBearing!),
                        SizedBox(height: 10), // Adjust spacing as needed
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 5),
                            ],
                          ),
                          child: Text(
                            "Distance: ${_distance.toStringAsFixed(2)} km",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_isLoading)
                  Center(child: CircularProgressIndicator()),

                if (_startedFishing)

                  Positioned(
                    top: 20,
                    right: 20,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Reduce padding
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(204), // Reduce opacity
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // Shrink box to fit content
                        crossAxisAlignment: CrossAxisAlignment.start, // Left align content
                        children: [
                          Divider(thickness: 1, color: Colors.black26),
                          _buildTimerRow(" ", _formatTime(highEffortTimer), Colors.green, 14),
                          _buildTimerRow(" ", _formatTime(mediumEffortTimer), Colors.orange, 14),
                          _buildTimerRow(" ", _formatTime(lowEffortTimer), Colors.red, 14),
                        ],
                      ),
                    ),


                  ),

              ],
            ),
          ),
          // The bottom container changes its content based on _startedFishing
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
            ),
            // Check _startedFishing to decide what to display
            child: _startedFishing
                ? Container(
              width: double.infinity, // Makes container full width
              padding: EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 4),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16), // Inner left padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_startedFishing)
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _startedFishing = false;
                            _effortTimer?.cancel();
                            _polylines.clear();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromRGBO(16, 81, 171, 1.0),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          "Stop Fishing",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        "Zone: $_currentEffortZone",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        children: [
                          TextSpan(
                            text: "Fishing Gear: ",
                            style: TextStyle(
                              color: Color.fromRGBO(16, 81, 171, 1.0),
                            ),
                          ),
                          TextSpan(
                            text: widget.selectedGear,
                            style:
                            TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment:
                      CrossAxisAlignment.end,
                      children: [
                        Switch(
                          value: _showHeatmap,
                          activeColor:
                          Color.fromRGBO(16, 81, 171, 1.0),
                          materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                          onChanged: (bool value) {
                            setState(() {
                              _showHeatmap = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 3),
                Text(
                  "Allowed Fishing hours as per zones ",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 5),
                ListTile(
                  leading: FaIcon(
                    recommendation["icon"],
                    color: recommendation["color"],
                    size: 40,
                  ),
                  title: buildRecommendationMessage(recommendation),
                ),
                SizedBox(height: 10),
                Center(
                  child: ElevatedButton(
                   onPressed: _startFishing, // This replaces all the inline code

                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      Color.fromRGBO(16, 81, 171, 1.0),
                      padding: EdgeInsets.symmetric(
                          horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Start Fishing",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          LocationPermission permission =
          await Geolocator.checkPermission();
          if (permission == LocationPermission.denied ||
              permission == LocationPermission.deniedForever) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            Position position = await Geolocator.getCurrentPosition(
                locationSettings: LocationSettings(
                  accuracy: LocationAccuracy.high,
                ),);
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(
                LatLng(position.latitude, position.longitude),
              ),
            );
          }
        },
        backgroundColor: Color.fromRGBO(16, 81, 171, 1.0),
        child: Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}