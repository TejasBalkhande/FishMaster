// ignore_for_file: deprecated_member_use

import 'package:fishmaster/controllers/global_controller.dart';
import 'package:fishmaster/features/Activities/screen/chatbot/chatbot.dart';
import 'package:fishmaster/features/Activities/screen/homepage.dart';
import 'package:fishmaster/features/Activities/screen/profile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalController globalController =
      Get.put(GlobalController(), permanent: true);
  int _selectedIndex = 0;
  DateTime? currentBackPressTime;

  final List<Widget> _pages = [
    Homepage(),
    ChatbotPage(),
    Profile(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (globalController.isLoading.value) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      return PopScope(
        canPop: _selectedIndex == 0,
        onPopInvoked: (bool didPop) async {
          if (didPop) return;
          if (_selectedIndex != 0) {
            setState(() {
              _selectedIndex = 0;
            });
            return;
          }
          DateTime now = DateTime.now();
          if (currentBackPressTime == null ||
              now.difference(currentBackPressTime!) >
                  const Duration(seconds: 2)) {
            currentBackPressTime = now;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Press back again to exit'),
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }
          if (mounted) {
            Navigator.of(context).pop();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: _pages[_selectedIndex],
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.only(bottom: 0.0, left: 0.0, right: 0.0),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30.0),
                topRight: Radius.circular(30.0),
              ),
              child: SizedBox(
                height: 60,
                child: NavigationBar(
                  selectedIndex: _selectedIndex,
                  indicatorColor: const Color.fromRGBO(16, 81, 171, 1.0),
                  onDestinationSelected: _onItemTapped,
                  backgroundColor: Colors.white,
                  destinations: [
                    _buildNavItem(Icons.home, "Home", 0),
                    _buildNavItem(Icons.message, "ChatBot", 1),
                    _buildNavItem(Icons.person, "Profile", 2),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
<<<<<<< HEAD
=======
    });
>>>>>>> e0fa1afeefd587ea24a89206cd6abf68bfc87945
  }

  NavigationDestination _buildNavItem(IconData icon, String label, int index) {
    return NavigationDestination(
      icon: Icon(
        icon,
        color: _selectedIndex == index ? Colors.white : Colors.black,
        size: 22,
      ),
      label: label,
    );
  }
}
