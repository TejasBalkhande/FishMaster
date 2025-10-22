import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fishmaster/features/auth/auth_service.dart';
import 'package:fishmaster/features/auth/login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final AuthService authService = Get.find<AuthService>();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  final List<String> vesselTypes = ['Boat', 'Canoe', 'Ship', 'None', 'Other'];
  String? selectedVesselType;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Create Account'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),

              Text(
                'Fisherman Registration',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(16, 81, 171, 1),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Please fill in your details',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 32),

              // First Name Field
              _buildFormField(
                'First Name',
                firstNameController,
                Icons.person,
                    (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Last Name Field
              _buildFormField(
                'Last Name',
                lastNameController,
                Icons.person_outline,
                    (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Username Field
              _buildFormField(
                'Username',
                usernameController,
                Icons.badge,
                    (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter username';
                  }
                  if (value.length < 3) {
                    return 'Username must be at least 3 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Email Field
              _buildFormField(
                'Email Address',
                emailController,
                Icons.email,
                    (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email address';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Password Field
              _buildPasswordField(
                'Password',
                passwordController,
                _obscurePassword,
                    (value) {
                  setState(() {
                    _obscurePassword = value;
                  });
                },
                    (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Confirm Password Field
              _buildPasswordField(
                'Confirm Password',
                confirmPasswordController,
                _obscureConfirmPassword,
                    (value) {
                  setState(() {
                    _obscureConfirmPassword = value;
                  });
                },
                    (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Phone Field
              _buildFormField(
                'Phone Number',
                phoneController,
                Icons.phone,
                    (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  if (value.length != 10) {
                    return 'Please enter a valid 10-digit phone number';
                  }
                  return null;
                },
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16),

              // Vessel Type Dropdown
              Text(
                'Vessel Type',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedVesselType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Select your vessel type',
                ),
                items: vesselTypes.map((String vessel) {
                  return DropdownMenuItem<String>(
                    value: vessel,
                    child: Text(vessel),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedVesselType = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select vessel type';
                  }
                  return null;
                },
              ),
              SizedBox(height: 32),

              // Sign Up Button
              Obx(() => authService.isLoading.value
                  ? Center(child: CircularProgressIndicator())
                  : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(16, 81, 171, 1),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(
      String label,
      TextEditingController controller,
      IconData icon,
      String? Function(String?) validator, {
        TextInputType keyboardType = TextInputType.text,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: 'Enter your $label',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: Icon(icon),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPasswordField(
      String label,
      TextEditingController controller,
      bool obscureText,
      Function(bool) onVisibilityChanged,
      String? Function(String?) validator) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: 'Enter your $label',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                onVisibilityChanged(!obscureText);
              },
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      if (selectedVesselType == null) {
        Get.snackbar(
          'Error',
          'Please select vessel type',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      try {
        await authService.signUp(
          firstName: firstNameController.text.trim(),
          lastName: lastNameController.text.trim(),
          username: usernameController.text.trim(),
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
          phone: phoneController.text.trim(),
          vesselType: selectedVesselType!,
        );

        // After successful signup, go to login page
        Get.offAll(() => LoginPage());

      } catch (e) {
        String errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('PostgrestException: ', '');

        Get.snackbar(
          'Error',
          errorMessage,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: Duration(seconds: 5),
        );
      }
    }
  }
}