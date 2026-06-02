// lib/core/config/app_config.dart
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

  // AI Chat (OpenRouter) — already deployed on Render, dev URL not set yet.
  // Comment in the dev branch and set a local URL when running locally.
  static String get aiChatBaseUrl {
    if (isDev) return 'http://127.0.0.1:8001';
    return 'https://fastapi-openrouter-api.onrender.com';
  }

  static String get trelloCloneBaseUrl {
    if (isDev) return 'http://127.0.0.1:8003';
    return 'https://trello-clone-api-latest-2.onrender.com';
  }

  static String get agentChatHistoryBaseUrl {
    if (isDev) return 'http://127.0.0.1:8004';
    return 'http://127.0.0.1:8004';
  }

  static const String trelloCloneApiKey =
      String.fromEnvironment('TRELLO_CLONE_API_KEY', defaultValue: '');

  static const String agentModelName =
      String.fromEnvironment('AGENT_MODEL_NAME', defaultValue: 'local-agent');
}
