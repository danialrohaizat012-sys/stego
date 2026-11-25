import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stegoland/data/models.dart';
import 'package:stegoland/data/store.dart';

void main() {
  var now = DateTime(2026, 11, 25, 19, 30);
  late AppStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 11, 25, 19, 30);
    store = AppStore(clock: () => now);
    await store.load();
  });

  test('deals are only buyable inside the Last Call window', () async {
    final chicken = store.menu.firstWhere((m) => m.name == 'Set A');
    await store.upsertDeal(itemId: chicken.id, price: 6.5, qty: 3);

    expect(store.lastCallActive, isFalse);
    expect(store.lastCallUpcoming, isTrue);
    expect(store.activeDeals, isEmpty);
    await store.addDealToCart(store.todaysDeals.single);
    expect(store.cart, isEmpty);

    now = DateTime(2026, 11, 25, 20, 15);
    expect(store.lastCallActive, isTrue);
    expect(store.lastCallMinutesLeft, 105);
    final deal = store.activeDeals.single;
    await store.addDealToCart(deal, 5); // clamped to stock
    expect(store.cart.single.qty, 3);
    expect(store.cartTotal, closeTo(19.5, 0.001));

    await store.placeOrder(mode: OrderMode.takeaway, table: '', name: 'Hakim', note: '');
    expect(store.todaysDeals, isEmpty); // sold out
  });

  test('order is rejected if the window closed while in the cart', () async {
    now = DateTime(2026, 11, 25, 21, 50);
    final item = store.menu.first;
    await store.upsertDeal(itemId: item.id, price: 1, qty: 2);
    await store.addDealToCart(store.activeDeals.single);
    now = DateTime(2026, 11, 25, 22, 1);
    expect(() => store.placeOrder(mode: OrderMode.dineIn, table: '2', name: 'A', note: ''), throwsStateError);
  });

  test('deals expire the next day', () async {
    now = DateTime(2026, 11, 25, 20, 30);
    await store.upsertDeal(itemId: store.menu.first.id, price: 1, qty: 2);
    now = DateTime(2026, 11, 26, 20, 30);
    expect(store.activeDeals, isEmpty);
  });
}
