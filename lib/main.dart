import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'models/athlete_analysis.dart';
import 'models/video_analysis.dart';
import 'screens/home_screen.dart';
import 'screens/analysis_result_screen.dart';
import 'screens/video_result_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: AthletixApp(),
    ),
  );
}

// Cấu hình GoRouter điều hướng
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/result',
      builder: (context, state) {
        final result = state.extra as AnalysisResult;
        return AnalysisResultScreen(result: result);
      },
    ),
    GoRoute(
      path: '/video-result',
      builder: (context, state) {
        final result = state.extra as VideoAnalysisResult;
        return VideoResultScreen(result: result);
      },
    ),
  ],
);

class AthletixApp extends StatelessWidget {
  const AthletixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Athletix - AI Điền Kinh',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
    );
  }
}
