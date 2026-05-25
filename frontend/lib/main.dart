import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'providers/task_provider.dart';
import 'views/login_view.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: const DailyTaskApp(),
    ),
  );
}

class DailyTaskApp extends StatelessWidget {
  const DailyTaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Task Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF2C2C2C),
        scaffoldBackgroundColor: const Color(0xFFFAF6EE), // Retro Cream/Beige
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2C2C2C),
          secondary: Color(0xFF4CAF50), // Retro Green
          surface: Color(0xFFFAF6EE),
          error: Color(0xFFFF5252), // Retro Red
        ),
        textTheme: TextTheme(
          displayLarge: GoogleFonts.pressStart2p(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 24),
          titleLarge: GoogleFonts.pressStart2p(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18),
          titleMedium: GoogleFonts.pressStart2p(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 14),
          bodyLarge: const TextStyle(fontFamily: 'Sans-Serif', color: Colors.black87, fontSize: 16),
          bodyMedium: const TextStyle(fontFamily: 'Sans-Serif', color: Colors.black54, fontSize: 14),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.black;
            }
            return Colors.transparent;
          }),
          side: const BorderSide(color: Colors.black, width: 2),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        chipTheme: const ChipThemeData(
          backgroundColor: Colors.white,
          selectedColor: Color(0xFF4CAF50),
          disabledColor: Colors.grey,
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: Colors.black, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFEB3B), // Retro Yellow
            foregroundColor: Colors.black,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: GoogleFonts.pressStart2p(fontWeight: FontWeight.bold, fontSize: 12),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
              side: BorderSide(color: Colors.black, width: 2.5),
            ),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: TextStyle(color: Colors.black38),
          prefixIconColor: Colors.black87,
          suffixIconColor: Colors.black87,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Colors.black, width: 2.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Colors.black, width: 2.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Colors.black, width: 3),
          ),
        ),
      ),
      home: const LoginView(),
    );
  }

  // Helper method to resolve ElevatedButton.styleFrom safely across different Flutter versions
  static ButtonStyle ElevatedButtonFrom({
    required Color backgroundColor,
    required Color foregroundColor,
    required TextStyle textStyle,
    double borderRadius = 0,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: 0,
      textStyle: textStyle,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: const BorderSide(color: Colors.black, width: 2.5),
      ),
    );
  }
}
