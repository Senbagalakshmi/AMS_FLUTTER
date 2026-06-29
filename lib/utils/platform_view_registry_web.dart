import 'package:universal_html/html.dart' as html;
import 'dart:ui_web' as ui_web;

void registerWebImage(String viewId, String url, void Function() onError) {
  ui_web.platformViewRegistry.registerViewFactory(
    viewId,
    (int viewId) {
      final img = html.ImageElement()
        ..src = url
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.borderRadius = '50%';
      img.onError.listen((_) => onError());
      return img;
    },
  );
}

void registerWebAppIcon(String viewId, String url, void Function() onError) {
  ui_web.platformViewRegistry.registerViewFactory(
    viewId,
    (int viewId) {
      final img = html.ImageElement()
        ..src = url
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'contain'
        ..style.borderRadius = '12px'
        ..style.border = 'none'
        ..style.outline = 'none'
        ..style.background = 'transparent';
      img.onError.listen((_) => onError());
      return img;
    },
  );
}
