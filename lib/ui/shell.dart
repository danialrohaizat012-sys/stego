import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/store.dart';
import 'cafe/cafe_screen.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'tickets/my_tickets_screen.dart';

/// Lets any descendant switch the bottom-nav tab.
class ShellScope extends InheritedWidget {
  const ShellScope({super.key, required this.goTo, required super.child});
  final void Function(int tab) goTo;

  static ShellScope? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ShellScope>();

  @override
  bool updateShouldNotify(ShellScope oldWidget) => false;
}

abstract final class Tabs {
  static const home = 0;
  static const cafe = 1;
  static const tickets = 2;
  static const profile = 3;
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _goTo(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final cartCount = context.select<AppStore, int>((s) => s.cartCount);
    return ShellScope(
      goTo: _goTo,
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: const [HomeScreen(), CafeScreen(), MyTicketsScreen(), ProfileScreen()],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _goTo,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.rocket_outlined),
              selectedIcon: Icon(Icons.rocket_launch_rounded),
              label: 'Utama',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: cartCount > 0,
                label: Text('$cartCount'),
                child: const Icon(Icons.local_cafe_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: cartCount > 0,
                label: Text('$cartCount'),
                child: const Icon(Icons.local_cafe_rounded),
              ),
              label: 'Jasmine Cafe',
            ),
            const NavigationDestination(
              icon: Icon(Icons.confirmation_number_outlined),
              selectedIcon: Icon(Icons.confirmation_number_rounded),
              label: 'Tiket Saya',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
