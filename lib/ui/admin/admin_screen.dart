import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/seed.dart';
import '../../data/store.dart';
import '../booking/pickers.dart';
import '../booking/ticket_screen.dart';
import '../cafe/last_call.dart';
import '../tickets/my_tickets_screen.dart';
import '../widgets/common.dart';

/// Staff panel: dashboard, bookings, cafe orders, menu and settings.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel Staf'),
          actions: [
            if (store.isCloud)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Tooltip(
                  message: 'Disambung ke Firebase${store.staffEmail == null ? '' : ' • ${store.staffEmail}'}',
                  child: const Icon(Icons.cloud_done_rounded, color: StegoColors.mint),
                ),
              ),
            if (store.isCloud)
              IconButton(
                tooltip: 'Log keluar staf',
                onPressed: () async {
                  await store.staffSignOut();
                  if (context.mounted) Navigator.of(context).pop();
                },
                icon: const Icon(Icons.logout_rounded),
              ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontFamily: StegoTheme.body),
            tabs: [
              const Tab(text: 'Ringkasan'),
              Tab(child: _TabLabel('Tempahan', store.pendingGroups)),
              Tab(child: _TabLabel('Pesanan', store.openOrders)),
              const Tab(text: 'Menu'),
              const Tab(text: 'Tetapan'),
            ],
          ),
        ),
        body: const TabBarView(children: [_Dashboard(), _Bookings(), _Orders(), _MenuAdmin(), _SettingsAdmin()]),
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel(this.text, this.count);
  final String text;
  final int count;

  @override
  Widget build(BuildContext context) =>
      Badge(isLabelVisible: count > 0, label: Text('$count'), offset: const Offset(14, -6), child: Text(text));
}

// --------------------------------------------------------------- dashboard

class _Dashboard extends StatefulWidget {
  const _Dashboard();

  @override
  State<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<_Dashboard> {
  late DateTime _date = dateOnly(context.read<AppStore>().now);

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final bookings = store.bookingsOn(_date);
    final kids = bookings.fold<int>(0, (a, b) => a + b.children);
    final adults = bookings.fold<int>(0, (a, b) => a + b.guardians);
    final ordersToday = store.adminOrders.where((o) => dateKey(o.createdAt) == dateKey(_date)).length;

    Widget kpi(String label, String value, IconData icon, Color color) => Expanded(
      child: StegoCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBadge(icon, color: color, size: 36),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontFamily: StegoTheme.display, fontSize: 24, fontWeight: FontWeight.w700),
            ),
            Text(
              label,
              style: const TextStyle(color: StegoColors.muted, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );

    return ContentWidth(
      maxWidth: 900,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          DateStrip(selected: _date, days: 30, onSelected: (d) => setState(() => _date = d)),
          const SizedBox(height: 16),
          Row(
            children: [
              kpi('Kanak-kanak', '$kids', Icons.child_care_rounded, StegoColors.navy),
              const SizedBox(width: 10),
              kpi('Dewasa / guru', '$adults', Icons.person_rounded, StegoColors.sky),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              kpi('Jualan (anggaran)', rm(store.revenueOn(_date)), Icons.payments_rounded, StegoColors.mint),
              const SizedBox(width: 10),
              kpi('Pesanan kafe', '$ordersToday', Icons.local_cafe_rounded, StegoColors.jasmine),
            ],
          ),
          const SizedBox(height: 18),
          const SectionHeader('Kapasiti slot'),
          StegoCard(
            child: Column(
              children: [
                for (final s in store.settings.slots) _CapacityRow(date: _date, slot: s),
                if (store.settings.slots.isEmpty) const Text('Tiada slot ditetapkan.'),
              ],
            ),
          ),
          if (store.pendingGroups > 0) ...[
            const SizedBox(height: 18),
            const SectionHeader('Permohonan kumpulan menunggu'),
            for (final b in store.adminBookings.where(
              (b) => b.kind == BookingKind.group && b.status == BookingStatus.pending,
            ))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: BookingTile(booking: b, onTap: () => _showBookingActions(context, b)),
              ),
          ],
        ],
      ),
    );
  }
}

