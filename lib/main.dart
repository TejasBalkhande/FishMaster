import 'dart:async';
import 'package:fishmaster/controllers/global_controller.dart';
import 'package:fishmaster/features/Activities/alerts/geofence_service.dart';
import 'package:fishmaster/features/Activities/controller/homescreen.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeAppWithRetry(); // Initialize the app with retry logic (For cold-boot/1st run after install issue)
}

// Tejas this is a cold-boot/1st run after install issue, so we need to retry the initialization of the app if it fails. This is because the app may not have the necessary permissions or resources available on the first run, and we need to give it a chance to initialize properly before showing the error screen.
// Create a permanent solve for this later (Prolly resource and permission check.)

Future<void> _initializeAppWithRetry({
  int maxRetries = 6,
  int initialDelaySeconds = 1,
}) async {
  int attempt = 0;
  int delaySeconds = initialDelaySeconds;
  while (attempt < maxRetries) {
    try {
      await GetStorage.init();
      await Future.wait([
        Get.putAsync<GeofenceService>(() async {
          final service = GeofenceService();
          await service.init().timeout(Duration(seconds: 5));
          print("Geofence service initialized");
          return service;
        }),
        Get.putAsync<GlobalController>(() async {
          final controller = GlobalController();
          await controller.initialize().timeout(Duration(seconds: 5));
          print("Global controller initialized");
          return controller;
        }),
      ], eagerError: true);

      runApp(const App());
      return; // Success - exit the retry loop
    } catch (e) {
      attempt++;
      print('Initialization attempt $attempt failed: $e');

      if (attempt >= maxRetries) {
        _showFinalErrorScreen(e);
        return;
      }
      // Exponential backoff
      delaySeconds *= 2;
      print('Retrying in $delaySeconds seconds...');
      await Future.delayed(Duration(seconds: delaySeconds));
    }
  }
}

void _showFinalErrorScreen(dynamic error) {
  runApp(MaterialApp(
    home: Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Initialization Failed After Multiple Attempts'),
            Text(error.toString()),
            ElevatedButton(
              onPressed: () => main(),
              child: Text('Retry Manually'),
            ),
          ],
        ),
      ),
    ),
  ));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: Future.delayed(Duration(seconds: 2)), // Minimum splash time
        builder: (context, snapshot) {
          return Obx(() {
            final controller = Get.find<GlobalController>();
            if (controller.isLoading.value) {
              return SplashScreen(
                progress: controller.loadingProgress.value,
                error: controller.error.value,
              );
            }
            return HomeScreen();
          });
        },
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  final double progress;
  final String? error;

  const SplashScreen({super.key, required this.progress, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(value: progress),
              ),
            ),
            SizedBox(height: 20),
            if (error != null) ...[
              Text('Loading your fishing data...'),
              SizedBox(height: 10),
            ] else ...[
              Text('Loading your fishing data...'),
            ],
          ],
        ),
      ),
    );
  }
}
