import 'package:fishmaster/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fishmaster/features/authentication/auth_service.dart';
import 'package:fishmaster/features/Activities/controller/homescreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});



  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  bool _isChecked = false; // Checkbox state
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();
  }

  Future<void> _loadSavedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isChecked = prefs.getBool('remember_me') ?? false;
      if (_isChecked) {
        _emailController.text = prefs.getString('remembered_email') ?? '';
      }
    });
  }

  void _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    try {
      final user = await _authService.signIn(email, password);
      if (user != null && mounted) {
        final prefs = await SharedPreferences.getInstance(); // Add this line
        if (_isChecked) {
          await prefs.setBool('remember_me', true);
          await prefs.setString('remembered_email', email);
        } else {
          await prefs.setBool('remember_me', false);
          await prefs.remove('remembered_email');
        }
        Get.to(() => HomeScreen());
      }
    }on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  void _handleAuthError(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'invalid-email':
        message = "Invalid email format";
        break;
      case 'user-disabled':
        message = "Account disabled";
        break;
      case 'user-not-found':
        message = "Account not found";
        break;
      case 'wrong-password':
        message = "Incorrect password";
        break;
      default:
        message = "Login failed: ${e.message}";
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }



  InputDecoration customInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Image(
                    height: 150,
                    image: AssetImage('assets/logos/FishMaster.png'),
                  ),
                  Text(
                    "Welcome Back",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: FSizes.sm),
                  Text(
                    "Find the best location for fishing without crossing the border unintentionally.",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),

              Form(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: FSizes.spaceBtwSections),
                  child: Column(
                    children: [
                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: customInputDecoration(
                            "Email", Iconsax.direct_right),
                      ),
                      const SizedBox(height: FSizes.spaceBtwInputFields),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: customInputDecoration(
                                "Password", Iconsax.password_check)
                            .copyWith(
                                suffixIcon: const Icon(Iconsax.eye_slash)),
                      ),
                      const SizedBox(height: FSizes.spaceBtwInputFields / 2),

                      // Remember Me & Forget Password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Remember Me
                          Row(
                            children: [
                              Checkbox(
                                value: _isChecked,
                                onChanged: (value) {
                                  setState(() {
                                    _isChecked = value!;
                                  });
                                },
                                activeColor:
                                    const Color.fromRGBO(51, 108, 138, 1),
                              ),
                              const Text("Remember Me"),
                            ],
                          ),

                        ],
                      ),
                      const SizedBox(height: FSizes.spaceBtwSections),

                      // Sign In Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _signIn,
                          child: const Text("Sign In"),
                        ),
                      ),
                      const SizedBox(height: FSizes.spaceBtwItems),

                      // Create Account Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Get.toNamed('/signup');
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 17),
                            side: const BorderSide(
                                color: Color.fromRGBO(130, 130, 130, 1)),
                            foregroundColor: const Color.fromRGBO(1, 1, 1, 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Create Account",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: FSizes.spaceBtwItems),
                    ],
                  ),
                ),
              ),

              // Divider
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Flexible(
                    child: Divider(
                      color: Colors.grey,
                      thickness: 0.5,
                      indent: 60,
                      endIndent: 5,
                    ),
                  ),
                  Text("Or Sign In with",
                      style: Theme.of(context).textTheme.labelMedium),
                  const Flexible(
                    child: Divider(
                      color: Colors.grey,
                      thickness: 0.5,
                      indent: 5,
                      endIndent: 60,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: FSizes.spaceBtwSections),

              // Social Login Button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Image(
                        width: FSizes.iconMd,
                        height: FSizes.iconMd,
                        image: AssetImage("assets/logos/googleLogo.png"),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
