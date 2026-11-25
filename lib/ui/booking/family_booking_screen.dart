import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../widgets/common.dart';
import 'pickers.dart';
import 'ticket_screen.dart';

class FamilyBookingScreen extends StatefulWidget {
  const FamilyBookingScreen({super.key});

  @override
  State<FamilyBookingScreen> createState() => _FamilyBookingScreenState();
}

class _FamilyBookingScreenState extends State<FamilyBookingScreen> {
  final _form = GlobalKey<FormState>();
  late DateTime _date;
  String? _slotId;
  int _kids = 1;
  int _guardians = 1;
  late final TextEditingController _name;
  late final TextEditingController _phone;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final store = context.read<AppStore>();
    _date = dateOnly(store.now);
    // Skip to the next open day if today is fully closed.
    for (var i = 0; i < 14 && store.slotsFor(_date).isEmpty; i++) {
      _date = _date.add(const Duration(days: 1));
    }
    _name = TextEditingController(text: store.member?.name ?? '');
    _phone = TextEditingController(text: store.member?.phone ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final store = context.read<AppStore>();
    if (_slotId == null) return showSnack(context, 'Sila pilih slot masa');
    if (!_form.currentState!.validate()) return;
    final err = store.validate(date: _date, slotId: _slotId!, children: _kids);
    if (err != null) return showSnack(context, err);

    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => _ConfirmSheet(
        date: _date,
        slot: store.slotLabel(_slotId!),
        kids: _kids,
        guardians: _guardians,
        childPrice: store.childPrice(_date),
        guardianPrice: store.settings.guardianPrice,
        total: store.familyTotal(_date, _kids, _guardians),
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final b = await store.createFamilyBooking(
        date: _date,
        slotId: _slotId!,
        children: _kids,
        guardians: _guardians,
        name: _name.text,
        phone: _phone.text,
      );
      if (!mounted) return;
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => TicketScreen(bookingId: b.id, justCreated: true)));
    } on StateError catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final s = store.settings;
    final price = store.childPrice(_date);
    // Clear selection if it became unavailable (e.g. capacity changed).
    if (_slotId != null && store.remaining(_date, _slotId!) < _kids) _slotId = null;

    return Scaffold(
      appBar: AppBar(title: const Text('Tempah Tiket Keluarga')),
      bottomNavigationBar: TotalBar(
        label: 'Jumlah • bayar di kaunter',
        total: store.familyTotal(_date, _kids, _guardians),
        action: 'Teruskan',
        busy: _busy,
        onPressed: _submit,
      ),
      body: Form(
        key: _form,
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              StepTitle(
                1,
                'Pilih tarikh',
                trailing: Text(shortDate(_date), style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
              DateStrip(
                selected: _date,
                onSelected: (d) => setState(() {
                  _date = d;
                  _slotId = null;
                }),
              ),
              const SizedBox(height: 10),
              const DayTypeLegend(),
              StepTitle(2, 'Pilih slot masa'),
              SlotPicker(
                date: _date,
                selectedId: _slotId,
                needed: _kids,
                onSelected: (id) => setState(() => _slotId = id),
              ),
              StepTitle(3, 'Bilangan pengunjung'),
              StegoCard(
                child: Column(
                  children: [
                    CountField(
                      label: 'Kanak-kanak',
                      helper: '${rm(price)} seorang • ${store.dayType(_date).label}',
                      icon: Icons.child_care_rounded,
                      value: _kids,
                      min: 1,
                      max: s.slotCapacity,
                      onChanged: (v) => setState(() => _kids = v),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                    CountField(
                      label: 'Penjaga dewasa',
                      helper: '${rm(s.guardianPrice)} seorang',
                      icon: Icons.person_rounded,
                      value: _guardians,
                      max: 20,
                      onChanged: (v) => setState(() => _guardians = v),
                    ),
                  ],
                ),
              ),
              StepTitle(4, 'Maklumat hubungan'),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nama', prefixIcon: Icon(Icons.badge_rounded)),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Sila isi nama' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'No. telefon', prefixIcon: Icon(Icons.phone_rounded)),
                validator: (v) => (v ?? '').replaceAll(RegExp(r'\D'), '').length < 9 ? 'No. telefon tidak sah' : null,
              ),
              const SizedBox(height: 16),
              const _PayNote(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayNote extends StatelessWidget {
  const _PayNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StegoColors.flame.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.payments_rounded, color: StegoColors.ink),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tempat anda dikunci serta-merta. Bayaran dibuat di kaunter semasa daftar masuk '
              '(tunai, kad atau DuitNow QR).',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.date,
    required this.slot,
    required this.kids,
    required this.guardians,
    required this.childPrice,
    required this.guardianPrice,
    required this.total,
  });

  final DateTime date;
  final String slot;
  final int kids;
  final int guardians;
  final double childPrice;
  final double guardianPrice;
  final double total;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Semak tempahan', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            LineRow('Tarikh', longDate(date)),
            LineRow('Slot', slot),
            const Divider(height: 20),
            LineRow('Kanak-kanak × $kids', rm(childPrice * kids)),
            if (guardians > 0) LineRow('Penjaga × $guardians', rm(guardianPrice * guardians)),
            const Divider(height: 20),
            LineRow('Jumlah', rm(total), bold: true),
            const SizedBox(height: 18),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sahkan Tempahan')),
            const SizedBox(height: 6),
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Ubah')),
          ],
        ),
      ),
    );
  }
}
