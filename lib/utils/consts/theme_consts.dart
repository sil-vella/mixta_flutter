import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF1C1B2E); // Dark Slate Blue
  static const Color accentColor = Color(0xFF8A4090); // Light Purple (Accent)
  static const Color accentColor2 = Color(0xFFFBC02D); // Soft Yellowish Accent
  static const Color scaffoldBackgroundColor =
  Color(0xFF1C1B2E); // Dark Slate Blue for background
  static const Color white = Colors.white; // White text
  static const Color lightGray = Color(0xFFB0BEC5);
  static const Color redAccent = Colors.redAccent; // Error text color

}

class AppTextStyles {
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16,
    color: AppColors.white,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.white, // Use white text for buttons
  );
}

class AppPadding {
  static const EdgeInsets defaultPadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardPadding =
  EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      primaryColor: AppColors.primaryColor,
      hintColor: AppColors.accentColor,
      scaffoldBackgroundColor: AppColors.scaffoldBackgroundColor,

      // Apply global text theme
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodyLarge: TextStyle(color: AppColors.white), // Input text style
      ),

      // TextButton global style
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: AppTextStyles.buttonText,
          backgroundColor: AppColors.accentColor,
          padding: AppPadding.defaultPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),

      // ElevatedButton global style
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: AppTextStyles.buttonText,
          backgroundColor: AppColors.accentColor,
          padding: AppPadding.defaultPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),

      // InputDecoration global style
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.primaryColor,
        // Background color of input
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.lightGray),
          borderRadius: BorderRadius.circular(8.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.lightGray),
          borderRadius: BorderRadius.circular(8.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.accentColor),
          borderRadius: BorderRadius.circular(8.0),
        ),
        labelStyle: const TextStyle(color: AppColors.white),
        // Label text color
        hintStyle: const TextStyle(color: AppColors.lightGray),
        // Hint text color
        errorStyle: const TextStyle(color: AppColors.redAccent),
        // Error text color
        contentPadding: AppPadding.defaultPadding,
      ),

      // Customizing the cursor and text selection globally
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.accentColor,
        // Cursor color
        selectionColor: AppColors.accentColor.withOpacity(0.5),
        // Selection color
        selectionHandleColor: AppColors.accentColor, // Handle color
      ),
    );
  }
}
