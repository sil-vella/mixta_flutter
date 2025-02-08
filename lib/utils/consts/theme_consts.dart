import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF1C1B2E); // Dark Slate Blue (Background)
  static const Color accentColor = Color(0xFFCB9C50); // 🌟 Gold Accent
  static const Color accentColor2 = Color(0xFFE4B96F); // ✨ Softer Gold for Highlights
  static const Color scaffoldBackgroundColor = Color(0xFF121212); // 🔥 Deep Black for OLED Displays
  static const Color white = Colors.white;
  static const Color lightGray = Color(0xFFB0BEC5); // 🌫 Cool Gray for Subtle Text
  static const Color redAccent = Colors.redAccent; // ⚠️ Error Color (Kept as-is)
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
  static const EdgeInsets cardPadding = EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      primaryColor: AppColors.primaryColor,
      scaffoldBackgroundColor: AppColors.scaffoldBackgroundColor,
      hintColor: AppColors.accentColor, // ✅ Use Gold as highlight color

      // ✅ Apply Global Text Styles
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.accentColor, // 🌟 Gold Titles
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          color: AppColors.white, // 📝 White Body Text
        ),
        bodyLarge: TextStyle(
          fontSize: 18,
          color: AppColors.lightGray, // 💡 Light Gray for Less Prominent Text
        ),
      ),

      // ✅ Buttons: Gold Background
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          backgroundColor: AppColors.accentColor,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          backgroundColor: AppColors.accentColor,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),

      // ✅ Input Fields: Gold Glow + Dark Background
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.primaryColor, // 🎨 Dark Input Background
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.lightGray),
          borderRadius: BorderRadius.circular(8.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.accentColor), // 🌟 Gold Border
          borderRadius: BorderRadius.circular(8.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.accentColor2), // ✨ Softer Gold Focus
          borderRadius: BorderRadius.circular(8.0),
        ),
        labelStyle: const TextStyle(color: AppColors.white),
        hintStyle: const TextStyle(color: AppColors.lightGray),
        errorStyle: const TextStyle(color: AppColors.redAccent),
      ),

      // ✅ Cursor + Selection Color: Gold Theme
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.accentColor, // 🖋 Gold Cursor
        selectionColor: AppColors.accentColor.withOpacity(0.5),
        selectionHandleColor: AppColors.accentColor2,
      ),

      // ✅ Drawer & NavigationBar Styles
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.scaffoldBackgroundColor,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.primaryColor,
        indicatorColor: AppColors.accentColor2.withOpacity(0.2),
        labelTextStyle: MaterialStateProperty.all(
          const TextStyle(fontSize: 14, color: AppColors.white),
        ),
      ),
    );
  }
}