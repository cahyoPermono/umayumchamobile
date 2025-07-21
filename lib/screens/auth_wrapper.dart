import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:umayumcha/controllers/auth_controller.dart';
import 'package:umayumcha/screens/dashboard_screen.dart';
import 'package:umayumcha/screens/sign_in_screen.dart';
import 'package:umayumcha/screens/splash_screen.dart';

class AuthWrapper extends GetView<AuthController> {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // While the auth controller is loading, show the splash screen
      if (controller.isLoading.value) {
        return const SplashScreen();
      }
      // If the user is logged in, show the dashboard
      if (controller.currentUser.value != null) {
        return const DashboardScreen();
      }
      // Otherwise, show the sign-in screen
      return const SignInScreen();
    });
  }
}
