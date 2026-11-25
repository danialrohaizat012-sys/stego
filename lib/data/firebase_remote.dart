import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Settings;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/format.dart';
import 'models.dart';
import 'seed.dart';
import 'store.dart';

/// Firestore layout
/// ```
/// config/settings        Settings            read: all   write: staff
/// config/business        BusinessInfo        read: all   write: staff
/// menu/{id}              MenuItem            read: all   write: staff
/// deals/{id}             LastCallDeal        read: all   write: staff (customers may only decrement qtyLeft)
/// bookings/{id}          Booking + ownerUid  read: owner/staff
/// slotEntries/{id}       SlotEntry (no PII)  read: all, created together with its booking
/// orders/{id}            CafeOrder + ownerUid read: owner/staff
/// members/{uid}          Member              owner (points may only go down) / staff
/// members/{uid}/vouchers/{code}
/// staff/{uid}            {email, name}       created manually in the Firebase console
/// ```
///
/// Customers are signed in anonymously on [auth]. Staff sign in with
/// email/password on a *separate* Firebase app ([staffAuth]/[staffDb]) so the
/// customer identity on the same device is never lost.
class FirebaseRemote implements Remote {
  FirebaseRemote({required this.store, required this.db, required this.auth, required this.staffSession});

  final AppStore store;
  final FirebaseFirestore db;
  final FirebaseAuth auth;

  /// Lazily creates the staff Firestore/Auth pair (a secondary Firebase app).
  final Future<(FirebaseFirestore, FirebaseAuth)> Function() staffSession;

  FirebaseFirestore? _staffDb;
  FirebaseAuth? _staffAuth;

  final _publicSubs = <StreamSubscription<dynamic>>[];
  final _userSubs = <StreamSubscription<dynamic>>[];
  final _staffSubs = <StreamSubscription<dynamic>>[];

  @override
  String? get uid => auth.currentUser?.uid;

  FirebaseFirestore get _writeDb => store.isStaff && _staffDb != null ? _staffDb! : db;

  // ------------------------------------------------------------- lifecycle

  Future<void> start() async {
    store.remote = this;
    if (auth.currentUser == null) await auth.signInAnonymously();
    _listenPublic();
    _listenUser(auth.currentUser!.uid);
    await _restoreStaff();
  }

  Future<void> dispose() async {
    for (final s in [..._publicSubs, ..._userSubs, ..._staffSubs]) {
      await s.cancel();
    }
  }

  void _onError(Object e) => debugPrint('Stegoland Firestore: $e');

  Map<String, dynamic> _data(DocumentSnapshot<Map<String, dynamic>> d) => {...?d.data(), 'id': d.id};

  void _listenPublic() {
    final today = dateKey(store.now);
    final yesterday = dateKey(store.now.subtract(const Duration(days: 1)));

    _publicSubs.addAll([
      db.doc('config/settings').snapshots().listen((d) {
        if (!d.exists) return;
        store.applyRemote(() => store.settings = Settings.fromJson({...defaultSettings.toJson(), ...d.data()!}));
      }, onError: _onError),
      db.doc('config/business').snapshots().listen((d) {
        if (!d.exists) return;
        store.applyRemote(() => store.business = BusinessInfo.fromJson({...defaultBusiness.toJson(), ...d.data()!}));
      }, onError: _onError),
      db.collection('menu').snapshots().listen((q) {
        // Keep the built-in menu until staff have seeded the cloud one.
        if (q.docs.isEmpty) return;
        final items = q.docs.map((d) => MenuItem.fromJson(_data(d))).toList();
        final order = {for (final (i, c) in menuCategories.indexed) c: i};
        items.sort((a, b) {
          final c = (order[a.category] ?? 99).compareTo(order[b.category] ?? 99);
          return c != 0 ? c : a.name.compareTo(b.name);
        });
        store.applyRemote(() => store.menu = items);
      }, onError: _onError),
      db.collection('deals').where('date', isGreaterThanOrEqualTo: yesterday).snapshots().listen((q) {
        store.applyRemote(() => store.deals = q.docs.map((d) => LastCallDeal.fromJson(_data(d))).toList());
      }, onError: _onError),
      db.collection('slotEntries').where('date', isGreaterThanOrEqualTo: today).snapshots().listen((q) {
        store.applyRemote(() => store.slotEntries = q.docs.map((d) => SlotEntry.fromJson(d.data())).toList());
      }, onError: _onError),
    ]);
  }

