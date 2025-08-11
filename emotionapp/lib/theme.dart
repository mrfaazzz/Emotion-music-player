import 'package:flutter/material.dart';

class AppTheme {
  // Primary theme colors
  static const Color primaryColor = Color(0xFF1DB954);      // Spotify green
  static const Color backgroundColor = Color(0xFF121212);   // Dark background
  static const Color secondaryBackgroundColor = Color(0xFF282828); // Slightly lighter background
  static const Color textColor = Color(0xFFFFFFFF);         // White text
  static const Color secondaryTextColor = Color(0xFFB3B3B3); // Gray text
  static const Color dividerColor = Color(0xFF404040);      // Dark gray divider
  static const Color errorColor = Color(0xFFFF0000);        // Red for errors/logout

  // Gradients
  static const Gradient mainGradient = LinearGradient(
    colors: [secondaryBackgroundColor, backgroundColor],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Gradient bottomNavGradient = LinearGradient(
    colors: [secondaryBackgroundColor, backgroundColor],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  static const Gradient cardOverlayGradient = LinearGradient(
    colors: [Colors.black87, Colors.transparent],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  // Text styles
  static const TextStyle appBarTitle = TextStyle(
    color: textColor,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
  );

  static const TextStyle sectionTitleLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textColor,
    letterSpacing: 1.2,
  );

  static const TextStyle sectionTitleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: textColor,
    letterSpacing: 1.2,
  );

  static TextStyle sectionTitleWithShadow(double fontSize) => TextStyle(
    fontSize: fontSize,
    fontWeight: FontWeight.bold,
    color: textColor,
    letterSpacing: 1.2,
    shadows: [
      Shadow(
        color: primaryColor.withOpacity(0.5),
        offset: const Offset(2, 2),
        blurRadius: 5,
      ),
    ],
  );

  static const TextStyle cardTitle = TextStyle(
    color: textColor,
    fontWeight: FontWeight.bold,
    fontSize: 14,
  );

  static const TextStyle cardSubtitle = TextStyle(
    color: secondaryTextColor,
    fontSize: 12,
  );

  static const TextStyle smallCardTitle = TextStyle(
    color: textColor,
    fontWeight: FontWeight.w500,
    fontSize: 12,
  );

  static const TextStyle drawerItemTitle = TextStyle(
    color: textColor,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle drawerHeaderName = TextStyle(
    color: textColor,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle drawerHeaderEmail = TextStyle(
    color: secondaryTextColor,
    fontSize: 14,
  );

  static const TextStyle dialogTitle = TextStyle(
    color: textColor,
  );

  static const TextStyle dialogContent = TextStyle(
    color: secondaryTextColor,
  );

  static const TextStyle dialogCancel = TextStyle(
    color: primaryColor,
  );

  static const TextStyle dialogConfirm = TextStyle(
    color: errorColor,
  );

  static const TextStyle moodCardTitle = TextStyle(
    color: textColor,
    fontSize: 18,
    fontWeight: FontWeight.bold,
    shadows: [Shadow(color: primaryColor, blurRadius: 5)],
  );

  // Decorations
  static BoxDecoration cardDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(15),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 10,
        offset: const Offset(0, 5),
      ),
    ],
  );

  static const BoxDecoration gradientBackground = BoxDecoration(
    gradient: mainGradient,
  );

  static const BoxDecoration bottomNavBackground = BoxDecoration(
    gradient: bottomNavGradient,
  );

  static const BoxDecoration drawerHeaderDecoration = BoxDecoration(
    color: secondaryBackgroundColor,
    border: Border(bottom: BorderSide(color: dividerColor, width: 1)),
  );

  // Shapes
  static final RoundedRectangleBorder drawerItemShape =
  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));

  static final RoundedRectangleBorder cardShape =
  RoundedRectangleBorder(borderRadius: BorderRadius.circular(15));

  static final RoundedRectangleBorder smallCardShape =
  RoundedRectangleBorder(borderRadius: BorderRadius.circular(6));

  // Theme data
  static ThemeData get themeData => ThemeData(
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: backgroundColor,
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryBackgroundColor,
      background: backgroundColor,
      error: errorColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: appBarTitle,
    ),
    bottomAppBarTheme: const BottomAppBarTheme(
      color: Colors.transparent,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: textColor,
    ),
    textTheme: const TextTheme(
      titleLarge: appBarTitle,
      titleMedium: sectionTitleLarge,
      titleSmall: sectionTitleMedium,
      bodyLarge: cardTitle,
      bodyMedium: drawerItemTitle,
      bodySmall: cardSubtitle,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      titleTextStyle: dialogTitle,
      contentTextStyle: dialogContent,
    ),
    dividerTheme: const DividerThemeData(
      color: dividerColor,
      thickness: 1,
      indent: 16,
      endIndent: 16,
    ),
    iconTheme: const IconThemeData(
      color: secondaryTextColor,
      size: 28,
    ),
  );

  // Spacing and sizing constants
  static const double cardMargin = 16.0;
  static const double smallCardMargin = 12.0;
  static const double sectionPadding = 20.0;
  static const double cardSpacing = 15.0;
  static const double cardBorderRadius = 15.0;
  static const double smallCardBorderRadius = 6.0;
  static const double iconSize = 28.0;
  static const double fabIconSize = 32.0;
  static const double drawerHeaderPaddingTop = 40.0;
  static const double drawerHeaderPaddingHorizontal = 16.0;
  static const double drawerHeaderPaddingBottom = 16.0;
  static const double avatarRadius = 40.0;
  static const double avatarImageSize = 76.0;

  // Animation durations
  static const Duration fabAnimationDuration = Duration(milliseconds: 1200);
  static const double fabAnimationStartScale = 1.0;
  static const double fabAnimationEndScale = 1.15;
}