import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stegoland/data/models.dart';
import 'package:stegoland/data/store.dart';

void main() {
  // Wednesday 25 Nov 2026, 09:00
  final now = DateTime(2026, 11, 25, 9);
  late AppStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = AppStore(clock: () => now);
    await store.load();
  });

  test('Kelantan weekend is Friday & Saturday, holidays override', () {
    expect(store.dayType(DateTime(2026, 11, 26)), DayType.weekday); // Thu
    expect(store.dayType(DateTime(2026, 11, 27)), DayType.weekend); // Fri
    expect(store.dayType(DateTime(2026, 11, 28)), DayType.weekend); // Sat
    expect(store.dayType(DateTime(2026, 11, 29)), DayType.weekday); // Sun
    expect(store.dayType(DateTime(2026, 12, 25)), DayType.holiday);
    expect(store.childPrice(DateTime(2026, 11, 26)), 14);
    expect(store.childPrice(DateTime(2026, 11, 27)), 19);
    expect(store.childPrice(DateTime(2026, 12, 25)), 23);
  });

  test('family total = child price × kids + RM5 × guardians', () {
    expect(store.familyTotal(DateTime(2026, 11, 28), 2, 1), 19 * 2 + 5);
  });

  test('Friday prayer slot hidden, past dates closed', () {
    final fri = store.slotsFor(DateTime(2026, 11, 27)).map((s) => s.id);
    expect(fri, isNot(contains('s2')));
    expect(store.slotsFor(DateTime(2026, 11, 26)).length, 6);
    expect(store.slotsFor(DateTime(2026, 11, 24)), isEmpty);
  });

  test('school quote: RM10/child, 5 teachers free, meals & private', () {
    final q = store.groupQuote(children: 45, teachers: 6, meals: 45, drinks: 45, privateSession: false);
    expect(q.childTotal, 450);
    expect(q.chargeableTeachers, 1);
    expect(q.total, closeTo(450 + 5 + 45 * 7.9 + 45 * 1.9, 0.001));
  });

  test('capacity is enforced and private sessions block slot', () async {
    final d = DateTime(2026, 11, 26);
    await store.createFamilyBooking(date: d, slotId: 's1', children: 75, guardians: 2, name: 'A', phone: '0123456789');
    expect(store.remaining(d, 's1'), 5);
    expect(store.validate(date: d, slotId: 's1', children: 6), isNotNull);

    await store.createGroupBooking(
      date: d,
      slotId: 's3',
      children: 30,
      picName: 'Cikgu Ain',
      phone: '0198887777',
      group: const GroupDetails(
        institution: 'Tadika Ceria',
        institutionType: 'Tadika',
        teachers: 4,
        meals: 30,
        drinks: 30,
        privateSession: true,
        notes: '',
      ),
    );
    expect(store.remaining(d, 's3'), 0);
    expect(store.pendingGroups, 1);
    expect(
      () => store.createFamilyBooking(date: d, slotId: 's3', children: 1, guardians: 0, name: 'B', phone: '0123'),
      throwsStateError,
    );
  });

  test('points awarded on check-in for own booking and data persists', () async {
    await store.completeOnboarding(name: 'Danial', phone: '011-7595 6474');
    final b = await store.createFamilyBooking(
      date: DateTime(2026, 11, 26),
      slotId: 's1',
      children: 2,
      guardians: 1,
      name: 'Danial',
      phone: '01175956474',
    );
    await store.setBookingStatus(b.id, BookingStatus.checkedIn);
    expect(store.member!.points, 33);

    final reloaded = AppStore(clock: () => now);
    await reloaded.load();
    expect(reloaded.bookings.single.status, BookingStatus.checkedIn);
    expect(reloaded.member!.points, 33);
  });

  test('cafe cart and order flow', () async {
    final item = store.menu.firstWhere((m) => m.name == 'Twin Bite');
    await store.addToCart(item);
    await store.addToCart(item);
    expect(store.cartTotal, 36);
    final o = await store.placeOrder(mode: OrderMode.dineIn, table: '4', name: 'Aina', note: '');
    expect(store.cart, isEmpty);
    expect(o.status, OrderStatus.received);
    await store.setOrderStatus(o.id, OrderStatus.preparing);
    expect(store.openOrders, 1);
  });
}
