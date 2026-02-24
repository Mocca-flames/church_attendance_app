import 'package:flutter/material.dart';

/// Global navigator key for showing dialogs from any context
/// This allows dialogs to be shown even when the local context
/// doesn't have a Navigator (e.g., during app startup on SplashScreen)
final navigatorKey = GlobalKey<NavigatorState>();
