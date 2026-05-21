import 'package:flutter/material.dart';

extension ThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  
  // ColorScheme shortcuts
  Color get primary => colors.primary;
  Color get onPrimary => colors.onPrimary;
  Color get secondary => colors.secondary;
  Color get onSecondary => colors.onSecondary;
  Color get surface => colors.surface;
  Color get onSurface => colors.onSurface;
  Color get error => colors.error;
  
  // Semantic text colors
  Color get textPrimary => colors.onSurface;
  Color get textSecondary => colors.onSurface.withAlpha(160);
  
  // Theme shortcuts
  Color get card => Theme.of(this).cardColor;
  Color get background => Theme.of(this).scaffoldBackgroundColor;
  Color get divider => Theme.of(this).dividerColor;
}
