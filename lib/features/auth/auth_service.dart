import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'login_page.dart';

class AuthService extends GetxService {
  static final SupabaseClient supabase = Supabase.instance.client;
  final GetStorage storage = GetStorage();

  final RxBool isLoading = true.obs;
  final RxBool isLoggedIn = false.obs;
  final RxString currentUserId = ''.obs;
  final RxMap<String, dynamic> currentUser = <String, dynamic>{}.obs;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://kunizonmfjouoomyjwcl.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt1bml6b25tZmpvdW9vbXlqd2NsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA3NTUxMzgsImV4cCI6MjA3NjMzMTEzOH0.1wecBf_y0oVNm_W6V8Q-NeudOII_sC2uLySDo7Z5K8c',
    );
    Get.put(AuthService());
  }

  @override
  void onInit() {
    super.onInit();
    checkAuthStatus();
    setupAuthListener();
  }

  Future<void> checkAuthStatus() async {
    try {
      isLoading.value = true;

      final session = supabase.auth.currentSession;
      if (session != null) {
        isLoggedIn.value = true;
        currentUserId.value = session.user.id;
        await fetchUserProfile();
      } else {
        isLoggedIn.value = false;
        currentUser.value = {};
      }
    } catch (e) {
      print('Auth check error: $e');
      isLoggedIn.value = false;
      currentUser.value = {};
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signUp({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
    required String phone,
    required String vesselType,
  }) async {
    try {
      isLoading.value = true;

      // Check if email already exists
      final emailCheck = await supabase
          .from('profiles')
          .select('email')
          .eq('email', email)
          .maybeSingle();

      if (emailCheck != null) {
        throw Exception('Email already registered. Please use a different email.');
      }

      // Check if phone number already exists
      final phoneCheck = await supabase
          .from('profiles')
          .select('phone')
          .eq('phone', phone)
          .maybeSingle();

      if (phoneCheck != null) {
        throw Exception('Phone number already registered. Please use a different phone number.');
      }

      // Check if username already exists
      final usernameCheck = await supabase
          .from('profiles')
          .select('username')
          .eq('username', username)
          .maybeSingle();

      if (usernameCheck != null) {
        throw Exception('Username already taken. Please choose a different username.');
      }

      // Sign up the user
      final AuthResponse response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('User creation failed');
      }

      // Create the profile
      await _createUserProfile(
        userId: response.user!.id,
        email: email,
        firstName: firstName,
        lastName: lastName,
        username: username,
        phone: phone,
        vesselType: vesselType,
      );

      Get.snackbar(
        'Success',
        'Account created successfully! Please login to continue.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

    } catch (e) {
      print('Signup error: $e');
      if (e.toString().contains('row-level security policy')) {
        throw Exception('Database configuration error. Please contact support.');
      } else if (e.toString().contains('already registered') ||
          e.toString().contains('already taken')) {
        rethrow;
      } else if (e.toString().contains('User already registered')) {
        throw Exception('Email already registered. Please use a different email.');
      } else {
        throw Exception('Failed to create account: ${e.toString().replaceAll('Exception: ', '').replaceAll('PostgrestException: ', '')}');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _createUserProfile({
    required String userId,
    required String email,
    required String firstName,
    required String lastName,
    required String username,
    required String phone,
    required String vesselType,
  }) async {
    try {
      final response = await supabase
          .from('profiles')
          .insert({
        'id': userId,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'username': username,
        'phone': phone,
        'vessel_type': vesselType,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      if (response == null) {
        throw Exception('Profile creation failed');
      }

      print('Profile created successfully: $response');
    } catch (e) {
      print('Profile creation error: $e');
      if (e.toString().contains('row-level security policy')) {
        throw Exception('Database security policy prevented profile creation. Please contact support.');
      } else {
        throw Exception('Failed to create user profile: ${e.toString().replaceAll('PostgrestException: ', '')}');
      }
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      isLoading.value = true;

      final AuthResponse response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await handleSuccessfulLogin(response.user!.id);
      }
    } on AuthException catch (e) {
      print('AuthException: ${e.message}');
      if (e.message?.contains('Invalid login credentials') == true) {
        throw Exception('Invalid email or password');
      } else {
        throw Exception('Login failed: ${e.message}');
      }
    } catch (e) {
      print('Login error: $e');
      if (e.toString().contains('Invalid login credentials')) {
        throw Exception('Invalid email or password');
      } else {
        throw Exception('Login failed: ${e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '')}');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> handleSuccessfulLogin(String userId) async {
    currentUserId.value = userId;
    isLoggedIn.value = true;
    await fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', currentUserId.value)
          .single();

      if (response != null) {
        currentUser.value = response as Map<String, dynamic>;
        storage.write('currentUser', currentUser.value);
        print('User profile fetched: ${currentUser.value}');
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      // If profile doesn't exist, create a basic one
      if (e.toString().contains('PGRST116')) {
        print('Profile not found, creating basic profile...');
        await _createBasicProfile();
      }
    }
  }

  Future<void> _createBasicProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase
            .from('profiles')
            .insert({
          'id': user.id,
          'email': user.email,
          'first_name': 'User',
          'last_name': 'Name',
          'username': 'user${user.id.substring(0, 8)}',
          'phone': 'Not provided',
          'vessel_type': 'Not specified',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        await fetchUserProfile(); // Fetch again after creation
      }
    } catch (e) {
      print('Error creating basic profile: $e');
    }
  }

  Future<void> logout() async {
    try {
      await supabase.auth.signOut();
      isLoggedIn.value = false;
      currentUserId.value = '';
      currentUser.value = {};
      storage.remove('currentUser');
      Get.offAllNamed('/'); // Go to home screen after logout
    } catch (e) {
      print('Logout error: $e');
    }
  }

  void setupAuthListener() {
    supabase.auth.onAuthStateChange.listen((AuthState data) {
      final session = data.session;
      if (session != null) {
        isLoggedIn.value = true;
        currentUserId.value = session.user.id;
        fetchUserProfile();
      } else {
        isLoggedIn.value = false;
        currentUserId.value = '';
        currentUser.value = {};
      }
    });
  }

  Future<void> updateLocation(
      double latitude,
      double longitude, {
        double? accuracy,
        double? altitude,
        double? speed,
        double? heading,
      }) async {
    try {
      if (!isLoggedIn.value) return;

      await supabase
          .from('location_history')
          .insert({
        'user_id': currentUserId.value,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'altitude': altitude,
        'speed': speed,
        'heading': heading,
        'timestamp': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });

      await supabase
          .from('profiles')
          .update({
        'current_lat': latitude,
        'current_lng': longitude,
        'location_updated_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', currentUserId.value);

      // Update local user data
      currentUser.value = {
        ...currentUser.value,
        'current_lat': latitude,
        'current_lng': longitude,
        'location_updated_at': DateTime.now().toIso8601String(),
      };

    } catch (e) {
      print('Location update error: $e');
    }
  }
}