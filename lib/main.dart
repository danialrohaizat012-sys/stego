import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'data/firebase_remote.dart';
import 'data/store.dart';
import 'firebase_options.dart';
import 'ui/onboarding_screen.dart';
import 'ui/shell.dart';

/// `--dart-define=FIREBASE_EMULATOR=localhost` runs against the local
/// Firebase Emulator Suite with a demo project (no real project needed).
const _emulatorHost = String.fromEnvironment('FIREBASE_EMULATOR');

const _demoOptions = FirebaseOptions(
  apiKey: 'demo-key',
  appId: '1:000000000000:web:0000000000000000',
  messagingSenderId: '000000000000',
  projectId: 'demo-stegoland',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ms_MY');
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  final store = AppStore();
  await store.load();
  await _connectFirebase(store);
  runApp(StegolandApp(store: store));
}

/// Attaches Firestore if Firebase is configured; otherwise the app keeps
/// running in local mode.
Future<void> _connectFirebase(AppStore store) async {
  FirebaseOptions? options;
  if (_emulatorHost.isNotEmpty) {
    options = _demoOptions;
  } else {
    try {
      options = DefaultFirebaseOptions.currentPlatform;
    } on UnsupportedError {
      debugPrint('Stegoland: Firebase not configured — running in local mode.');
      return;
    }
  }

  FirebaseRemote? remote;
  try {
    final app = await Firebase.initializeApp(options: options);
    final db = FirebaseFirestore.instanceFor(app: app);
    final auth = FirebaseAuth.instanceFor(app: app);
    _useEmulator(db, auth);

    remote = FirebaseRemote(
      store: store,
      db: db,
      auth: auth,
      staffSession: () async {
        final staffApp = await Firebase.initializeApp(name: 'staff', options: options!);
        final sdb = FirebaseFirestore.instanceFor(app: staffApp);
        final sauth = FirebaseAuth.instanceFor(app: staffApp);
        _useEmulator(sdb, sauth);
        return (sdb, sauth);
      },
    );
    await remote.start().timeout(const Duration(seconds: 12));
  } catch (e) {
    // Offline on first launch or misconfigured: fall back to local mode.
    debugPrint('Stegoland: Firebase unavailable ($e) — running in local mode.');
    await remote?.dispose();
    store.remote = null;
  }
}

void _useEmulator(FirebaseFirestore db, FirebaseAuth auth) {
  if (_emulatorHost.isEmpty) return;
  db.useFirestoreEmulator(_emulatorHost, 8080);
  auth.useAuthEmulator(_emulatorHost, 9099);
}

class StegolandApp extends StatelessWidget {
  const StegolandApp({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: store,
      child: MaterialApp(
        title: 'Stegoland',
        debugShowCheckedModeBanner: false,
        theme: StegoTheme.light(),
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final onboarded = context.select<AppStore, bool>((s) => s.onboarded);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: onboarded ? const AppShell() : const OnboardingScreen(),
    );
  }
}
