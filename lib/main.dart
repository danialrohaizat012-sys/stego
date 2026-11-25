import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'data/store.dart';
import 'ui/onboarding_screen.dart';
import 'ui/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ms_MY');
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  final store = AppStore();
  await store.load();
  runApp(StegolandApp(store: store));
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
