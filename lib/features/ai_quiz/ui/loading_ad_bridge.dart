/// No-op on non-web platforms (and in `flutter test` on the VM).
export 'loading_ad_bridge_stub.dart'
    if (dart.library.html) 'loading_ad_bridge_web.dart';