class _CapacityRow extends StatelessWidget {
  const _CapacityRow({required this.date, required this.slot});
  final DateTime date;
  final TimeSlot slot;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final cap = store.settings.slotCapacity;
    final booked = store.bookedChildren(date, slot.id);
    final private = store.isPrivate(date, slot.id);
    final ratio = cap == 0 ? 0.0 : (booked / cap).clamp(0, 1).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '${timeLabel(slot.start)} – ${timeLabel(slot.end)}',
              maxLines: 1,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: private ? 1 : ratio,
                minHeight: 10,
                backgroundColor: StegoColors.surface,
                color: private
                    ? StegoColors.rocket
                    : ratio > 0.85
                    ? StegoColors.rocket
                    : ratio > 0.6
                    ? StegoColors.flame
                    : StegoColors.mint,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 64,
            child: Text(
              private ? 'Privasi' : '$booked/$cap',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- bookings

Future<void> _showBookingActions(BuildContext context, Booking b) async {
  final store = context.read<AppStore>();
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    builder: (c) {
      Widget action(String label, IconData icon, Color color, Future<void> Function() run) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: color, minimumSize: const Size.fromHeight(50)),
          onPressed: () async {
            try {
              await run();
            } catch (e) {
              if (context.mounted) showSnack(context, errorMessage(e));
            }
            if (c.mounted) Navigator.pop(c);
          },
          icon: Icon(icon),
          label: Text(label),
        ),
      );
      final g = b.group;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(b.id, style: Theme.of(c).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: StatusPill(b.status.label, color: bookingStatusColor(b.status)),
              ),
              const SizedBox(height: 10),
              if (g != null) ...[
                LineRow('Institusi', '${g.institution} (${g.institutionType})'),
                LineRow('Murid / guru', '${b.children} / ${g.teachers}'),
                LineRow('Kids Meal / minuman', '${g.meals} / ${g.drinks}'),
                LineRow('Sesi privasi', g.privateSession ? 'Ya' : 'Tidak'),
                if (g.notes.isNotEmpty) LineRow('Catatan', g.notes),
              ] else
                LineRow('Kanak-kanak / penjaga', '${b.children} / ${b.guardians}'),
              LineRow('Tarikh', longDate(parseDateKey(b.date))),
              LineRow('Slot', store.slotLabel(b.slotId)),
              LineRow('Hubungi', '${b.contactName} • ${b.contactPhone}'),
              LineRow('Jumlah', rm(b.total), bold: true),
              const SizedBox(height: 8),
              if (b.status == BookingStatus.pending) ...[
                action(
                  'Sahkan',
                  Icons.check_circle_rounded,
                  StegoColors.mint,
                  () => store.setBookingStatus(b.id, BookingStatus.confirmed),
                ),
                action(
                  'Tolak',
                  Icons.cancel_rounded,
                  StegoColors.rocket,
                  () => store.setBookingStatus(b.id, BookingStatus.rejected),
                ),
              ],
              if (b.status == BookingStatus.confirmed)
                action(
                  'Daftar Masuk',
                  Icons.login_rounded,
                  StegoColors.navy,
                  () => store.setBookingStatus(b.id, BookingStatus.checkedIn),
                ),
              if (b.status.isActive)
                action(
                  b.paid ? 'Tanda belum bayar' : 'Tanda sudah bayar',
                  Icons.payments_rounded,
                  b.paid ? StegoColors.muted : StegoColors.jasmine,
                  () => store.setBookingPaid(b.id, !b.paid),
                ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () {
                  Navigator.pop(c);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => TicketScreen(bookingId: b.id)));
                },
                child: const Text('Lihat tiket'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _Bookings extends StatefulWidget {
  const _Bookings();

  @override
  State<_Bookings> createState() => _BookingsState();
}

class _BookingsState extends State<_Bookings> {
  late DateTime _date = dateOnly(context.read<AppStore>().now);
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final q = _search.text.trim().toUpperCase().replaceFirst('STEGOLAND:', '');
    final list = q.isNotEmpty
        ? store.adminBookings
              .where(
                (b) =>
                    b.id.contains(q) ||
                    b.contactName.toUpperCase().contains(q) ||
                    b.contactPhone.contains(q) ||
                    (b.group?.institution.toUpperCase().contains(q) ?? false),
              )
              .toList()
        : (store.adminBookings.where((b) => b.date == dateKey(_date)).toList()
            ..sort((a, b) => a.slotId.compareTo(b.slotId)));

    return ContentWidth(
      maxWidth: 900,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Cari ID tiket, nama, telefon atau sekolah',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(onPressed: () => setState(_search.clear), icon: const Icon(Icons.close_rounded)),
            ),
          ),
          const SizedBox(height: 14),
          if (q.isEmpty) ...[
            DateStrip(selected: _date, days: 60, showPrice: false, onSelected: (d) => setState(() => _date = d)),
            const SizedBox(height: 14),
          ],
          if (list.isEmpty)
            const EmptyState(
              icon: Icons.event_note_rounded,
              title: 'Tiada tempahan',
              message: 'Tiada tempahan untuk paparan ini.',
            )
          else
            for (final b in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: BookingTile(
                  booking: b,
                  onTap: () => _showBookingActions(context, b),
                  trailing: const Icon(Icons.more_vert_rounded),
                ),
              ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- orders

class _Orders extends StatelessWidget {
  const _Orders();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final open = store.adminOrders
        .where((o) => o.status != OrderStatus.completed && o.status != OrderStatus.cancelled)
        .toList()
        .reversed // oldest first, like a kitchen queue
        .toList();
    final done = store.adminOrders.where((o) => !open.contains(o)).take(20).toList();

    Widget card(CafeOrder o) {
      final next = o.status.next;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: StegoCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(o.id, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(width: 8),
                  StatusPill(o.status.label, color: orderStatusColor(o.status)),
                  const Spacer(),
                  Text(
                    hhmm(o.createdAt),
                    style: const TextStyle(color: StegoColors.muted, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${o.mode == OrderMode.dineIn ? 'Meja ${o.table}' : 'Bungkus'} • ${o.customerName}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              for (final l in o.lines) Text('${l.qty} × ${l.name}'),
              if (o.note.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Nota: ${o.note}',
                    style: const TextStyle(color: StegoColors.rocket, fontWeight: FontWeight.w700),
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(rm(o.total), style: const TextStyle(fontWeight: FontWeight.w900)),
                  const Spacer(),
                  if (o.status == OrderStatus.received)
                    TextButton(
                      onPressed: () => store.setOrderStatus(o.id, OrderStatus.cancelled),
                      child: const Text('Batal', style: TextStyle(color: StegoColors.rocket)),
                    ),
                  if (next != null)
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 42),
                        backgroundColor: StegoColors.jasmine,
                      ),
                      onPressed: () => store.setOrderStatus(o.id, next),
                      child: Text('→ ${next.label}'),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return ContentWidth(
      maxWidth: 900,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          SectionHeader('Barisan dapur (${open.length})'),
          if (open.isEmpty)
            const EmptyState(
              icon: Icons.soup_kitchen_rounded,
              title: 'Tiada pesanan aktif',
              message: 'Pesanan baharu akan muncul di sini.',
            )
          else
            ...open.map(card),
          if (done.isNotEmpty) ...[const SectionHeader('Terkini selesai'), ...done.map(card)],
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- menu

class _MenuAdmin extends StatelessWidget {
  const _MenuAdmin();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return Scaffold(
      backgroundColor: StegoColors.surface,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: StegoColors.jasmine,
        foregroundColor: Colors.white,
        onPressed: () => _editItem(context, store.newMenuItem(), isNew: true),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Item baharu'),
      ),
      body: ContentWidth(
        maxWidth: 900,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
          children: [
            const _LastCallAdmin(),
            for (final cat in menuCategories) ...[
              if (store.menu.any((m) => m.category == cat)) SectionHeader(cat),
              for (final m in store.menu.where((m) => m.category == cat))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: StegoCard(
                    padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                    onTap: () => _editItem(context, m),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                              Text(rm(m.price), style: const TextStyle(color: StegoColors.muted)),
                            ],
                          ),
                        ),
                        Text(
                          m.available ? 'Ada' : 'Habis',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: m.available ? StegoColors.mint : StegoColors.rocket,
                          ),
                        ),
                        Switch(
                          value: m.available,
                          onChanged: (v) => store.upsertMenuItem(m.copyWith(available: v)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _editItem(BuildContext context, MenuItem item, {bool isNew = false}) async {
    final store = context.read<AppStore>();
    final name = TextEditingController(text: item.name);
    final price = TextEditingController(text: isNew ? '' : item.price.toStringAsFixed(2));
    final desc = TextEditingController(text: item.description);
    var cat = item.category;
    final result = await showDialog<String>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text(isNew ? 'Item baharu' : 'Edit item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Nama'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                  decoration: const InputDecoration(labelText: 'Harga (RM)'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: cat,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: [for (final c in menuCategories) DropdownMenuItem(value: c, child: Text(c))],
                  onChanged: (v) => set(() => cat = v ?? cat),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: desc,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Keterangan'),
                ),
              ],
            ),
          ),
          actions: [
            if (!isNew)
              TextButton(
                onPressed: () => Navigator.pop(c, 'delete'),
                child: const Text('Padam', style: TextStyle(color: StegoColors.rocket)),
              ),
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Batal')),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
              onPressed: () => Navigator.pop(c, 'save'),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    if (result == 'delete') {
      await store.deleteMenuItem(item.id);
    } else if (result == 'save') {
      final p = double.tryParse(price.text);
      if (name.text.trim().isEmpty || p == null) {
        if (context.mounted) showSnack(context, 'Sila isi nama dan harga yang sah');
      } else {
        await store.upsertMenuItem(
          item.copyWith(name: name.text.trim(), price: p, category: cat, description: desc.text.trim()),
        );
      }
    }
    name.dispose();
    price.dispose();
    desc.dispose();
  }
}

// --------------------------------------------------------------- settings

class _SettingsAdmin extends StatefulWidget {
  const _SettingsAdmin();

  @override
  State<_SettingsAdmin> createState() => _SettingsAdminState();
}

class _SettingsAdminState extends State<_SettingsAdmin> {
  late Settings _s;
  late BusinessInfo _b;
  final _c = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    final store = context.read<AppStore>();
    _s = store.settings;
    _b = store.business;
    void add(String k, Object v) => _c[k] = TextEditingController(text: '$v');
    add('weekday', _s.weekdayPrice.toStringAsFixed(2));
    add('weekend', _s.weekendPrice.toStringAsFixed(2));
    add('holiday', _s.holidayPrice.toStringAsFixed(2));
    add('guardian', _s.guardianPrice.toStringAsFixed(2));
    add('groupChild', _s.groupChildPrice.toStringAsFixed(2));
    add('freeTeachers', _s.freeTeachers);
    add('extraTeacher', _s.extraTeacherPrice.toStringAsFixed(2));
    add('meal', _s.kidsMealPrice.toStringAsFixed(2));
    add('drink', _s.drinkPrice.toStringAsFixed(2));
    add('private', _s.privateSessionPrice.toStringAsFixed(2));
    add('groupMin', _s.groupMinimum);
    add('capacity', _s.slotCapacity);
    add('pin', _s.adminPin);
    add('phone', _b.phone);
    add('whatsapp', _b.whatsapp);
    add('hours', _b.openingHours);
    add('address', _b.address);
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  double _d(String k, double fallback) => double.tryParse(_c[k]!.text) ?? fallback;
  int _i(String k, int fallback) => int.tryParse(_c[k]!.text) ?? fallback;

  Future<void> _save() async {
    final store = context.read<AppStore>();
    final pin = _c['pin']!.text.trim();
    if (!store.isCloud && pin.length < 4) return showSnack(context, 'PIN mesti sekurang-kurangnya 4 digit');
    if (_s.lastCallEnd <= _s.lastCallStart) {
      return showSnack(context, 'Masa tamat Last Call mesti selepas masa mula');
    }
    try {
      await store.updateSettings(
        _s.copyWith(
          weekdayPrice: _d('weekday', _s.weekdayPrice),
          weekendPrice: _d('weekend', _s.weekendPrice),
          holidayPrice: _d('holiday', _s.holidayPrice),
          guardianPrice: _d('guardian', _s.guardianPrice),
          groupChildPrice: _d('groupChild', _s.groupChildPrice),
          freeTeachers: _i('freeTeachers', _s.freeTeachers),
          extraTeacherPrice: _d('extraTeacher', _s.extraTeacherPrice),
          kidsMealPrice: _d('meal', _s.kidsMealPrice),
          drinkPrice: _d('drink', _s.drinkPrice),
          privateSessionPrice: _d('private', _s.privateSessionPrice),
          groupMinimum: _i('groupMin', _s.groupMinimum),
          slotCapacity: _i('capacity', _s.slotCapacity),
          adminPin: pin,
        ),
      );
      await store.updateBusiness(
        _b.copyWith(
          phone: _c['phone']!.text.trim(),
          whatsapp: _c['whatsapp']!.text.replaceAll(RegExp(r'\D'), ''),
          openingHours: _c['hours']!.text.trim(),
          address: _c['address']!.text.trim(),
        ),
      );
    } catch (e) {
      if (mounted) showSnack(context, 'Gagal simpan: $e');
      return;
    }
    if (mounted) showSnack(context, 'Tetapan disimpan');
  }

  Widget _field(String key, String label, {bool money = true, bool number = true}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: _c[key],
      keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(labelText: label, prefixText: money ? 'RM ' : null),
    ),
  );

  Widget _pair(Widget a, Widget b) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: a),
      const SizedBox(width: 10),
      Expanded(child: b),
    ],
  );

  Future<void> _addHoliday() async {
    final store = context.read<AppStore>();
    final picked = await showDatePicker(
      context: context,
      firstDate: dateOnly(store.now),
      lastDate: dateOnly(store.now).add(const Duration(days: 730)),
      helpText: 'Pilih tarikh cuti',
    );
    if (picked == null) return;
    final k = dateKey(picked);
    if (_s.holidays.contains(k)) return;
    setState(() => _s = _s.copyWith(holidays: [..._s.holidays, k]..sort()));
    await store.updateSettings(store.settings.copyWith(holidays: _s.holidays));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<AppStore>();
    return ContentWidth(
      maxWidth: 760,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          const SectionHeader('Harga tiket'),
          _pair(_field('weekday', 'Hari biasa'), _field('weekend', 'Hujung minggu')),
          _pair(_field('holiday', 'Cuti umum'), _field('guardian', 'Penjaga')),
          const SectionHeader('Pakej sekolah / kumpulan'),
          _pair(_field('groupChild', 'Harga murid'), _field('groupMin', 'Minimum murid', money: false)),
          _pair(_field('freeTeachers', 'Guru percuma', money: false), _field('extraTeacher', 'Guru tambahan')),
          _pair(_field('meal', 'Kids Meal'), _field('drink', 'Iced Lemon Tea')),
          _field('private', 'Sesi privasi'),
          const SectionHeader('Operasi'),
          _field('capacity', 'Kapasiti kanak-kanak setiap slot', money: false),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _s.fridayPrayerBreak,
            title: const Text('Tutup slot waktu solat Jumaat', style: TextStyle(fontWeight: FontWeight.w700)),
            onChanged: (v) => setState(() => _s = _s.copyWith(fridayPrayerBreak: v)),
          ),
          const SizedBox(height: 6),
          const Text('Hari hujung minggu', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var wd = 1; wd <= 7; wd++)
                FilterChip(
                  label: Text(dayName(DateTime(2024, 1, wd))), // 1 Jan 2024 is a Monday
                  selected: _s.weekendDays.contains(wd),
                  onSelected: (on) => setState(() {
                    final days = {..._s.weekendDays};
                    on ? days.add(wd) : days.remove(wd);
                    _s = _s.copyWith(weekendDays: days.toList()..sort());
                  }),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text('Cuti umum & sekolah', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              TextButton.icon(onPressed: _addHoliday, icon: const Icon(Icons.add_rounded), label: const Text('Tambah')),
            ],
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final h in _s.holidays)
                InputChip(
                  label: Text(longDate(parseDateKey(h))),
                  onDeleted: () async {
                    setState(() => _s = _s.copyWith(holidays: _s.holidays.where((x) => x != h).toList()));
                    await store.updateSettings(store.settings.copyWith(holidays: _s.holidays));
                  },
                ),
            ],
          ),
          const SectionHeader('${LastCallCopy.title} (Jasmine Cafe)'),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _s.lastCallEnabled,
            title: const Text('Aktifkan jualan hujung hari', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Item diskaun hanya boleh dibeli dalam tempoh ini.'),
            onChanged: (v) => setState(() => _s = _s.copyWith(lastCallEnabled: v)),
          ),
          _pair(
            _TimeButton(
              label: 'Mula',
              minutes: _s.lastCallStart,
              onChanged: (m) => setState(() => _s = _s.copyWith(lastCallStart: m)),
            ),
            _TimeButton(
              label: 'Tamat',
              minutes: _s.lastCallEnd,
              onChanged: (m) => setState(() => _s = _s.copyWith(lastCallEnd: m)),
            ),
          ),
          const SectionHeader('Maklumat perniagaan'),
          _field('phone', 'No. telefon', money: false, number: false),
          _field('whatsapp', 'No. WhatsApp (cth: 60182351000)', money: false, number: false),
          _field('hours', 'Waktu operasi', money: false, number: false),
          _field('address', 'Alamat', money: false, number: false),
          if (!store.isCloud) ...[const SectionHeader('Keselamatan'), _field('pin', 'PIN staf', money: false)],
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Simpan Tetapan'),
          ),
          const SizedBox(height: 24),
          if (!store.isCloud)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: StegoColors.rocket),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Set semula semua data?'),
                    content: const Text('Semua tempahan, pesanan, menu dan tetapan pada peranti ini akan dipadam.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: StegoColors.rocket,
                          minimumSize: const Size(64, 44),
                        ),
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('Set semula'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await store.resetAll();
                  if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
                }
              },
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Set semula data peranti'),
            ),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({required this.label, required this.minutes, required this.onChanged});
  final String label;
  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () async {
        final t = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
        );
        if (t != null) onChanged(t.hour * 60 + t.minute);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: StegoColors.muted)),
          Text(timeLabel(minutes), style: const TextStyle(color: StegoColors.ink)),
        ],
      ),
    );
  }
}

