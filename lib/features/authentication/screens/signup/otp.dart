import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';
import 'package:fishmaster/utils/constants/sizes.dart';
import 'package:fishmaster/features/Activities/controller/homescreen.dart';

class OTPVerificationScreen extends StatefulWidget {
  const OTPVerificationScreen({super.key});

  @override
  OTPVerificationScreenState createState() => OTPVerificationScreenState();
}

class OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController otpController = TextEditingController();
  bool isResendActive = false;
  int secondsRemaining = 30;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          if (secondsRemaining > 0) {
            secondsRemaining--;
            startTimer();
          } else {
            isResendActive = true;
          }
        });
      }
    });
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
                    "Enter OTP",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: FSizes.sm),
                  Text(
                    "A 6-digit OTP has been sent to your phone number.",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),

              const SizedBox(height: FSizes.spaceBtwSections),

              // OTP Input Field
              TextFormField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: customInputDecoration("Enter OTP", Iconsax.key),
              ),

              const SizedBox(height: FSizes.spaceBtwItems),

              // Resend OTP Section
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Didn't receive the OTP? "),
                  TextButton(
                    onPressed: isResendActive ? () {} : null,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color.fromRGBO(51, 108, 138, 1),
                    ),
                    child: Text(isResendActive
                        ? "Resend OTP"
                        : "Resend in $secondsRemaining sec"),
                  ),
                ],
              ),

              const SizedBox(height: FSizes.spaceBtwSections),

              // Verify OTP Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.to(() => const HomeScreen());
                  },
                  child: const Text("Verify OTP"),
                ),
              ),

              const SizedBox(height: FSizes.spaceBtwItems),
            ],
          ),
        ),
      ),
    );
  }
}
