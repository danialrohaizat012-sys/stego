// Plain data models with hand-written JSON (de)serialisation so the app has
// no code-generation step. All money values are in Ringgit (double).

enum DayType { weekday, weekend, holiday }

extension DayTypeLabel on DayType {
  String get label => switch (this) {
    DayType.weekday => 'Hari Biasa',
    DayType.weekend => 'Hujung Minggu',
    DayType.holiday => 'Cuti Umum / Sekolah',
  };
}

class TimeSlot {
  const TimeSlot({required this.id, required this.start, required this.end});

  final String id;

  /// Minutes from midnight.
  final int start;
  final int end;

  Map<String, dynamic> toJson() => {'id': id, 'start': start, 'end': end};
  factory TimeSlot.fromJson(Map<String, dynamic> j) =>
      TimeSlot(id: j['id'] as String, start: (j['start'] as num).toInt(), end: (j['end'] as num).toInt());
}

class BusinessInfo {
  const BusinessInfo({
    required this.name,
    required this.cafeName,
    required this.tagline,
    required this.address,
    required this.mapsQuery,
    required this.phone,
    required this.whatsapp,
    required this.tiktok,
    required this.facebook,
    required this.openingHours,
  });

  final String name;
  final String cafeName;
  final String tagline;
  final String address;
  final String mapsQuery;
  final String phone;

  /// International format without '+', e.g. 60182351000.
  final String whatsapp;
  final String tiktok;
  final String facebook;
  final String openingHours;

  BusinessInfo copyWith({String? address, String? phone, String? whatsapp, String? openingHours}) => BusinessInfo(
    name: name,
    cafeName: cafeName,
    tagline: tagline,
    address: address ?? this.address,
    mapsQuery: mapsQuery,
    phone: phone ?? this.phone,
    whatsapp: whatsapp ?? this.whatsapp,
    tiktok: tiktok,
    facebook: facebook,
    openingHours: openingHours ?? this.openingHours,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'cafeName': cafeName,
    'tagline': tagline,
    'address': address,
    'mapsQuery': mapsQuery,
    'phone': phone,
    'whatsapp': whatsapp,
    'tiktok': tiktok,
    'facebook': facebook,
    'openingHours': openingHours,
  };

  factory BusinessInfo.fromJson(Map<String, dynamic> j) => BusinessInfo(
    name: j['name'] as String,
    cafeName: j['cafeName'] as String,
    tagline: j['tagline'] as String,
    address: j['address'] as String,
    mapsQuery: j['mapsQuery'] as String,
    phone: j['phone'] as String,
    whatsapp: j['whatsapp'] as String,
    tiktok: j['tiktok'] as String,
    facebook: j['facebook'] as String,
    openingHours: j['openingHours'] as String,
  );
}

class Settings {
  const Settings({
    required this.weekdayPrice,
    required this.weekendPrice,
    required this.holidayPrice,
    required this.guardianPrice,
    required this.groupChildPrice,
    required this.freeTeachers,
    required this.extraTeacherPrice,
    required this.kidsMealPrice,
    required this.drinkPrice,
    required this.privateSessionPrice,
    required this.groupMinimum,
    required this.slotCapacity,
    required this.slots,
    required this.weekendDays,
    required this.holidays,
    required this.fridayPrayerBreak,
    required this.adminPin,
    this.lastCallEnabled = true,
    this.lastCallStart = 20 * 60,
    this.lastCallEnd = 22 * 60,
  });

  /// Last Call (end-of-day cafe markdown) window, minutes from midnight.
  final bool lastCallEnabled;
  final int lastCallStart;
  final int lastCallEnd;

  final double weekdayPrice;
  final double weekendPrice;
  final double holidayPrice;
  final double guardianPrice;

  // Group / school visit package
  final double groupChildPrice;
  final int freeTeachers;
  final double extraTeacherPrice;
  final double kidsMealPrice;
  final double drinkPrice;
  final double privateSessionPrice;
  final int groupMinimum;