/// Staff tool to mark today's leftover items down for Last Call.
class _LastCallAdmin extends StatelessWidget {
  const _LastCallAdmin();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final s = store.settings;
    final today = store.deals.where((d) => d.date == dateKey(store.now)).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: StegoCard(
        color: const Color(0xFF1B1A3A),
        borderColor: const Color(0xFF1B1A3A),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.nightlight_round, color: StegoColors.flame),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${LastCallCopy.title} hari ini',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                ),
                StatusPill(
                  !s.lastCallEnabled
                      ? 'Dimatikan'
                      : store.lastCallActive
                      ? 'Sedang berjalan'
                      : '${timeLabel(s.lastCallStart)} – ${timeLabel(s.lastCallEnd)}',
                  color: StegoColors.flame,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Tanda makanan lebihan dengan harga murah untuk dijual sebelum tutup. '
              'Tawaran tamat sendiri esok.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
            ),
            const SizedBox(height: 12),
            for (final d in today)
              if (store.menuItem(d.itemId) case final item?)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: ListTile(
                      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(
                        '${rm(item.price)} → ${rm(d.price)} (-${discountPercent(item.price, d.price)}%) • tinggal ${d.qtyLeft}',
                      ),
                      onTap: () => _editDeal(context, existing: d),
                      trailing: IconButton(
                        tooltip: 'Buang',
                        onPressed: () => store.removeDeal(d.id),
                        icon: const Icon(Icons.delete_outline_rounded, color: StegoColors.rocket),
                      ),
                    ),
                  ),
                ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: StegoColors.flame, foregroundColor: StegoColors.ink),
              onPressed: () => _editDeal(context),
              icon: const Icon(Icons.sell_rounded),
              label: const Text('Tambah item Last Call'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editDeal(BuildContext context, {LastCallDeal? existing}) async {
    final store = context.read<AppStore>();
    final items = store.menu.where((m) => m.available).toList();
    if (items.isEmpty) return showSnack(context, 'Tiada item menu tersedia');
    var item = existing == null ? items.first : (store.menuItem(existing.itemId) ?? items.first);
    final price = TextEditingController(text: (existing?.price ?? item.price * 0.5).toStringAsFixed(2));
    final qty = TextEditingController(text: '${existing?.qtyLeft ?? 5}');

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) {
          final p = double.tryParse(price.text);
          return AlertDialog(
            title: Text(existing == null ? 'Item Last Call' : 'Edit Last Call'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: item.id,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Item'),
                    items: [
                      for (final m in items)
                        DropdownMenuItem(
                          value: m.id,
                          child: Text('${m.name} • ${rm(m.price)}', overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: existing != null
                        ? null
                        : (id) => set(() {
                            item = items.firstWhere((m) => m.id == id);
                            price.text = (item.price * 0.5).toStringAsFixed(2);
                          }),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final pct in const [20, 30, 50, 70])
                        ActionChip(
                          label: Text('-$pct%'),
                          onPressed: () => set(() => price.text = (item.price * (100 - pct) / 100).toStringAsFixed(2)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: price,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                    onChanged: (_) => set(() {}),
                    decoration: InputDecoration(
                      labelText: 'Harga Last Call',
                      prefixText: 'RM ',
                      helperText: p == null
                          ? null
                          : 'Asal ${rm(item.price)} • diskaun ${discountPercent(item.price, p)}%',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: qty,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Kuantiti lebihan'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
    if (ok == true) {
      final p = double.tryParse(price.text);
      final q = int.tryParse(qty.text);
      if (p == null || q == null || q <= 0 || p <= 0) {
        if (context.mounted) showSnack(context, 'Sila isi harga dan kuantiti yang sah');
      } else if (p >= item.price) {
        if (context.mounted) showSnack(context, 'Harga Last Call mesti lebih rendah dari harga asal');
      } else {
        await store.upsertDeal(itemId: item.id, price: p, qty: q);
      }
    }
    price.dispose();
    qty.dispose();
  }
}
