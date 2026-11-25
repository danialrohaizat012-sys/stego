import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/format.dart';
import 'models.dart';
import 'seed.dart';

/// Breakdown of a group / school-visit quotation.
class GroupQuote {
  const GroupQuote({
    required this.children,
    required this.childTotal,
    required this.chargeableTeachers,
    required this.teacherTotal,
    required this.mealTotal,
    required this.drinkTotal,
    required this.privateTotal,
  });

  final int children;
  final double childTotal;
  final int chargeableTeachers;
  final double teacherTotal;
  final double mealTotal;
  final double drinkTotal;
  final double privateTotal;

  double get total => childTotal + teacherTotal + mealTotal + drinkTotal + privateTotal;
}

/// Public, PII-free record of seats taken in a slot (cloud mode). Lets every
/// customer see live capacity without being able to read other bookings.
class SlotEntry {
  const SlotEntry({
    required this.date,
    required this.slotId,
    required this.children,
    required this.private,
    required this.active,
  });
  final String date;
  final String slotId;
  final int children;
  final bool private;
  final bool active;

  factory SlotEntry.fromJson(Map<String, dynamic> j) => SlotEntry(
    date: j['date'] as String,
    slotId: j['slotId'] as String,
    children: (j['children'] as num).toInt(),
    private: j['private'] as bool? ?? false,
    active: j['active'] as bool? ?? true,
  );

  static Map<String, dynamic> fromBooking(Booking b) => {
    'date': b.date,
    'slotId': b.slotId,
    'children': b.children,
    'private': b.group?.privateSession ?? false,
    'active': b.status.isActive,
  };
}

/// Cloud backend (Firebase). When attached to [AppStore.remote], writes go to
/// the cloud and listeners push changes back into the store.
abstract class Remote {
  String? get uid;
  Future<void> saveMember(Member m);
  Future<String> redeem(Reward reward, String code);
  Future<void> createBooking(Booking b);
  Future<void> setBookingStatus(Booking b, BookingStatus status);
  Future<void> setBookingPaid(Booking b, bool paid);
  Future<void> placeOrder(CafeOrder o, Map<String, int> dealQty);
  Future<void> setOrderStatus(CafeOrder o, OrderStatus status);
  Future<void> upsertMenuItem(MenuItem m);
  Future<void> deleteMenuItem(String id);
  Future<void> upsertDeal(LastCallDeal d);
  Future<void> removeDeal(String id);
  Future<void> updateSettings(Settings s);
  Future<void> updateBusiness(BusinessInfo b);

  /// Returns an error message, or null on success.
  Future<String?> staffSignIn(String email, String password);
  Future<void> staffSignOut();
}

