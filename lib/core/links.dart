import 'package:url_launcher/url_launcher.dart';

import '../data/models.dart';

Future<bool> _open(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

Future<bool> openWhatsApp(BusinessInfo b, [String message = '']) =>
    _open(Uri.https('wa.me', '/${b.whatsapp}', message.isEmpty ? null : {'text': message}));

Future<bool> callPhone(BusinessInfo b) => _open(Uri(scheme: 'tel', path: b.phone.replaceAll(RegExp(r'[^\d+]'), '')));

Future<bool> openMaps(BusinessInfo b) =>
    _open(Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': b.mapsQuery}));

Future<bool> openWaze(BusinessInfo b) => _open(Uri.https('waze.com', '/ul', {'q': b.mapsQuery, 'navigate': 'yes'}));

Future<bool> openTikTok(BusinessInfo b) =>
    _open(Uri.https('www.tiktok.com', '/${b.tiktok.startsWith('@') ? b.tiktok : '@${b.tiktok}'}'));

Future<bool> openFacebook(BusinessInfo b) => _open(Uri.parse(b.facebook));
