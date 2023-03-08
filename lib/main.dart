import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:socialoo/app.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  MobileAds.instance.initialize();
  await SharedPreferences.getInstance().then(
    (prefs) {
      runApp(
        Socialoo(prefs, savedThemeMode),
      );
    },
  );
}