  /// Maximum children per slot.
  final int slotCapacity;
  final List<TimeSlot> slots;

  /// DateTime.weekday values treated as weekend. Kelantan: Friday (5) & Saturday (6).
  final List<int> weekendDays;

  /// Public / school holiday dates as yyyy-MM-dd.
  final List<String> holidays;

  /// Hide slots overlapping Friday prayers (12:15–14:45).
  final bool fridayPrayerBreak;
  final String adminPin;

  Settings copyWith({
    double? weekdayPrice,
    double? weekendPrice,
    double? holidayPrice,
    double? guardianPrice,
    double? groupChildPrice,
    int? freeTeachers,
    double? extraTeacherPrice,
    double? kidsMealPrice,
    double? drinkPrice,
    double? privateSessionPrice,
    int? groupMinimum,
    int? slotCapacity,
    List<TimeSlot>? slots,
    List<int>? weekendDays,
    List<String>? holidays,
    bool? fridayPrayerBreak,
    String? adminPin,
    bool? lastCallEnabled,
    int? lastCallStart,
    int? lastCallEnd,
  }) => Settings(
    weekdayPrice: weekdayPrice ?? this.weekdayPrice,
    weekendPrice: weekendPrice ?? this.weekendPrice,
    holidayPrice: holidayPrice ?? this.holidayPrice,
    guardianPrice: guardianPrice ?? this.guardianPrice,
    groupChildPrice: groupChildPrice ?? this.groupChildPrice,
    freeTeachers: freeTeachers ?? this.freeTeachers,
    extraTeacherPrice: extraTeacherPrice ?? this.extraTeacherPrice,
    kidsMealPrice: kidsMealPrice ?? this.kidsMealPrice,
    drinkPrice: drinkPrice ?? this.drinkPrice,
    privateSessionPrice: privateSessionPrice ?? this.privateSessionPrice,
    groupMinimum: groupMinimum ?? this.groupMinimum,
    slotCapacity: slotCapacity ?? this.slotCapacity,
    slots: slots ?? this.slots,
    weekendDays: weekendDays ?? this.weekendDays,
    holidays: holidays ?? this.holidays,
    fridayPrayerBreak: fridayPrayerBreak ?? this.fridayPrayerBreak,
    adminPin: adminPin ?? this.adminPin,
    lastCallEnabled: lastCallEnabled ?? this.lastCallEnabled,
    lastCallStart: lastCallStart ?? this.lastCallStart,
    lastCallEnd: lastCallEnd ?? this.lastCallEnd,
  );

  Map<String, dynamic> toJson() => {
    'weekdayPrice': weekdayPrice,
    'weekendPrice': weekendPrice,
    'holidayPrice': holidayPrice,
    'guardianPrice': guardianPrice,
    'groupChildPrice': groupChildPrice,
    'freeTeachers': freeTeachers,
    'extraTeacherPrice': extraTeacherPrice,
    'kidsMealPrice': kidsMealPrice,
    'drinkPrice': drinkPrice,
    'privateSessionPrice': privateSessionPrice,
    'groupMinimum': groupMinimum,
    'slotCapacity': slotCapacity,
    'slots': slots.map((s) => s.toJson()).toList(),
    'weekendDays': weekendDays,
    'holidays': holidays,
    'fridayPrayerBreak': fridayPrayerBreak,
    'adminPin': adminPin,
    'lastCallEnabled': lastCallEnabled,
    'lastCallStart': lastCallStart,
    'lastCallEnd': lastCallEnd,
  };

