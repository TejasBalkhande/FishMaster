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
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:fishmaster/features/auth/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final Set<Marker> _markers = {};
  final Random _random = Random();
  bool _isLoading = true;
  String _currentEffortZone = "Location Not Available";
  bool _isMapCreated = false;
  bool _mapsAvailable = true;

  Map<String, Map<String, int>> _gearTimeLimits = {};

  int lowEffortTimer = 0;
  int mediumEffortTimer = 0;
  int highEffortTimer = 0;
  Timer? _effortTimer;
  Timer? _locationTrackerTimer;

  bool _startedFishing = false;
  List<String> _fishingSessionData = [];
  DateTime? _fishingStartTime;
  final AuthService _authService = Get.find<AuthService>();
  final SupabaseClient _supabase = Supabase.instance.client;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(13.1039, 80.2901),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _checkMapsAvailability();
    _loadFishingEffortData();
    fetchAllOccurrences();
    _loadPorts();
    _getUserLocation();
    _startLocationUpdates();
    _loadGearTimeLimits();
    _updateCurrentZone();
  }

  void _checkMapsAvailability() {
    if (kIsWeb) {
      // Check if Google Maps is available on web
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _mapsAvailable = true; // Assume available, will catch errors in map creation
          });
        }
      });
    }
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
            polylineId: const PolylineId('fishing-line'),
            points: [_userLocation!, _markerLocation!],
            color: Colors.deepPurple,
            width: 3,
          ),
        };
      });
    }
  }

  void _loadGearTimeLimits() async {
    try {
      String jsonString = await rootBundle.loadString('assets/gear_time.json');
      Map<String, dynamic> jsonData = jsonDecode(jsonString);

      setState(() {
        _gearTimeLimits = jsonData.map((key, value) =>
            MapEntry(key, Map<String, int>.from(value)));
      });
    } catch (e) {
      print("Error loading gear time limits: $e");
    }
  }

  void _checkTimeExceeded() {
    if (_gearTimeLimits.isEmpty || widget.selectedGear.isEmpty) return;

    final gearLimits = _gearTimeLimits[widget.selectedGear];
    if (gearLimits == null) return;

    if (_currentEffortZone == "Low Effort Zone 🔴") {
      final limit = gearLimits["Low Effort Zone 🔴"] ?? 99999;
      if (lowEffortTimer >= limit * 3600) {
        _showTimeExceededAlert();
      } else if (lowEffortTimer >= (limit * 3600) - 300) {
        _showTimeLimitWarning(limit, lowEffortTimer, "Low Effort Zone 🔴");
      }
    } else if (_currentEffortZone == "Medium Effort Zone 🟡") {
      final limit = gearLimits["Medium Effort Zone 🟡"] ?? 99999;
      if (mediumEffortTimer >= limit * 3600) {
        _showTimeExceededAlert();
      } else if (mediumEffortTimer >= (limit * 3600) - 300) {
        _showTimeLimitWarning(limit, mediumEffortTimer, "Medium Effort Zone 🟡");
      }
    } else if (_currentEffortZone == "High Effort Zone 🟢") {
      final limit = gearLimits["High Effort Zone 🟢"] ?? 99999;
      if (highEffortTimer >= limit * 3600) {
        _showTimeExceededAlert();
      } else if (highEffortTimer >= (limit * 3600) - 300) {
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
            const SizedBox(width: 10),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
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
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.timer, color: color, size: 16),
              const SizedBox(width: 6),
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
        const SnackBar(content: Text("Waiting for GPS location...")),
      );
      return;
    }

    setState(() {
      _startedFishing = true;
      _currentEffortZone = getCurrentEffortZone();
      _fishingStartTime = DateTime.now();
      _fishingSessionData.clear();
    });
    _updatePolyline();

    // Start tracking location every 5 minutes
    _startLocationTracking();

    _effortTimer?.cancel();
    _effortTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (mounted) {
        setState(() {
          if (_currentEffortZone == "Low Effort Zone 🔴") {
            lowEffortTimer++;
          } else if (_currentEffortZone == "Medium Effort Zone 🟡") {
            mediumEffortTimer++;
          } else if (_currentEffortZone == "High Effort Zone 🟢") {
            highEffortTimer++;
          }
        });
        _checkTimeExceeded();
      }
    });
  }

  void _startLocationTracking() {
    // Record initial location
    _recordLocation();

    // Start timer to record location every 5 minutes
    _locationTrackerTimer = Timer.periodic(const Duration(minutes: 5), (Timer t) {
      _recordLocation();
    });
  }

  void _recordLocation() {
    if (_userLocation != null) {
      final now = DateTime.now();
      final locationData = '${_userLocation!.latitude},${_userLocation!.longitude},${now.toIso8601String()}';
      _fishingSessionData.add(locationData);
      print('Recorded location: $locationData');
    }
  }

  Future<void> _stopFishing() async {
    _effortTimer?.cancel();
    _locationTrackerTimer?.cancel();

    if (_fishingSessionData.isNotEmpty && _fishingStartTime != null) {
      await _saveFishingSessionToSupabase();
    }

    setState(() {
      _startedFishing = false;
      _polylines.clear();
      _fishingSessionData.clear();
      _fishingStartTime = null;
    });
  }

  Future<void> _saveFishingSessionToSupabase() async {
    try {
      if (!_authService.isLoggedIn.value) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      final sessionData = {
        'user_id': _authService.currentUser['id'],
        'start_time': _fishingStartTime!.toIso8601String(),
        'end_time': DateTime.now().toIso8601String(),
        'fishing_gear': widget.selectedGear,
        'target_fishes': widget.selectedFishes,
        'location_data': _fishingSessionData.join(';'),
        'total_duration_seconds': highEffortTimer + mediumEffortTimer + lowEffortTimer,
        'low_effort_time': lowEffortTimer,
        'medium_effort_time': mediumEffortTimer,
        'high_effort_time': highEffortTimer,
        'created_at': DateTime.now().toIso8601String(),
      };

      // Correct way to insert data in Supabase Flutter
      final response = await _supabase
          .from('fishing_sessions')
          .insert(sessionData);

      // In newer versions of supabase_flutter, you can just await the insert
      // If there's an error, it will throw an exception

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fishing session saved successfully!')),
      );

      print('Fishing session saved: ${_fishingSessionData.length} location points');

    } catch (e) {
      print('Error saving fishing session: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving fishing session: ${e.toString()}')),
      );
    }
  }

  void _startLocationUpdates() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
          _currentEffortZone = getCurrentEffortZone();
          if (_startedFishing) {
            _updatePolyline();
            _checkTimeExceeded();
          }
        });
      }
    });
  }

  Future<void> _getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ));
        if (mounted) {
          setState(() {
            _userLocation = LatLng(position.latitude, position.longitude);
          });
        }
      }
    } catch (e) {
      print("Error getting user location: $e");
    }
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const double R = 6371e3;
    double lat1 = start.latitude * pi / 180;
    double lat2 = end.latitude * pi / 180;
    double deltaLat = (end.latitude - start.latitude) * pi / 180;
    double deltaLon = (end.longitude - start.longitude) * pi / 180;

    double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) *
            sin(deltaLon / 2) * sin(deltaLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c / 1000;
  }

  void _onMapTapped(LatLng tappedPoint) {
    if (mounted) {
      setState(() {
        _markerLocation = tappedPoint;

        _markers.removeWhere(
                (marker) => marker.markerId.value == "selected-location");
        _markers.add(
          Marker(
            markerId: const MarkerId("selected-location"),
            position: tappedPoint,
            infoWindow: const InfoWindow(title: "Selected Location"),
          ),
        );

        if (_userLocation != null) {
          _distance = _calculateDistance(_userLocation!, tappedPoint);
        }
      });
      if (_startedFishing) {
        _updatePolyline();
      }
    }
  }

  String getCurrentEffortZone() {
    if (_userLocation == null) return "Location Not Available";

    for (var circle in _circles) {
      double distance = _calculateDistance(_userLocation!, circle.center);

      if (distance <= circle.radius / 1000) {
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

  List<String> getScientificNames(String selectedFishes) {
    List<String> localNames =
    selectedFishes.split(',').map((s) => s.trim()).toList();
    List<String> scientificNames = [];

    for (String local in localNames) {
      final matches = fishList
          .where((fish) => fish.localName.toLowerCase() == local.toLowerCase());
      if (matches.isNotEmpty) {
        scientificNames.add(matches.first.scientificName);
      }
    }
    return scientificNames;
  }

  String getLocalName(String scientificName) {
    final matches = fishList.where(
          (fish) => fish.scientificName.toLowerCase() == scientificName.toLowerCase(),
    );
    if (matches.isNotEmpty) {
      return matches.first.localName;
    }
    return scientificName;
  }

  Future<void> fetchOccurrencesForSpecies(String species) async {
    final url =
        'https://api.gbif.org/v1/occurrence/search?scientificName=$species&limit=100';
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
            if (mounted) {
              setState(() {
                _markers.add(marker);
              });
            }
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

      BitmapDescriptor portIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(8, 8)),
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

      if (mounted) {
        setState(() {
          _markers.addAll(portMarkers);
        });
      }
    } catch (e) {
      debugPrint("Error loading ports: $e");
    }
  }

  Future<void> _loadFishingEffortData() async {
    try {
      String jsonString;
      if (kIsWeb) {
        // For web, use a different approach to load assets
        final response = await http.get(Uri.parse('assets/response4.json'));
        if (response.statusCode == 200) {
          jsonString = response.body;
        } else {
          throw Exception('Failed to load asset on web');
        }
      } else {
        // For mobile, use rootBundle
        jsonString = await rootBundle.loadString('assets/response4.json');
      }

      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      final List<dynamic> entries = jsonData['entries'];
      final List<dynamic> fishingData =
      entries[0]['public-global-fishing-effort:v3.0'];

      Set<Circle> circles = {};

      for (var item in fishingData) {
        double lat = (item['lat'] as num).toDouble();
        double lon = (item['lon'] as num).toDouble();
        double hours = (item['hours'] as num).toDouble();

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

      if (mounted) {
        setState(() {
          _circles.addAll(circles);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading fishing effort data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      );
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
        children: [
          const TextSpan(
            text: "High Effort Zone 🟢: ",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: recommendation["High Effort Area"] + "\n\n"),
          const TextSpan(
            text: "Medium Effort Zone 🟡: ",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: recommendation["Medium Effort Area"] + "\n\n"),
          const TextSpan(
            text: "Low Effort Zone 🔴: ",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: recommendation["Low Effort Area"]),
        ],
      ),
    );
  }

  Widget _buildMapWidget() {
    if (!_mapsAvailable) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              "Google Maps Not Available",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Please check your internet connection and try again",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: _initialPosition,
      onMapCreated: (controller) {
        _mapController = controller;
        _isMapCreated = true;
      },
      onCameraMoveStarted: () {
        // Handle map interaction
      },
      circles: _showHeatmap ? _circles : {},
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      onTap: _onMapTapped,
    );
  }

  @override
  void dispose() {
    _effortTimer?.cancel();
    _locationTrackerTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
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
                _buildMapWidget(),
                if (_markerLocation != null && _userLocation != null && targetBearing != null)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CompassWidget(bearing: targetBearing),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 5),
                            ],
                          ),
                          child: Text(
                            "Distance: ${_distance.toStringAsFixed(2)} km",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),

                if (_startedFishing)
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(204),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(thickness: 1, color: Colors.black26),
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
            ),
            child: _startedFishing
                ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 4),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton(
                      onPressed: _stopFishing,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(16, 81, 171, 1.0),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Stop Fishing",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "Zone: $_currentEffortZone",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (_fishingSessionData.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          "Location points recorded: ${_fishingSessionData.length}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
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
                        style: const TextStyle(
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
                            const TextStyle(fontWeight: FontWeight.w500),
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
                          const Color.fromRGBO(16, 81, 171, 1.0),
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
                const SizedBox(height: 3),
                const Text(
                  "Allowed Fishing hours as per zones ",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),
                ListTile(
                  leading: FaIcon(
                    recommendation["icon"],
                    color: recommendation["color"],
                    size: 40,
                  ),
                  title: buildRecommendationMessage(recommendation),
                ),
                const SizedBox(height: 10),
                Center(
                  child: ElevatedButton(
                    onPressed: _startFishing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color.fromRGBO(16, 81, 171, 1.0),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
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
          try {
            LocationPermission permission =
            await Geolocator.checkPermission();
            if (permission == LocationPermission.denied ||
                permission == LocationPermission.deniedForever) {
              permission = await Geolocator.requestPermission();
            }
            if (permission == LocationPermission.whileInUse ||
                permission == LocationPermission.always) {
              Position position = await Geolocator.getCurrentPosition(
                  locationSettings: const LocationSettings(
                    accuracy: LocationAccuracy.high,
                  ));
              _mapController?.animateCamera(
                CameraUpdate.newLatLng(
                  LatLng(position.latitude, position.longitude),
                ),
              );
            }
          } catch (e) {
            print("Error moving to current location: $e");
          }
        },
        backgroundColor: const Color.fromRGBO(16, 81, 171, 1.0),
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}