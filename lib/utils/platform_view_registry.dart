export 'platform_view_registry_stub.dart'
    if (dart.library.js_util) 'platform_view_registry_web.dart'
    if (dart.library.html) 'platform_view_registry_web.dart';