  factory Settings.fromJson(Map<String, dynamic> j) => Settings(
    weekdayPrice: (j['weekdayPrice'] as num).toDouble(),
    weekendPrice: (j['weekendPrice'] as num).toDouble(),
    holidayPrice: (j['holidayPrice'] as num).toDouble(),
    guardianPrice: (j['guardianPrice'] as num).toDouble(),
    groupChildPrice: (j['groupChildPrice'] as num).toDouble(),
    freeTeachers: (j['freeTeachers'] as num).toInt(),
    extraTeacherPrice: (j['extraTeacherPrice'] as num).toDouble(),
    kidsMealPrice: (j['kidsMealPrice'] as num).toDouble(),
    drinkPrice: (j['drinkPrice'] as num).toDouble(),
    privateSessionPrice: (j['privateSessionPrice'] as num).toDouble(),
    groupMinimum: (j['groupMinimum'] as num).toInt(),
    slotCapacity: (j['slotCapacity'] as num).toInt(),
    slots: (j['slots'] as List).map((e) => TimeSlot.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    weekendDays: (j['weekendDays'] as List).map((e) => (e as num).toInt()).toList(),
    holidays: (j['holidays'] as List).cast<String>(),
    fridayPrayerBreak: j['fridayPrayerBreak'] as bool,
    adminPin: j['adminPin'] as String,
    lastCallEnabled: j['lastCallEnabled'] as bool? ?? true,
    lastCallStart: (j['lastCallStart'] as num?)?.toInt() ?? 20 * 60,
    lastCallEnd: (j['lastCallEnd'] as num?)?.toInt() ?? 22 * 60,
  );
}

enum BookingKind { family, group }

enum BookingStatus { pending, confirmed, checkedIn, cancelled, rejected }

extension BookingStatusLabel on BookingStatus {
  String get label => switch (this) {
    BookingStatus.pending => 'Menunggu Pengesahan',
    BookingStatus.confirmed => 'Disahkan',
    BookingStatus.checkedIn => 'Sudah Masuk',
    BookingStatus.cancelled => 'Dibatalkan',
    BookingStatus.rejected => 'Ditolak',
  };

  bool get isActive =>
      this == BookingStatus.pending || this == BookingStatus.confirmed || this == BookingStatus.checkedIn;
}

class GroupDetails {
  const GroupDetails({
    required this.institution,
    required this.institutionType,
    required this.teachers,
    required this.meals,
    required this.drinks,
    required this.privateSession,
    required this.notes,
  });

  final String institution;

  /// Tadika, Sekolah Rendah, Taska, Lain-lain
  final String institutionType;
  final int teachers;
  final int meals;
  final int drinks;
  final bool privateSession;
  final String notes;

  Map<String, dynamic> toJson() => {
    'institution': institution,
    'institutionType': institutionType,
    'teachers': teachers,
    'meals': meals,
    'drinks': drinks,
    'privateSession': privateSession,
    'notes': notes,
  };

  factory GroupDetails.fromJson(Map<String, dynamic> j) => GroupDetails(
    institution: j['institution'] as String,
    institutionType: j['institutionType'] as String,
    teachers: (j['teachers'] as num).toInt(),
    meals: (j['meals'] as num).toInt(),
    drinks: (j['drinks'] as num).toInt(),
    privateSession: j['privateSession'] as bool,
    notes: j['notes'] as String? ?? '',
  );
}

class Booking {
  const Booking({
    required this.id,
    required this.kind,
    required this.date,
    required this.slotId,
    required this.children,
    required this.guardians,
    required this.total,
    required this.status,
    required this.paid,
    required this.contactName,
    required this.contactPhone,
    required this.createdAt,
    this.group,
    this.ownerUid,
  });

  /// Firebase Auth uid of the customer who made it (null in local mode).
  final String? ownerUid;

  final String id;
  final BookingKind kind;

  /// yyyy-MM-dd
  final String date;
  final String slotId;
  final int children;
  final int guardians;
  final double total;
  final BookingStatus status;
  final bool paid;
  final String contactName;
  final String contactPhone;
  final DateTime createdAt;
  final GroupDetails? group;

