class ServerStatus {
  static bool mapsReady = false;
  static bool mongoReady = false;
  static bool bootCheckCompleted = false;

  static bool get allReady => mapsReady && mongoReady;

  static void update({
    required bool mapsOk,
    required bool mongoOk,
  }) {
    mapsReady = mapsOk;
    mongoReady = mongoOk;
    bootCheckCompleted = true;
  }
}