  void _listenUser(String uid) {
    for (final s in _userSubs) {
      s.cancel();
    }
    _userSubs
      ..clear()
      ..addAll([
        db.collection('bookings').where('ownerUid', isEqualTo: uid).snapshots().listen((q) {
          final list = q.docs.map((d) => Booking.fromJson(_data(d))).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          store.applyRemote(() => store.bookings = list);
        }, onError: _onError),
        db.collection('orders').where('ownerUid', isEqualTo: uid).snapshots().listen((q) {
          final list = q.docs.map((d) => CafeOrder.fromJson(_data(d))).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          store.applyRemote(() => store.orders = list);
        }, onError: _onError),
        db.doc('members/$uid').snapshots().listen((d) {
          if (d.exists) {
            store.applyRemote(() => store.member = Member.fromJson(d.data()!));
          } else if (store.member != null) {
            // First launch on cloud: upload the member created on-device.
            saveMember(store.member!.copyWith(points: 0)).catchError(_onError);
          }
        }, onError: _onError),
        db.collection('members/$uid/vouchers').snapshots().listen((q) {
          final list = q.docs.map((d) => Voucher.fromJson(d.data())).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          store.applyRemote(() => store.vouchers = list);
        }, onError: _onError),
      ]);
  }

  // ------------------------------------------------------------- staff

  Future<void> _ensureStaffSession() async {
    if (_staffDb != null) return;
    final (sdb, sauth) = await staffSession();
    _staffDb = sdb;
    _staffAuth = sauth;
  }

  Future<void> _restoreStaff() async {
    try {
      await _ensureStaffSession();
      final u = _staffAuth!.currentUser;
      if (u != null && !u.isAnonymous) await _becomeStaff(u);
    } catch (e) {
      _onError(e);
    }
  }

  Future<bool> _becomeStaff(User u) async {
    final doc = await _staffDb!.doc('staff/${u.uid}').get();
    if (!doc.exists) return false;
    store.applyRemote(() {
      store.isStaff = true;
      store.staffEmail = u.email;
    });
    await _seedIfEmpty();
    _listenStaff();
    return true;
  }

