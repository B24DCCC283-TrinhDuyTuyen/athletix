import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  static String get analyzeEndpoint => '$baseUrl/api/analyze';
  static String get analyzeVideoEndpoint => '$baseUrl/api/analyze-video';
  static String get healthEndpoint => '$baseUrl/api/health';

  static String getMediaUrl(String relativePath) {
    if (relativePath.startsWith('http')) return relativePath;
    final cleanPath = relativePath.startsWith('/') ? relativePath : '/$relativePath';
    return '$baseUrl$cleanPath';
  }
}
