import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stegoland/data/firebase_remote.dart';
import 'package:stegoland/data/models.dart';
import 'package:stegoland/data/seed.dart';
import 'package:stegoland/data/store.dart';

Future<void> settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  final now = DateTime(2026, 11, 27, 20, 15); // Friday evening, Last Call open
  late FakeFirebaseFirestore cloud;

  Future<(AppStore, FirebaseRemote)> device({String? staffUid}) async {
    final store = AppStore(clock: () => now);
    await store.load();
    final remote = FirebaseRemote(
      store: store,
      db: cloud,
      auth: MockFirebaseAuth(),
      staffSession: () async => (
        cloud,
        MockFirebaseAuth(
          mockUser: MockUser(uid: staffUid ?? 'staff1', email: 'staf@stegoland.my', isAnonymous: false),
        ),
      ),
    );
    await remote.start();
    await settle();
    return (store, remote);
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cloud = FakeFirebaseFirestore();
  });

  test('staff login seeds config + menu; non-staff is refused', () async {
    final (store, _) = await device(staffUid: 'nobody');
    expect(await store.staffSignIn('x@y.z', 'pw'), isNotNull);
    expect(store.isStaff, isFalse);

    await cloud.doc('staff/staff1').set({'email': 'staf@stegoland.my'});
    final (staffStore, _) = await device();
    expect(await staffStore.staffSignIn('staf@stegoland.my', 'pw'), isNull);
    expect(staffStore.isStaff, isTrue);
    expect((await cloud.doc('config/settings').get()).exists, isTrue);
    expect((await cloud.collection('menu').get()).docs.length, defaultMenu.length);
  });

  test('booking on one phone reduces capacity seen on another', () async {
    final (a, _) = await device();
    final (b, _) = await device();
    final sat = DateTime(2026, 11, 28);

    final bk = await a.createFamilyBooking(
      date: sat,
      slotId: 's1',
      children: 70,
      guardians: 2,
      name: 'Aina',
      phone: '0123456789',
    );
    await settle();
    expect(bk.ownerUid, isNotNull);
    expect(b.remaining(sat, 's1'), 10);
    expect(b.validate(date: sat, slotId: 's1', children: 11), isNotNull);
    expect(a.bookings.single.id, bk.id);
    expect(b.bookings, isEmpty); // other customers can't see it

    await a.setBookingStatus(bk.id, BookingStatus.cancelled);
    await settle();
    expect(b.remaining(sat, 's1'), 80);
  });

  test('group request → staff confirms → check-in awards points', () async {
    await cloud.doc('staff/staff1').set({'email': 'staf@stegoland.my'});
    final (teacher, _) = await device();
    await teacher.completeOnboarding(name: 'Cikgu Ain', phone: '0198887777');
    await settle();
    final g = await teacher.createGroupBooking(
      date: DateTime(2026, 11, 29),
      slotId: 's1',
      children: 30,
      picName: 'Cikgu Ain',
      phone: '0198887777',
      group: const GroupDetails(
        institution: 'Tadika Ceria',
        institutionType: 'Tadika',
        teachers: 4,
        meals: 30,
        drinks: 0,
        privateSession: true,
        notes: '',
      ),
    );

    final (counter, _) = await device();
    await counter.staffSignIn('staf@stegoland.my', 'pw');
    await settle();
    expect(counter.pendingGroups, 1);
    expect(counter.remaining(DateTime(2026, 11, 29), 's1'), 0); // private session

    await counter.setBookingStatus(g.id, BookingStatus.confirmed);
    await counter.setBookingPaid(g.id, true);
    await counter.setBookingStatus(g.id, BookingStatus.checkedIn);
    await settle();
    expect(teacher.bookings.single.status, BookingStatus.checkedIn);
    expect(teacher.bookings.single.paid, isTrue);
    expect(teacher.member!.points, g.total.floor());
  });

  test('Last Call stock is shared and orders reach the kitchen', () async {
    await cloud.doc('staff/staff1').set({'email': 'staf@stegoland.my'});
    final (counter, _) = await device();
    await counter.staffSignIn('staf@stegoland.my', 'pw');
    await settle();
    await counter.upsertDeal(itemId: 'm11', price: 7.9, qty: 2);

    final (customer, _) = await device();
    await settle();
    expect(customer.activeDeals.single.qtyLeft, 2);
    await customer.addDealToCart(customer.activeDeals.single, 2);
    final o = await customer.placeOrder(mode: OrderMode.dineIn, table: '5', name: 'Hakim', note: '');
    await settle();
    expect(customer.todaysDeals, isEmpty);
    expect(counter.openOrders, 1);

    await counter.setOrderStatus(o.id, OrderStatus.preparing);
    await settle();
    expect(customer.orders.single.status, OrderStatus.preparing);

    // A second customer racing for the sold-out deal is refused.
    final (third, _) = await device();
    await expectLater(
      FirebaseRemote(
        store: third,
        db: cloud,
        auth: MockFirebaseAuth(signedIn: true),
        staffSession: () => throw UnimplementedError(),
      ).placeOrder(o, {counter.deals.single.id: 1}),
      throwsStateError,
    );
  });

  test('settings changed by staff reach customers', () async {
    await cloud.doc('staff/staff1').set({'email': 'staf@stegoland.my'});
    final (counter, _) = await device();
    await counter.staffSignIn('staf@stegoland.my', 'pw');
    await counter.updateSettings(counter.settings.copyWith(weekendPrice: 21));
    final (customer, _) = await device();
    await settle();
    expect(customer.childPrice(DateTime(2026, 11, 28)), 21);
  });
}
