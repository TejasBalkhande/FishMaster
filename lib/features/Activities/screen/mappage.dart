import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class MapPage extends StatefulWidget {
  final String fishSpecies;

  const MapPage({required this.fishSpecies, super.key});


  @override
  MapPageState createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  List<LatLng> fishLocations = [];
  late GoogleMapController mapController;
  LatLng _currentPosition = LatLng(9.5, 80.3); // Default location
  bool _isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    fetchFishLocations(widget.fishSpecies);
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });

    mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 8)); // Initial zoom-out
  }

  Future<void> fetchFishLocations(String species) async {
    final response = await http.get(Uri.parse(
        'https://api.gbif.org/v1/occurrence/search?scientificName=$species&limit=50'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        fishLocations = (data['results'] as List)
            .where((record) =>
                record.containsKey('decimalLatitude') &&
                record.containsKey('decimalLongitude'))
            .map((record) =>
                LatLng(record['decimalLatitude'], record['decimalLongitude']))
            .toList();
        _isLoading = false; // Stop loading when data is received
      });

      // Zoom in after loading fish locations
      mapController
          .animateCamera(CameraUpdate.newLatLngZoom(_currentPosition, 12));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/logos/fisher.png', // Path to your image
          height: 60, // Adjust the height as needed
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Fish species name below the AppBar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              widget.fishSpecies,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(51, 108, 138, 1),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Map takes up half the screen
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition,
                zoom: 8, // Initial zoom-out
              ),
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              markers: {
                Marker(
                  markerId: MarkerId('current_location'),
                  position: _currentPosition,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueBlue),
                ),
                ...fishLocations.map((loc) => Marker(
                      markerId: MarkerId('${loc.latitude},${loc.longitude}'),
                      position: loc,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed),
                    )),
              },
            ),
          ),

          Expanded(
            child: Center(
              child: Text(
                "Info ",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Loading Indicator
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                color: Color.fromRGBO(51, 108, 138, 1),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        backgroundColor: const Color.fromRGBO(51, 108, 138, 1),
        child: Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}