  Booking copyWith({BookingStatus? status, bool? paid}) => Booking(
    id: id,
    kind: kind,
    date: date,
    slotId: slotId,
    children: children,
    guardians: guardians,
    total: total,
    status: status ?? this.status,
    paid: paid ?? this.paid,
    contactName: contactName,
    contactPhone: contactPhone,
    createdAt: createdAt,
    group: group,
    ownerUid: ownerUid,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'date': date,
    'slotId': slotId,
    'children': children,
    'guardians': guardians,
    'total': total,
    'status': status.name,
    'paid': paid,
    'contactName': contactName,
    'contactPhone': contactPhone,
    'createdAt': createdAt.toIso8601String(),
    if (group != null) 'group': group!.toJson(),
    if (ownerUid != null) 'ownerUid': ownerUid,
  };

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
    id: j['id'] as String,
    kind: BookingKind.values.byName(j['kind'] as String),
    date: j['date'] as String,
    slotId: j['slotId'] as String,
    children: (j['children'] as num).toInt(),
    guardians: (j['guardians'] as num).toInt(),
    total: (j['total'] as num).toDouble(),
    status: BookingStatus.values.byName(j['status'] as String),
    paid: j['paid'] as bool,
    contactName: j['contactName'] as String,
    contactPhone: j['contactPhone'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
    group: j['group'] == null ? null : GroupDetails.fromJson(Map<String, dynamic>.from(j['group'] as Map)),
    ownerUid: j['ownerUid'] as String?,
  );
}

class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.available,
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final String description;
  final bool available;

  MenuItem copyWith({String? name, String? category, double? price, String? description, bool? available}) => MenuItem(
    id: id,
    name: name ?? this.name,
    category: category ?? this.category,
    price: price ?? this.price,
    description: description ?? this.description,
    available: available ?? this.available,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'price': price,
    'description': description,
    'available': available,
  };

  factory MenuItem.fromJson(Map<String, dynamic> j) => MenuItem(
    id: j['id'] as String,
    name: j['name'] as String,
    category: j['category'] as String,
    price: (j['price'] as num).toDouble(),
    description: j['description'] as String? ?? '',
    available: j['available'] as bool,
  );
}

class OrderLine {
  const OrderLine({required this.itemId, required this.name, required this.price, required this.qty});

  final String itemId;
  final String name;
  final double price;
  final int qty;

  double get subtotal => price * qty;

  OrderLine withQty(int q) => OrderLine(itemId: itemId, name: name, price: price, qty: q);

  Map<String, dynamic> toJson() => {'itemId': itemId, 'name': name, 'price': price, 'qty': qty};
  factory OrderLine.fromJson(Map<String, dynamic> j) => OrderLine(
    itemId: j['itemId'] as String,
    name: j['name'] as String,
    price: (j['price'] as num).toDouble(),
    qty: (j['qty'] as num).toInt(),
  );
}

enum OrderMode { dineIn, takeaway }

enum OrderStatus { received, preparing, ready, completed, cancelled }

extension OrderStatusLabel on OrderStatus {
  String get label => switch (this) {
    OrderStatus.received => 'Diterima',
    OrderStatus.preparing => 'Sedang Disediakan',
    OrderStatus.ready => 'Sedia Diambil',
    OrderStatus.completed => 'Selesai',
    OrderStatus.cancelled => 'Dibatalkan',
  };

  OrderStatus? get next => switch (this) {
    OrderStatus.received => OrderStatus.preparing,
    OrderStatus.preparing => OrderStatus.ready,
    OrderStatus.ready => OrderStatus.completed,
    _ => null,
  };
}

class CafeOrder {
  const CafeOrder({
    required this.id,
    required this.lines,
    required this.mode,
    required this.table,
    required this.customerName,
    required this.note,
    required this.status,
    required this.createdAt,
    this.ownerUid,
  });

  final String id;
  final String? ownerUid;
  final List<OrderLine> lines;
  final OrderMode mode;
  final String table;
  final String customerName;
  final String note;
  final OrderStatus status;
  final DateTime createdAt;

