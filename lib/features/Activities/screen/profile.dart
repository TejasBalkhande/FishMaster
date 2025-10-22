import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fishmaster/features/auth/auth_service.dart';
import 'package:fishmaster/features/auth/login_page.dart';
import 'package:fishmaster/features/auth/signup_page.dart';

class Profile extends StatefulWidget {
  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final AuthService authService = Get.find<AuthService>();
  final RxBool _isRefreshing = false.obs;

  @override
  void initState() {
    super.initState();
    // Refresh user data when profile page opens
    _refreshUserData();
  }

  Future<void> _refreshUserData() async {
    if (authService.isLoggedIn.value) {
      _isRefreshing.value = true;
      await authService.fetchUserProfile();
      await Future.delayed(Duration(milliseconds: 500)); // Small delay for better UX
      _isRefreshing.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          if (authService.isLoggedIn.value)
            IconButton(
              icon: Obx(() => _isRefreshing.value
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Icon(Icons.refresh)
              ),
              onPressed: _isRefreshing.value ? null : _refreshUserData,
            ),
        ],
      ),
      body: Obx(() {
        // Show loading while checking auth status
        if (authService.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Checking authentication...'),
              ],
            ),
          );
        }

        // Show login/signup options if not logged in
        if (!authService.isLoggedIn.value) {
          return _buildAuthOptions(context);
        }

        // Show user profile data
        final user = authService.currentUser;

        return RefreshIndicator(
          onRefresh: _refreshUserData,
          child: _buildProfileContent(context, user),
        );
      }),
    );
  }

  Widget _buildAuthOptions(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 24),
            Text(
              'Welcome to FishMaster',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please login or create an account to access all features',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.to(() => LoginPage());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromRGBO(16, 81, 171, 1),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Get.to(() => SignUpPage());
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Color.fromRGBO(16, 81, 171, 1)),
                ),
                child: Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(16, 81, 171, 1),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, Map<String, dynamic> user) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color.fromRGBO(16, 81, 171, 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Color.fromRGBO(16, 81, 171, 1),
                  child: Text(
                    _getInitials(user),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  _getFullName(user),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  user['email'] ?? 'No email',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Active',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          // Personal Information
          _buildDetailCard('Personal Information', [
            _buildDetailItem('Email', user['email'] ?? 'N/A'),
            _buildDetailItem('First Name', user['first_name'] ?? 'N/A'),
            _buildDetailItem('Last Name', user['last_name'] ?? 'N/A'),
            _buildDetailItem('Username', user['username'] ?? 'N/A'),
            _buildDetailItem('Phone', user['phone'] ?? 'N/A'),
            _buildDetailItem('Vessel Type', user['vessel_type'] ?? 'N/A'),
          ]),

          SizedBox(height: 16),

          // Location Information
          _buildDetailCard('Location Information', [
            _buildDetailItem('Current Latitude',
                user['current_lat']?.toString() ?? 'N/A (Start fishing to track location)'),
            _buildDetailItem('Current Longitude',
                user['current_lng']?.toString() ?? 'N/A (Start fishing to track location)'),
            if (user['location_updated_at'] != null)
              _buildDetailItem('Last Location Update',
                  _formatDate(user['location_updated_at'])),
          ]),

          SizedBox(height: 16),

          // Account Information
          _buildDetailCard('Account Information', [
            _buildDetailItem('Account Created',
                user['created_at'] != null ? _formatDate(user['created_at']) : 'N/A'),
            _buildDetailItem('Last Updated',
                user['updated_at'] != null ? _formatDate(user['updated_at']) : 'N/A'),
          ]),

          SizedBox(height: 32),

          // Action Buttons
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _refreshUserData,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Color.fromRGBO(16, 81, 171, 1)),
                  ),
                  child: Obx(() => _isRefreshing.value
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text(
                    'Refresh Data',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(16, 81, 171, 1),
                    ),
                  )),
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _showLogoutConfirmation(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIconForSection(title),
                  color: Color.fromRGBO(16, 81, 171, 1),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(16, 81, 171, 1),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: SelectableText(
              value,
              style: TextStyle(
                color: Colors.grey[900],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(Map<String, dynamic> user) {
    final firstName = user['first_name']?.toString() ?? '';
    final lastName = user['last_name']?.toString() ?? '';

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName.substring(0, 1)}${lastName.substring(0, 1)}'.toUpperCase();
    } else if (firstName.isNotEmpty) {
      return firstName.substring(0, 1).toUpperCase();
    } else if (lastName.isNotEmpty) {
      return lastName.substring(0, 1).toUpperCase();
    } else {
      return 'U';
    }
  }

  String _getFullName(Map<String, dynamic> user) {
    final firstName = user['first_name'] ?? '';
    final lastName = user['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    return fullName.isNotEmpty ? fullName : 'Unknown User';
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  IconData _getIconForSection(String title) {
    switch (title) {
      case 'Personal Information':
        return Icons.person;
      case 'Location Information':
        return Icons.location_on;
      case 'Account Information':
        return Icons.account_circle;
      default:
        return Icons.info;
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                authService.logout();
              },
              child: Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}