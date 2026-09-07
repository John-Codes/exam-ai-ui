// lib/core/config/app_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
//
// Single source of truth for all API base URLs.
//
// ── To switch environments, change this one line: ─────────────────────────
//   static const AppEnvironment env = AppEnvironment.dev;
// ──────────────────────────────────────────────────────────────────────────
//
// For APIs already in prod, comment out the isDev branch so the toggle
// has no effect on that service.

enum AppEnvironment { dev, prod }

class AppConfig {
  // ── Change this one line to switch all APIs at once ──
  static const AppEnvironment env = AppEnvironment.dev;
  // ─────────────────────────────────────────────────────

  static bool get isDev => env == AppEnvironment.dev;

  static const String aiChatBaseUrl = 'http://100.91.34.26:8001';

  /// TestReady CDL exam API base used by the AI quiz mode.
  /// Override with --dart-define=EXAM_API_URL=https://...
  static const String examApiBase = String.fromEnvironment(
    'EXAM_API_URL',
    defaultValue: 'https://exam-api-acfz.onrender.com',
  );

  static const String examWorkspace =
      String.fromEnvironment('EXAM_WORKSPACE', defaultValue: 'ws_1');

  static const String thorVoiceBaseUrl = 'http://100.91.34.26:8020';

  static const String thorVoiceWebSocketUrl =
      'ws://100.91.34.26:8020/v1/listen';

  static String get voiceApiToken =>
      dotenv.env['VOICE_API_TOKEN'] ??
      const String.fromEnvironment('VOICE_API_TOKEN', defaultValue: '');

  static String get trelloCloneBaseUrl {
    if (isDev) return 'http://100.91.34.26:8003';
    return 'https://trello-clone-api-latest-2.onrender.com';
  }

  static String get agentChatHistoryBaseUrl {
    return 'http://100.91.34.26:8004';
  }

  static const String trelloCloneApiKey =
      String.fromEnvironment('TRELLO_CLONE_API_KEY', defaultValue: '');

  static const String agentModelName =
      String.fromEnvironment('AGENT_MODEL_NAME', defaultValue: 'local-agent');

  static const String aiChatApiKey =
      String.fromEnvironment('AI_CHAT_API_KEY', defaultValue: '');

  static const bool showSubAgentUi = bool.fromEnvironment(
    'SHOW_SUB_AGENT_UI',
    defaultValue: false,
  );
}
