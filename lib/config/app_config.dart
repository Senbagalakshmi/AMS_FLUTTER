import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Loads runtime configuration from `web/config.json` (web)
/// or `assets/config.json` (mobile/desktop).
///
/// Usage:
///   await AppConfig.getInstance();   // call once in main()
///   AppConfig.instance.baseUrl;      // use anywhere
class AppConfig {
  /// Finance backend base URL  e.g. http://localhost:8080/api
  final String baseUrl;

  /// Access Manager base URL  e.g. http://localhost:8082/accessmanager
  final String amBaseUrl;

  /// Product code for the exchange-token API body
  final int productCode;

  AppConfig._({
    required this.baseUrl,
    required this.amBaseUrl,
    required this.productCode,
  });

  static AppConfig? _instance;

  /// Load config once and cache it. Safe to call multiple times.
  static Future<AppConfig> getInstance() async {
    if (_instance != null) return _instance!;

    Map<String, dynamic> data;

    if (kIsWeb) {
      // Flutter web: config.json is served from the web/ folder
      final response = await http.get(Uri.parse('./config.json'));
      data = json.decode(response.body);
    } else {
      // Mobile / desktop: bundled in assets/
      final jsonString = await rootBundle.loadString('assets/config.json');
      data = json.decode(jsonString);
    }

    _instance = AppConfig._(
      baseUrl:     data['baseUrl']     ?? 'http://localhost:8080/api',
      amBaseUrl:   data['amBaseUrl']   ?? 'http://localhost:8082/accessmanager',
      productCode: data['productCode'] ?? 1,
    );

    return _instance!;
  }

  /// Access the loaded config. Throws if not initialised.
  static AppConfig get instance {
    if (_instance == null) {
      throw Exception(
        'AppConfig not initialised. Call AppConfig.getInstance() first.',
      );
    }
    return _instance!;
  }
}
