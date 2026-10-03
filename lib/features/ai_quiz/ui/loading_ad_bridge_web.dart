import 'dart:html' as html;

/// Shows / hides the `#loading-ad` overlay reserved in `web/index.html`.
/// The overlay only contains a live AdSense unit when `LOADING_AD_SLOT` is
/// set in the shell; otherwise this is a harmless no-op on a hidden div.
void setLoadingAdVisible(bool visible) {
  final el = html.document.getElementById('loading-ad');
  if (el != null) {
    el.style.display = visible ? 'block' : 'none';
  }
}
