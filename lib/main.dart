import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'features/ai_agent_ui/ui/ai_agent_screen.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exceptionAsString()}');
      debugPrintStack(stackTrace: details.stack);
    };
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      debugPrint('Uncaught platform error: $error');
      debugPrintStack(stackTrace: stack);
      return true;
    };

    try {
      await dotenv.load(fileName: '.env');
      debugPrint('AOne UI environment loaded');
    } catch (e, stack) {
      debugPrint('Could not load .env file: $e');
      debugPrintStack(stackTrace: stack);
    }

    runApp(const AOneUiApp());
  }, (Object error, StackTrace stack) {
    debugPrint('Uncaught zone error: $error');
    debugPrintStack(stackTrace: stack);
  });
}

class AOneUiApp extends StatelessWidget {
  const AOneUiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4F8CFF),
        brightness: Brightness.dark,
      ),
      cardColor: const Color(0xFF1E1E1E),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );

    return MaterialApp(
      title: 'AOne UI',
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.dark,
      home: const AiAgentScreen(),
    );
  }
}