/// Single source of truth for the app.
///
/// Two modes:
/// * **Local** (no Firebase configured): everything is persisted on-device
///   with SharedPreferences.
/// * **Cloud** ([remote] attached): bookings, orders, menu, settings and
///   members live in Firestore; the cart and onboarding flag stay local.
class AppStore extends ChangeNotifier {
  AppStore({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static const _key = 'stegoland.v1';
  final DateTime Function() _clock;
  final _rand = Random();

  DateTime get now => _clock();

  BusinessInfo business = defaultBusiness;
  Settings settings = defaultSettings;
  List<MenuItem> menu = List.of(defaultMenu);
  List<Booking> bookings = [];
  List<CafeOrder> orders = [];
  List<OrderLine> cart = [];
  List<Voucher> vouchers = [];
  List<LastCallDeal> deals = [];
  Member? member;
  bool onboarded = false;
  bool ready = false;

  // Cloud mode state
  Remote? remote;
  bool get isCloud => remote != null;
  bool isStaff = false;
  String? staffEmail;
  List<Booking> staffBookings = [];
  List<CafeOrder> staffOrders = [];
  List<SlotEntry> slotEntries = [];

  /// Bookings/orders visible in the staff panel.
  List<Booking> get adminBookings => isCloud ? staffBookings : bookings;
  List<CafeOrder> get adminOrders => isCloud ? staffOrders : orders;

  /// Applies a change pushed from the cloud.
  void applyRemote(void Function() change) {
    change();
    notifyListeners();
  }

  Future<void> persistLocal() => _save();

  // ---------------------------------------------------------------- storage

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) _fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Stegoland: failed to load saved data ($e), using defaults');
    }
    ready = true;
    notifyListeners();
  }

  void _fromJson(Map<String, dynamic> j) {
    List<Map<String, dynamic>> list(String k) =>
        ((j[k] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

    if (j['business'] != null) {
      business = BusinessInfo.fromJson(Map<String, dynamic>.from(j['business'] as Map));
    }
    if (j['settings'] != null) {
      settings = Settings.fromJson(Map<String, dynamic>.from(j['settings'] as Map));
    }
    if (j['menu'] != null) menu = list('menu').map(MenuItem.fromJson).toList();
    bookings = list('bookings').map(Booking.fromJson).toList();
    orders = list('orders').map(CafeOrder.fromJson).toList();
    cart = list('cart').map(OrderLine.fromJson).toList();
    vouchers = list('vouchers').map(Voucher.fromJson).toList();
    deals = list('deals').map(LastCallDeal.fromJson).toList();
    member = j['member'] == null ? null : Member.fromJson(Map<String, dynamic>.from(j['member'] as Map));
    onboarded = j['onboarded'] as bool? ?? false;
  }

  Map<String, dynamic> _toJson() => {
    'business': business.toJson(),
    'settings': settings.toJson(),
    'menu': menu.map((e) => e.toJson()).toList(),
    'bookings': bookings.map((e) => e.toJson()).toList(),
    'orders': orders.map((e) => e.toJson()).toList(),
    'cart': cart.map((e) => e.toJson()).toList(),
    'vouchers': vouchers.map((e) => e.toJson()).toList(),
    'deals': deals.map((e) => e.toJson()).toList(),
    if (member != null) 'member': member!.toJson(),
    'onboarded': onboarded,
  };

  Future<void> _save() async {
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(_toJson()));
    } catch (e) {
      debugPrint('Stegoland: failed to save ($e)');
    }
  }

  String _id(String prefix) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return '$prefix-${List.generate(6, (_) => chars[_rand.nextInt(chars.length)]).join()}';
  }

  // ---------------------------------------------------------------- member

  Future<void> completeOnboarding({String? name, String? phone}) async {
    if (name != null && name.trim().isNotEmpty && phone != null && phone.trim().isNotEmpty) {
      member = Member(id: _id('STG'), name: name.trim(), phone: phone.trim(), points: 0, joined: now);
      await _syncMember();
    }
    onboarded = true;
    await _save();
  }

  Future<void> updateMember({required String name, required String phone}) async {
    member = member == null
        ? Member(id: _id('STG'), name: name, phone: phone, points: 0, joined: now)
        : member!.copyWith(name: name, phone: phone);
    await _syncMember();
    await _save();
  }

  Future<void> _syncMember() async {
    if (remote == null || member == null) return;
    try {
      await remote!.saveMember(member!);
    } catch (e) {
      debugPrint('Stegoland: member sync failed ($e)');
    }
  }

  bool _isMine(String phone) => member != null && _digits(member!.phone) == _digits(phone) && _digits(phone).isNotEmpty;

  static String _digits(String s) => s.replaceAll(RegExp(r'\D'), '');

  Future<void> _awardPoints(String phone, double amount) async {
    if (!_isMine(phone)) return;
    member = member!.copyWith(points: member!.points + amount.floor());
  }

  Future<String?> redeem(Reward reward) async {
    final m = member;
    if (m == null || m.points < reward.cost) return null;
    if (remote != null) return remote!.redeem(reward, _id('RWD'));
    member = m.copyWith(points: m.points - reward.cost);
    final v = Voucher(code: _id('RWD'), title: reward.title, createdAt: now, used: false);
    vouchers = [v, ...vouchers];
    await _save();
    return v.code;
  }

  // ---------------------------------------------------------------- pricing

  DayType dayType(DateTime date) {
    if (settings.holidays.contains(dateKey(date))) return DayType.holiday;
    if (settings.weekendDays.contains(date.weekday)) return DayType.weekend;
    return DayType.weekday;
  }

  double childPrice(DateTime date) => switch (dayType(date)) {
    DayType.weekday => settings.weekdayPrice,
    DayType.weekend => settings.weekendPrice,
    DayType.holiday => settings.holidayPrice,
  };

  double familyTotal(DateTime date, int children, int guardians) =>
      childPrice(date) * children + settings.guardianPrice * guardians;

  GroupQuote groupQuote({
    required int children,
    required int teachers,
    required int meals,
    required int drinks,
    required bool privateSession,
  }) {
    final s = settings;
    final chargeable = max(0, teachers - s.freeTeachers);
    return GroupQuote(
      children: children,
      childTotal: children * s.groupChildPrice,
      chargeableTeachers: chargeable,
      teacherTotal: chargeable * s.extraTeacherPrice,
      mealTotal: meals * s.kidsMealPrice,
      drinkTotal: drinks * s.drinkPrice,
      privateTotal: privateSession ? s.privateSessionPrice : 0,
    );
  }

  // ---------------------------------------------------------------- slots

  TimeSlot? slotById(String id) {
    for (final s in settings.slots) {
      if (s.id == id) return s;
    }
    return null;
  }

  String slotLabel(String id) {
    final s = slotById(id);
    return s == null ? '-' : '${timeLabel(s.start)} – ${timeLabel(s.end)}';
  }

  /// Slots open for booking on [date] (Friday-prayer slots removed, past slots
  /// of today removed).
  List<TimeSlot> slotsFor(DateTime date) {
    final today = dateOnly(now);
    final d = dateOnly(date);
    if (d.isBefore(today)) return const [];
    final minutesNow = now.hour * 60 + now.minute;
    return settings.slots.where((s) {
      if (settings.fridayPrayerBreak && d.weekday == DateTime.friday) {
        const prayerStart = 12 * 60 + 15, prayerEnd = 14 * 60 + 45;
        if (s.start < prayerEnd && s.end > prayerStart) return false;
      }
      if (d == today && s.end <= minutesNow) return false;
      return true;
    }).toList();
  }

  Iterable<Booking> _activeIn(String date, String slotId) =>
      bookings.where((b) => b.date == date && b.slotId == slotId && b.status.isActive);

  Iterable<SlotEntry> _entriesIn(String date, String slotId) =>
      slotEntries.where((e) => e.date == date && e.slotId == slotId && e.active);

  int bookedChildren(DateTime date, String slotId) => isCloud
      ? _entriesIn(dateKey(date), slotId).fold(0, (a, e) => a + e.children)
      : _activeIn(dateKey(date), slotId).fold(0, (a, b) => a + b.children);

  bool isPrivate(DateTime date, String slotId) => isCloud
      ? _entriesIn(dateKey(date), slotId).any((e) => e.private)
      : _activeIn(dateKey(date), slotId).any((b) => b.group?.privateSession ?? false);

  int remaining(DateTime date, String slotId) {
    if (isPrivate(date, slotId)) return 0;
    return max(0, settings.slotCapacity - bookedChildren(date, slotId));
  }

  /// Validates a booking request; returns an error message or null.
  String? validate({
    required DateTime date,
    required String slotId,
    required int children,
    bool privateSession = false,
  }) {
    if (!slotsFor(date).any((s) => s.id == slotId)) {
      return 'Slot ini tidak dibuka untuk tempahan.';
    }
    if (children <= 0) return 'Sila pilih sekurang-kurangnya seorang kanak-kanak.';
    if (privateSession && bookedChildren(date, slotId) > 0) {
      return 'Sesi privasi memerlukan slot kosong. Sila pilih slot lain.';
    }
    final left = remaining(date, slotId);
    if (children > left) {
      return left == 0 ? 'Slot ini sudah penuh.' : 'Hanya tinggal $left tempat untuk slot ini.';
    }
    return null;
  }

  // ---------------------------------------------------------------- bookings

  Future<Booking> createFamilyBooking({
    required DateTime date,
    required String slotId,
    required int children,
    required int guardians,
    required String name,
    required String phone,
  }) async {
    final error = validate(date: date, slotId: slotId, children: children);
    if (error != null) throw StateError(error);
    final b = Booking(
      id: _id('TKT'),
      kind: BookingKind.family,
      date: dateKey(date),
      slotId: slotId,
      children: children,
      guardians: guardians,
      total: familyTotal(date, children, guardians),
      status: BookingStatus.confirmed,
      paid: false,
      contactName: name.trim(),
      contactPhone: phone.trim(),
      createdAt: now,
      ownerUid: remote?.uid,
    );
    return _addBooking(b);
  }

  Future<Booking> _addBooking(Booking b) async {
    if (remote != null) await remote!.createBooking(b);
    bookings = [b, ...bookings.where((x) => x.id != b.id)];
    await _save();
    return b;
  }

  Future<Booking> createGroupBooking({
    required DateTime date,
    required String slotId,
    required int children,
    required String picName,
    required String phone,
    required GroupDetails group,
  }) async {
    final error = validate(date: date, slotId: slotId, children: children, privateSession: group.privateSession);
    if (error != null) throw StateError(error);
    if (children < settings.groupMinimum) {
      throw StateError('Pakej kumpulan memerlukan minimum ${settings.groupMinimum} murid.');
    }
    final q = groupQuote(
      children: children,
      teachers: group.teachers,
      meals: group.meals,
      drinks: group.drinks,
      privateSession: group.privateSession,
    );
    final b = Booking(
      id: _id('GRP'),
      kind: BookingKind.group,
      date: dateKey(date),
      slotId: slotId,
      children: children,
      guardians: group.teachers,
      total: q.total,
      status: BookingStatus.pending,
      paid: false,
      contactName: picName.trim(),
      contactPhone: phone.trim(),
      createdAt: now,
      group: group,
      ownerUid: remote?.uid,
    );
    return _addBooking(b);
  }

  Booking? bookingById(String id) {
    for (final b in [...bookings, ...staffBookings]) {
      if (b.id == id) return b;
    }
    return null;
  }

  List<Booking> _replaceBooking(List<Booking> list, Booking nb) => [
    for (final b in list)
      if (b.id == nb.id) nb else b,
  ];

  Future<void> setBookingStatus(String id, BookingStatus status) async {
    if (remote != null) {
      final b = bookingById(id);
      if (b == null) return;
      await remote!.setBookingStatus(b, status);
      final nb = b.copyWith(status: status);
      bookings = _replaceBooking(bookings, nb);
      staffBookings = _replaceBooking(staffBookings, nb);
      return _save();
    }
    bookings = [
      for (final b in bookings)
        if (b.id == id) b.copyWith(status: status) else b,
    ];
    if (status == BookingStatus.checkedIn) {
      final b = bookingById(id)!;
      await _awardPoints(b.contactPhone, b.total);
    }
    await _save();
  }

  Future<void> setBookingPaid(String id, bool paid) async {
    if (remote != null) {
      final b = bookingById(id);
      if (b == null) return;
      await remote!.setBookingPaid(b, paid);
      final nb = b.copyWith(paid: paid);
      bookings = _replaceBooking(bookings, nb);
      staffBookings = _replaceBooking(staffBookings, nb);
      return _save();
    }
    bookings = [
      for (final b in bookings)
        if (b.id == id) b.copyWith(paid: paid) else b,
    ];
    await _save();
  }

  /// Bookings made from this device (the customer's own).
  List<Booking> get myBookings => bookings;

  // ---------------------------------------------------------------- cafe

  int get cartCount => cart.fold(0, (a, l) => a + l.qty);
  double get cartTotal => cart.fold(0, (a, l) => a + l.subtotal);

  int qtyInCart(String itemId) {
    for (final l in cart) {
      if (l.itemId == itemId) return l.qty;
    }
    return 0;
  }

  /// Adjusts any cart line (regular item or Last Call deal) by [delta].
  Future<void> changeCartLine(String cartId, int delta) async {
    if (cartId.startsWith('lc:')) {
      final d = _dealByCartId(cartId);
      if (d != null) return addDealToCart(d, delta);
      cart = cart.where((l) => l.itemId != cartId).toList();
      return _save();
    }
    final item = menuItem(cartId);
    if (item != null) return addToCart(item, delta);
  }

  Future<void> addToCart(MenuItem item, [int delta = 1]) async {
    if (!item.available && delta > 0) return;
    final current = qtyInCart(item.id);
    final next = current + delta;
    if (next <= 0) {
      cart = cart.where((l) => l.itemId != item.id).toList();
    } else if (current == 0) {
      cart = [...cart, OrderLine(itemId: item.id, name: item.name, price: item.price, qty: next)];
    } else {
      cart = [
        for (final l in cart)
          if (l.itemId == item.id) l.withQty(next) else l,
      ];
    }
    await _save();
  }

  // ---------------------------------------------------------------- last call

  int get _minutesNow => now.hour * 60 + now.minute;

  /// True while the end-of-day Last Call window is open.
  bool get lastCallActive {
    final s = settings;
    return s.lastCallEnabled && _minutesNow >= s.lastCallStart && _minutesNow < s.lastCallEnd;
  }

  /// Minutes until the window closes (when active) or opens (before it).
  int get lastCallMinutesLeft =>
      lastCallActive ? settings.lastCallEnd - _minutesNow : settings.lastCallStart - _minutesNow;

  /// Today's deals with stock, regardless of window (for teaser + admin).
  List<LastCallDeal> get todaysDeals => deals.where((d) => d.date == dateKey(now) && d.qtyLeft > 0).toList();

  /// Deals customers can buy right now.
  List<LastCallDeal> get activeDeals => lastCallActive ? todaysDeals : const [];

  bool get lastCallUpcoming =>
      settings.lastCallEnabled && _minutesNow < settings.lastCallStart && todaysDeals.isNotEmpty;

  LastCallDeal? _dealByCartId(String cartId) {
    for (final d in deals) {
      if (d.cartId == cartId) return d;
    }
    return null;
  }

  MenuItem? menuItem(String id) {
    for (final m in menu) {
      if (m.id == id) return m;
    }
    return null;
  }

  Future<void> addDealToCart(LastCallDeal deal, [int delta = 1]) async {
    final item = menuItem(deal.itemId);
    if (item == null) return;
    final current = qtyInCart(deal.cartId);
    final next = (current + delta).clamp(0, deal.qtyLeft);
    if (delta > 0 && !lastCallActive) return;
    if (next == 0) {
      cart = cart.where((l) => l.itemId != deal.cartId).toList();
    } else if (current == 0) {
      cart = [...cart, OrderLine(itemId: deal.cartId, name: '${item.name} (Last Call)', price: deal.price, qty: next)];
    } else {
      cart = [
        for (final l in cart)
          if (l.itemId == deal.cartId) l.withQty(next) else l,
      ];
    }
    await _save();
  }

  /// Staff: put an item on Last Call for today (replaces an existing deal
  /// for the same item).
  Future<void> upsertDeal({required String itemId, required double price, required int qty}) async {
    final today = dateKey(now);
    final existing = deals.where((d) => d.itemId == itemId && d.date == today).firstOrNull;
    final deal =
        existing?.copyWith(price: price, qtyLeft: qty) ??
        LastCallDeal(id: _id('LC'), itemId: itemId, date: today, price: price, qtyLeft: qty);
    if (remote != null) await remote!.upsertDeal(deal);
    // Drop deals from previous days while we're here.
    deals = [
      for (final d in deals)
        if (d.date == today && d.id != deal.id) d,
      deal,
    ];
    await _save();
  }

  Future<void> removeDeal(String id) async {
    final d = deals.where((d) => d.id == id).firstOrNull;
    if (remote != null) await remote!.removeDeal(id);
    deals = deals.where((d) => d.id != id).toList();
    if (d != null) cart = cart.where((l) => l.itemId != d.cartId).toList();
    await _save();
  }

  Future<void> clearCart() async {
    cart = [];
    await _save();
  }

  Future<CafeOrder> placeOrder({
    required OrderMode mode,
    required String table,
    required String name,
    required String note,
  }) async {
    if (cart.isEmpty) throw StateError('Troli kosong.');
    // Re-check Last Call lines: window may have closed or stock sold out.
    for (final l in cart.where((l) => l.itemId.startsWith('lc:'))) {
      final d = _dealByCartId(l.itemId);
      if (d == null || !lastCallActive || d.date != dateKey(now)) {
        throw StateError('Tawaran Last Call "${l.name}" sudah tamat. Sila buang dari troli.');
      }
      if (l.qty > d.qtyLeft) {
        throw StateError('Hanya tinggal ${d.qtyLeft} untuk "${l.name}".');
      }
    }
    final dealQty = <String, int>{
      for (final l in cart.where((l) => l.itemId.startsWith('lc:'))) _dealByCartId(l.itemId)!.id: l.qty,
    };
    final o = CafeOrder(
      id: _id('ORD'),
      lines: List.of(cart),
      mode: mode,
      table: table.trim(),
      customerName: name.trim(),
      note: note.trim(),
      status: OrderStatus.received,
      createdAt: now,
      ownerUid: remote?.uid,
    );
    if (remote != null) await remote!.placeOrder(o, dealQty);
    deals = [for (final d in deals) d.copyWith(qtyLeft: d.qtyLeft - (dealQty[d.id] ?? 0))];
    orders = [o, ...orders];
    cart = [];
    await _save();
    return o;
  }

  Future<void> setOrderStatus(String id, OrderStatus status) async {
    if (remote != null) {
      final o = [...staffOrders, ...orders].where((o) => o.id == id).firstOrNull;
      if (o == null) return;
      await remote!.setOrderStatus(o, status);
      List<CafeOrder> repl(List<CafeOrder> l) => [
        for (final x in l)
          if (x.id == id) x.copyWith(status: status) else x,
      ];
      staffOrders = repl(staffOrders);
      orders = repl(orders);
      return _save();
    }
    CafeOrder? changed;
    orders = [
      for (final o in orders)
        if (o.id == id) (changed = o.copyWith(status: status)) else o,
    ];
    if (status == OrderStatus.completed && changed != null && member != null) {
      await _awardPoints(member!.phone, changed.total);
    }
    await _save();
  }

  // ---------------------------------------------------------------- admin

  bool checkPin(String pin) => pin == settings.adminPin;

  /// Cloud mode: signs a staff member in (separate session from the customer).
  Future<String?> staffSignIn(String email, String password) async {
    final err = await remote!.staffSignIn(email.trim(), password);
    return err;
  }

  Future<void> staffSignOut() async {
    await remote?.staffSignOut();
    applyRemote(() {
      isStaff = false;
      staffEmail = null;
      staffBookings = [];
      staffOrders = [];
    });
  }

  Future<void> upsertMenuItem(MenuItem item) async {
    if (remote != null) await remote!.upsertMenuItem(item);
    final exists = menu.any((m) => m.id == item.id);
    menu = exists
        ? [
            for (final m in menu)
              if (m.id == item.id) item else m,
          ]
        : [...menu, item];
    await _save();
  }

  MenuItem newMenuItem() =>
      MenuItem(id: _id('M'), name: '', category: menuCategories.first, price: 0, description: '', available: true);

  Future<void> deleteMenuItem(String id) async {
    if (remote != null) await remote!.deleteMenuItem(id);
    menu = menu.where((m) => m.id != id).toList();
    cart = cart.where((l) => l.itemId != id).toList();
    await _save();
  }

  Future<void> updateSettings(Settings s) async {
    if (remote != null) await remote!.updateSettings(s);
    settings = s;
    await _save();
  }

  Future<void> updateBusiness(BusinessInfo b) async {
    if (remote != null) await remote!.updateBusiness(b);
    business = b;
    await _save();
  }

  Future<void> resetAll() async {
    business = defaultBusiness;
    settings = defaultSettings;
    menu = List.of(defaultMenu);
    bookings = [];
    orders = [];
    cart = [];
    vouchers = [];
    deals = [];
    member = null;
    onboarded = false;
    await _save();
  }

  // Dashboard helpers
  List<Booking> bookingsOn(DateTime date) =>
      adminBookings.where((b) => b.date == dateKey(date) && b.status.isActive).toList();

  double revenueOn(DateTime date) {
    final k = dateKey(date);
    final tix = adminBookings.where((b) => b.date == k && b.status.isActive).fold<double>(0, (a, b) => a + b.total);
    final food = adminOrders
        .where((o) => dateKey(o.createdAt) == k && o.status != OrderStatus.cancelled)
        .fold<double>(0, (a, o) => a + o.total);
    return tix + food;
  }

  int get pendingGroups =>
      adminBookings.where((b) => b.kind == BookingKind.group && b.status == BookingStatus.pending).length;

  int get openOrders =>
      adminOrders.where((o) => o.status != OrderStatus.completed && o.status != OrderStatus.cancelled).length;
}
