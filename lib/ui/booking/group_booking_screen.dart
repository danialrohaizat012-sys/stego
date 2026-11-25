import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../widgets/common.dart';
import 'pickers.dart';
import 'ticket_screen.dart';

/// Group / school visit booking — designed for teachers booking for a whole
/// class at once. Creates a *pending* request that staff confirm.
class GroupBookingScreen extends StatefulWidget {
  const GroupBookingScreen({super.key});

  @override
  State<GroupBookingScreen> createState() => _GroupBookingScreenState();
}

class _GroupBookingScreenState extends State<GroupBookingScreen> {
  static const _types = ['Tadika', 'Taska', 'Sekolah Rendah', 'Lain-lain'];

  final _form = GlobalKey<FormState>();
  final _institution = TextEditingController();
  final _pic = TextEditingController();
  late final TextEditingController _phone;
  final _notes = TextEditingController();

  String _type = _types.first;
  late DateTime _date;
  String? _slotId;
  late int _students;
  int _teachers = 3;
  bool _mealsForAll = true;
  int _meals = 0;
  bool _drinksForAll = true;
  int _drinks = 0;
  bool _private = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final store = context.read<AppStore>();
    _students = store.settings.groupMinimum < 30 ? 30 : store.settings.groupMinimum;
    // Groups usually book ahead — default to the next weekday with slots.
    _date = dateOnly(store.now).add(const Duration(days: 1));
    for (var i = 0; i < 14 && (store.slotsFor(_date).isEmpty || store.dayType(_date) != DayType.weekday); i++) {
      _date = _date.add(const Duration(days: 1));
    }
    _phone = TextEditingController(text: store.member?.phone ?? '');
    _pic.text = store.member?.name ?? '';
  }

  @override
  void dispose() {
    _institution.dispose();
    _pic.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  int get _mealQty => _mealsForAll ? _students : _meals;
  int get _drinkQty => _drinksForAll ? _students : _drinks;

  Future<void> _submit() async {
    final store = context.read<AppStore>();
    if (!_form.currentState!.validate()) {
      return showSnack(context, 'Sila lengkapkan maklumat institusi');
    }
    if (_slotId == null) return showSnack(context, 'Sila pilih slot masa');
    if (_students < store.settings.groupMinimum) {
      return showSnack(context, 'Minimum ${store.settings.groupMinimum} murid untuk pakej kumpulan');
    }
    setState(() => _busy = true);
    try {
      final b = await store.createGroupBooking(
        date: _date,
        slotId: _slotId!,
        children: _students,
        picName: _pic.text,
        phone: _phone.text,
        group: GroupDetails(
          institution: _institution.text.trim(),
          institutionType: _type,
          teachers: _teachers,
          meals: _mealQty,
          drinks: _drinkQty,
          privateSession: _private,
          notes: _notes.text.trim(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => TicketScreen(bookingId: b.id, justCreated: true)));
    } catch (e) {
      if (mounted) showSnack(context, errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final s = store.settings;
    final q = store.groupQuote(
      children: _students,
      teachers: _teachers,
      meals: _mealQty,
      drinks: _drinkQty,
      privateSession: _private,
    );
    if (_slotId != null) {
      final booked = store.bookedChildren(_date, _slotId!);
      if (store.remaining(_date, _slotId!) < _students || (_private && booked > 0)) _slotId = null;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Lawatan Sekolah & Kumpulan')),
      bottomNavigationBar: TotalBar(
        label: 'Anggaran jumlah',
        total: q.total,
        action: 'Hantar Permohonan',
        busy: _busy,
        onPressed: _submit,
      ),
      body: Form(
        key: _form,
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              _PackageBanner(settings: s),
              StepTitle(1, 'Maklumat institusi'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in _types)
                    ChoiceChip(label: Text(t), selected: _type == t, onSelected: (_) => setState(() => _type = t)),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _institution,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama tadika / sekolah',
                  hintText: 'cth: Tadika Ceria Pasir Tumboh',
                  prefixIcon: Icon(Icons.apartment_rounded),
                ),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Sila isi nama institusi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pic,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama guru bertanggungjawab',
                  prefixIcon: Icon(Icons.person_pin_rounded),
                ),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Sila isi nama guru' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'No. telefon / WhatsApp',
                  prefixIcon: Icon(Icons.phone_rounded),
                ),
                validator: (v) => (v ?? '').replaceAll(RegExp(r'\D'), '').length < 9 ? 'No. telefon tidak sah' : null,
              ),
              StepTitle(2, 'Bilangan peserta'),
              StegoCard(
                child: Column(
                  children: [
                    CountField(
                      label: 'Murid',
                      helper: '${rm(s.groupChildPrice)} seorang • min ${s.groupMinimum}',
                      icon: Icons.groups_rounded,
                      value: _students,
                      min: 1,
                      max: s.slotCapacity,
                      onChanged: (v) => setState(() => _students = v),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                    CountField(
                      label: 'Guru / pengiring',
                      helper: '${s.freeTeachers} pertama percuma, seterusnya ${rm(s.extraTeacherPrice)}',
                      icon: Icons.co_present_rounded,
                      value: _teachers,
                      max: 50,
                      onChanged: (v) => setState(() => _teachers = v),
                    ),
                  ],
                ),
              ),
              StepTitle(3, 'Tarikh & slot'),
              DateStrip(
                selected: _date,
                onSelected: (d) => setState(() {
                  _date = d;
                  _slotId = null;
                }),
              ),
              const SizedBox(height: 10),
              const DayTypeLegend(),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _private,
                onChanged: (v) => setState(() {
                  _private = v;
                  _slotId = null;
                }),
                title: Text(
                  'Sesi privasi (+${rm(s.privateSessionPrice)})',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: const Text('Seluruh taman permainan untuk kumpulan anda sahaja.'),
              ),
              const SizedBox(height: 4),
              SlotPicker(
                date: _date,
                selectedId: _slotId,
                needed: _students,
                requireEmpty: _private,
                onSelected: (id) => setState(() => _slotId = id),
              ),
              StepTitle(4, 'Makanan dari Jasmine Cafe'),
              StegoCard(
                child: Column(
                  children: [
                    _MealToggle(
                      title: 'Kids Meal',
                      subtitle: 'Lemon chicken & nasi mentega • ${rm(s.kidsMealPrice)}',
                      icon: Icons.lunch_dining_rounded,
                      forAll: _mealsForAll,
                      qty: _meals,
                      students: _students,
                      onForAll: (v) => setState(() {
                        _mealsForAll = v;
                        if (!v) _meals = _students;
                      }),
                      onQty: (v) => setState(() => _meals = v),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider()),
                    _MealToggle(
                      title: 'Iced Lemon Tea',
                      subtitle: rm(s.drinkPrice),
                      icon: Icons.local_drink_rounded,
                      forAll: _drinksForAll,
                      qty: _drinks,
                      students: _students,
                      onForAll: (v) => setState(() {
                        _drinksForAll = v;
                        if (!v) _drinks = _students;
                      }),
                      onQty: (v) => setState(() => _drinks = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Catatan (pilihan)',
                  hintText: 'Alahan makanan, keperluan khas, masa ketibaan bas…',
                  alignLabelWithHint: true,
                ),
              ),
              StepTitle(5, 'Sebut harga'),
              StegoCard(
                child: Column(
                  children: [
                    LineRow('Murid × ${q.children}', rm(q.childTotal)),
                    LineRow('Guru × $_teachers (${q.chargeableTeachers} dikenakan caj)', rm(q.teacherTotal)),
                    if (_mealQty > 0) LineRow('Kids Meal × $_mealQty', rm(q.mealTotal)),
                    if (_drinkQty > 0) LineRow('Iced Lemon Tea × $_drinkQty', rm(q.drinkTotal)),
                    if (_private) LineRow('Sesi privasi', rm(q.privateTotal)),
                    const Divider(height: 20),
                    LineRow('Anggaran jumlah', rm(q.total), bold: true),
                    const SizedBox(height: 6),
                    const Text(
                      'Permohonan akan disemak oleh pihak Stegoland. Anda akan dihubungi melalui '
                      'WhatsApp untuk pengesahan dan bayaran.',
                      style: TextStyle(color: StegoColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackageBanner extends StatelessWidget {
  const _PackageBanner({required this.settings});
  final Settings settings;

  @override
  Widget build(BuildContext context) {
    final s = settings;
    Widget fact(IconData i, String t) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(i, color: StegoColors.flame, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              t,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    return SpaceBackground(
      radius: 24,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pakej Lawatan Sekolah',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  fact(Icons.child_care_rounded, '${rm(s.groupChildPrice)} seorang murid'),
                  fact(Icons.co_present_rounded, '${s.freeTeachers} guru percuma'),
                  fact(Icons.lunch_dining_rounded, 'Kids Meal ${rm(s.kidsMealPrice)}'),
                  fact(Icons.lock_rounded, 'Sesi privasi +${rm(s.privateSessionPrice)}'),
                ],
              ),
            ),
            const FloatingMascot(width: 92),
          ],
        ),
      ),
    );
  }
}

class _MealToggle extends StatelessWidget {
  const _MealToggle({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.forAll,
    required this.qty,
    required this.students,
    required this.onForAll,
    required this.onQty,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool forAll;
  final int qty;
  final int students;
  final ValueChanged<bool> onForAll;
  final ValueChanged<int> onQty;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconBadge(icon, size: 42, color: StegoColors.jasmine),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  Text(subtitle, style: const TextStyle(color: StegoColors.muted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: true, label: Text('Semua murid ($students)')),
            const ButtonSegment(value: false, label: Text('Pilih jumlah')),
          ],
          selected: {forAll},
          onSelectionChanged: (s) => onForAll(s.first),
        ),
        if (!forAll) ...[
          const SizedBox(height: 10),
          CountField(label: 'Kuantiti', value: qty, max: 500, onChanged: onQty),
        ],
      ],
    );
  }
}
