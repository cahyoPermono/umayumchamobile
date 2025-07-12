import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umayumcha/controllers/inventory_controller.dart';
import 'package:umayumcha/controllers/delivery_note_controller.dart';
import 'package:umayumcha/screens/splash_screen.dart';
import 'package:umayumcha/supabase_credentials.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  // Initialize core controllers here
  Get.put(InventoryController());
  Get.put(DeliveryNoteController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Umayumcha',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFFE57373), // Soft Red/Terracotta
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFFFCDD2), // Lighter Red
          onPrimaryContainer: Color(0xFFB71C1C),
          secondary: Color(0xFF81C784), // Soft Green
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFFC8E6C9), // Lighter Green
          onSecondaryContainer: Color(0xFF2E7D32),
          tertiary: Color(0xFFFFB74D), // Amber/Orange for accent
          onTertiary: Colors.black,
          tertiaryContainer: Color(0xFFFFECB3),
          onTertiaryContainer: Color(0xFFF57F17),
          error: Color(0xFFB00020),
          onError: Colors.white,
          errorContainer: Color(0xFFFCD8DF),
          onErrorContainer: Color(0xFF880E4F),
          surface: Colors.white, // White Surface for cards/dialogs
          onSurface: Colors.black,
          surfaceContainerHighest: Color(0xFFEEEEEE),
          onSurfaceVariant: Color(0xFF424242),
          outline: Color(0xFFBDBDBD),
          shadow: Colors.black26,
          inverseSurface: Color(0xFF303030),
          onInverseSurface: Colors.white,
          inversePrimary: Color(0xFFEF9A9A),
          surfaceTint: Color(0xFFE57373),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE57373), // Use primary color for app bar
          foregroundColor: Colors.white, // White text on app bar
          elevation: 2, // Subtle shadow
          centerTitle: true,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Slightly rounded corners
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(
              0xFFE57373,
            ), // Primary color for buttons
            foregroundColor: Colors.white, // White text on buttons
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // Rounded button corners
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(
              0xFFE57373,
            ), // Primary color for text buttons
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), // Rounded input fields
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100], // Light gray fill for input fields
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
