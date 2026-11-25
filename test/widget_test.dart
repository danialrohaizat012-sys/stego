import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stegoland/data/store.dart';
import 'package:stegoland/main.dart';

void main() {
  testWidgets('onboarding → home → family booking', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final store = AppStore(clock: () => DateTime(2026, 11, 25, 9));
    await store.load();

    await tester.pumpWidget(StegolandApp(store: store));
    expect(find.text('Selamat datang ke Stegoland!'), findsOneWidget);

    await tester.ensureVisible(find.text('Teruskan sebagai tetamu'));
    await tester.pump();
    await tester.tap(find.text('Teruskan sebagai tetamu'));
    await _settle(tester);
    expect(find.text('Jom ke angkasa!'), findsOneWidget);

    await tester.tap(find.text('Tempah Slot'));
    await _settle(tester);
    expect(find.text('Tempah Tiket Keluarga'), findsOneWidget);
    expect(find.text('Pilih tarikh'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Pilih slot masa'),
      200,
      scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first,
    );
    expect(find.textContaining('tempat lagi'), findsWidgets);
  });
}

/// pumpAndSettle never settles because of the looping mascot animation.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
