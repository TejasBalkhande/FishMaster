import 'package:fishmaster/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';
import 'package:fishmaster/features/authentication/screens/login/login.dart';
import 'package:fishmaster/features/authentication/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  SignupScreenState createState() => SignupScreenState();
}

class SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();






  Future<User?> _signUp() async {
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();
  final firstName = _firstNameController.text.trim();
  final lastName = _lastNameController.text.trim();
  final username = _usernameController.text.trim();

  try {
    User? user = await _authService.signUp(email, password);

    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'firstName': firstName,
          'lastName': lastName,
          'username': username,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) { // Ensure the widget is still mounted before accessing context
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Sign-up successful!")),
          );
        }
        return user;
      } catch (e) {
        await user.delete();
        if (mounted) { // Ensure the widget is still mounted before accessing context
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to save user data: ${e.toString()}")),
          );
        }
        return null;
      }
    }
  } catch (e) {

    if (mounted) { // Ensure the widget is still mounted before accessing context
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sign-up failed: ${e.toString()}")),
      );
    }
    return null;
  }
  return null;
}


  bool _isChecked = false;

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
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Create Your Account",
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: FSizes.spaceBtwSections),
              Form(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration: customInputDecoration(
                                'First Name', Iconsax.user),
                          ),
                        ),
                        const SizedBox(width: FSizes.spaceBtwInputFields),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration: customInputDecoration(
                                'Last Name', Iconsax.user),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: FSizes.spaceBtwInputFields),
                    TextFormField(
                      controller: _usernameController,
                      decoration:
                          customInputDecoration('Username', Iconsax.user_edit),
                    ),
                    const SizedBox(height: FSizes.spaceBtwInputFields),
                    TextFormField(
                      controller: _emailController,
                      decoration:
                          customInputDecoration('E-Mail', Iconsax.direct),
                    ),
                    const SizedBox(height: FSizes.spaceBtwInputFields),
                    TextFormField(
                      decoration:
                          customInputDecoration('Phone Number', Iconsax.call),
                    ),
                    const SizedBox(height: FSizes.spaceBtwInputFields),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: customInputDecoration(
                              'Password', Iconsax.password_check)
                          .copyWith(suffixIcon: const Icon(Iconsax.eye_slash)),
                    ),
                    const SizedBox(height: FSizes.spaceBtwInputFields),
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _isChecked,
                            onChanged: (value) {
                              setState(() {
                                _isChecked = value!;
                              });
                            },
                            activeColor: const Color.fromRGBO(51, 108, 138, 1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'I agree to ',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .apply(
                                        color: Color.fromRGBO(51, 108, 138, 1),
                                        decoration: TextDecoration.underline,
                                      ),
                                ),
                                TextSpan(
                                  text: ' and ',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                TextSpan(
                                  text: 'Terms of Use',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .apply(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: FSizes.spaceBtwSections),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                          onPressed: () async {
                            final user = await _signUp();
                            if (user != null) {
                              Get.to(() => LoginScreen());
                            }
                          },
                        child: const Text("Create Account"),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: FSizes.spaceBtwSections),
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
                  Text("Or Sign Up with",
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
                      icon: Image.asset(
                        "assets/logos/googleLogo.png",
                        width: FSizes.iconMd,
                        height: FSizes.iconMd,
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
//before store