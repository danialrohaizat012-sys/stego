// Placeholder — Firebase is NOT configured yet, so the app runs in local
// (on-device) mode.
//
// To connect Firebase, run from the project root:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=<your-firebase-project-id> --platforms=android,ios,web
//
// That command overwrites this file with your project's real options and the
// app switches to cloud mode automatically.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform =>
      throw UnsupportedError('Firebase belum dikonfigurasi. Jalankan `flutterfire configure`.');
}