  @override
  Future<String?> staffSignIn(String email, String password) async {
    try {
      await _ensureStaffSession();
      final cred = await _staffAuth!.signInWithEmailAndPassword(email: email, password: password);
      if (await _becomeStaff(cred.user!)) return null;
      await _staffAuth!.signOut();
      return 'Akaun ini belum didaftarkan sebagai staf.';
    } on FirebaseAuthException catch (e) {
      return switch (e.code) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' ||
        'invalid-email' => 'Emel atau kata laluan salah.',
        'too-many-requests' => 'Terlalu banyak cubaan. Cuba lagi sebentar.',
        'network-request-failed' => 'Tiada sambungan internet.',
        _ => 'Log masuk gagal (${e.code}).',
      };
    } catch (e) {
      return 'Log masuk gagal: $e';
    }
  }

  @override
  Future<void> staffSignOut() async {
    for (final s in _staffSubs) {
      await s.cancel();
    }
    _staffSubs.clear();
    await _staffAuth?.signOut();
  }

  void _listenStaff() {
    for (final s in _staffSubs) {
      s.cancel();
    }
    final sdb = _staffDb!;
    final from = dateKey(store.now.subtract(const Duration(days: 30)));
    final ordersFrom = DateTime(store.now.year, store.now.month, store.now.day).subtract(const Duration(days: 2));
    _staffSubs
      ..clear()
      ..addAll([
        sdb.collection('bookings').where('date', isGreaterThanOrEqualTo: from).snapshots().listen((q) {
          final list = q.docs.map((d) => Booking.fromJson(_data(d))).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          store.applyRemote(() => store.staffBookings = list);
        }, onError: _onError),
        sdb
            .collection('orders')
            .where('createdAt', isGreaterThanOrEqualTo: ordersFrom.toIso8601String())
            .snapshots()
            .listen((q) {
              final list = q.docs.map((d) => CafeOrder.fromJson(_data(d))).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
              store.applyRemote(() => store.staffOrders = list);
            }, onError: _onError),
      ]);
  }

  /// First staff login on a fresh project uploads the default settings,
  /// business info and menu.
  Future<void> _seedIfEmpty() async {
    final sdb = _staffDb!;
    final settings = await sdb.doc('config/settings').get();
    if (settings.exists) return;
    final batch = sdb.batch()
      ..set(sdb.doc('config/settings'), store.settings.toJson())
      ..set(sdb.doc('config/business'), store.business.toJson());
    for (final m in store.menu) {
      batch.set(sdb.doc('menu/${m.id}'), m.toJson());
    }
    await batch.commit();
  }

  FirebaseFirestore _requireStaff() {
    if (!store.isStaff || _staffDb == null) throw StateError('Perlu log masuk sebagai staf.');
    return _staffDb!;
  }

  // ------------------------------------------------------------- members

  @override
  Future<void> saveMember(Member m) async {
    final ref = db.doc('members/$uid');
    await db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) {
        tx.update(ref, {'name': m.name, 'phone': m.phone});
      } else {
        tx.set(ref, {...m.toJson(), 'points': 0});
      }
    });
  }

  @override
  Future<String> redeem(Reward reward, String code) async {
    final ref = db.doc('members/$uid');
    await db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final points = (snap.data()?['points'] as num?)?.toInt() ?? 0;
      if (points < reward.cost) throw StateError('Mata tidak mencukupi.');
      tx.update(ref, {'points': points - reward.cost});
      tx.set(db.doc('members/$uid/vouchers/$code'), {
        ...Voucher(code: code, title: reward.title, createdAt: store.now, used: false).toJson(),
        'cost': reward.cost,
      });
    });
    return code;
  }

  // ------------------------------------------------------------- bookings

  @override
  Future<void> createBooking(Booking b) async {
    final batch = db.batch()
      ..set(db.doc('bookings/${b.id}'), b.toJson())
      ..set(db.doc('slotEntries/${b.id}'), SlotEntry.fromBooking(b));
    await batch.commit();
  }

  @override
  Future<void> setBookingStatus(Booking b, BookingStatus status) async {
    final w = _writeDb;
    final active = status.isActive;
    await w.runTransaction((tx) async {
      final ref = w.doc('bookings/${b.id}');
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('Tempahan tidak dijumpai.');
      final current = BookingStatus.values.byName(snap.data()!['status'] as String);
      final ownerUid = snap.data()!['ownerUid'] as String?;
      DocumentSnapshot<Map<String, dynamic>>? member;
      if (status == BookingStatus.checkedIn && current != BookingStatus.checkedIn && ownerUid != null) {
        member = await tx.get(w.doc('members/$ownerUid'));
      }
      tx.update(ref, {'status': status.name});
      if (current.isActive != active) tx.update(w.doc('slotEntries/${b.id}'), {'active': active});
      if (member != null && member.exists) {
        tx.update(member.reference, {'points': FieldValue.increment(b.total.floor())});
      }
    });
  }

  @override
  Future<void> setBookingPaid(Booking b, bool paid) => _requireStaff().doc('bookings/${b.id}').update({'paid': paid});

  // ------------------------------------------------------------- cafe

  @override
  Future<void> placeOrder(CafeOrder o, Map<String, int> dealQty) async {
    await db.runTransaction((tx) async {
      final deals = <DocumentReference<Map<String, dynamic>>, int>{};
      for (final MapEntry(key: id, value: qty) in dealQty.entries) {
        final ref = db.doc('deals/$id');
        final snap = await tx.get(ref);
        final left = (snap.data()?['qtyLeft'] as num?)?.toInt() ?? 0;
        if (left < qty) {
          throw StateError(
            left == 0 ? 'Tawaran Last Call sudah habis.' : 'Hanya tinggal $left untuk tawaran Last Call.',
          );
        }
        deals[ref] = left - qty;
      }
      deals.forEach((ref, left) => tx.update(ref, {'qtyLeft': left}));
      tx.set(db.doc('orders/${o.id}'), o.toJson());
    });
  }

  @override
  Future<void> setOrderStatus(CafeOrder o, OrderStatus status) async {
    final sdb = _requireStaff();
    await sdb.runTransaction((tx) async {
      DocumentSnapshot<Map<String, dynamic>>? member;
      if (status == OrderStatus.completed && o.status != OrderStatus.completed && o.ownerUid != null) {
        member = await tx.get(sdb.doc('members/${o.ownerUid}'));
      }
      tx.update(sdb.doc('orders/${o.id}'), {'status': status.name});
      if (member != null && member.exists) {
        tx.update(member.reference, {'points': FieldValue.increment(o.total.floor())});
      }
    });
  }

  // ------------------------------------------------------------- admin

  @override
  Future<void> upsertMenuItem(MenuItem m) => _requireStaff().doc('menu/${m.id}').set(m.toJson());

  @override
  Future<void> deleteMenuItem(String id) => _requireStaff().doc('menu/$id').delete();

  @override
  Future<void> upsertDeal(LastCallDeal d) => _requireStaff().doc('deals/${d.id}').set(d.toJson());

  @override
  Future<void> removeDeal(String id) => _requireStaff().doc('deals/$id').delete();

  @override
  Future<void> updateSettings(Settings s) => _requireStaff().doc('config/settings').set(s.toJson());

  @override
  Future<void> updateBusiness(BusinessInfo b) => _requireStaff().doc('config/business').set(b.toJson());
}