  double get total => lines.fold(0, (a, l) => a + l.subtotal);
  int get itemCount => lines.fold(0, (a, l) => a + l.qty);

  CafeOrder copyWith({OrderStatus? status}) => CafeOrder(
    id: id,
    lines: lines,
    mode: mode,
    table: table,
    customerName: customerName,
    note: note,
    status: status ?? this.status,
    createdAt: createdAt,
    ownerUid: ownerUid,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    if (ownerUid != null) 'ownerUid': ownerUid,
    'total': total,
    'lines': lines.map((l) => l.toJson()).toList(),
    'mode': mode.name,
    'table': table,
    'customerName': customerName,
    'note': note,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory CafeOrder.fromJson(Map<String, dynamic> j) => CafeOrder(
    id: j['id'] as String,
    lines: (j['lines'] as List).map((e) => OrderLine.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    mode: OrderMode.values.byName(j['mode'] as String),
    table: j['table'] as String? ?? '',
    customerName: j['customerName'] as String? ?? '',
    note: j['note'] as String? ?? '',
    status: OrderStatus.values.byName(j['status'] as String),
    createdAt: DateTime.parse(j['createdAt'] as String),
    ownerUid: j['ownerUid'] as String?,
  );
}

class Member {
  const Member({required this.id, required this.name, required this.phone, required this.points, required this.joined});

  final String id;
  final String name;
  final String phone;
  final int points;
  final DateTime joined;

  Member copyWith({String? name, String? phone, int? points}) => Member(
    id: id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    points: points ?? this.points,
    joined: joined,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'points': points,
    'joined': joined.toIso8601String(),
  };

  factory Member.fromJson(Map<String, dynamic> j) => Member(
    id: j['id'] as String,
    name: j['name'] as String,
    phone: j['phone'] as String,
    points: (j['points'] as num).toInt(),
    joined: DateTime.parse(j['joined'] as String),
  );
}

class Reward {
  const Reward({required this.id, required this.title, required this.description, required this.cost});

  final String id;
  final String title;
  final String description;
  final int cost;
}

class Voucher {
  const Voucher({required this.code, required this.title, required this.createdAt, required this.used});

  final String code;
  final String title;
  final DateTime createdAt;
  final bool used;

  Map<String, dynamic> toJson() => {
    'code': code,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'used': used,
  };
  factory Voucher.fromJson(Map<String, dynamic> j) => Voucher(
    code: j['code'] as String,
    title: j['title'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
    used: j['used'] as bool,
  );
}

/// "Last Call" — an end-of-day markdown on a cafe item (like a supermarket
/// yellow-sticker discount). A deal is valid only on [date] and only inside
/// the configured Last Call window, while [qtyLeft] > 0.
class LastCallDeal {
  const LastCallDeal({
    required this.id,
    required this.itemId,
    required this.date,
    required this.price,
    required this.qtyLeft,
  });

  final String id;
  final String itemId;

  /// yyyy-MM-dd
  final String date;
  final double price;
  final int qtyLeft;

  /// Cart line id used for this deal.
  String get cartId => 'lc:$id';

  LastCallDeal copyWith({double? price, int? qtyLeft}) =>
      LastCallDeal(id: id, itemId: itemId, date: date, price: price ?? this.price, qtyLeft: qtyLeft ?? this.qtyLeft);

  Map<String, dynamic> toJson() => {'id': id, 'itemId': itemId, 'date': date, 'price': price, 'qtyLeft': qtyLeft};

  factory LastCallDeal.fromJson(Map<String, dynamic> j) => LastCallDeal(
    id: j['id'] as String,
    itemId: j['itemId'] as String,
    date: j['date'] as String,
    price: (j['price'] as num).toDouble(),
    qtyLeft: (j['qtyLeft'] as num).toInt(),
  );
}
