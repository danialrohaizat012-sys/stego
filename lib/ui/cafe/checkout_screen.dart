import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../booking/pickers.dart';
import '../widgets/common.dart';
import 'order_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  OrderMode _mode = OrderMode.dineIn;
  final _table = TextEditingController();
  late final _name = TextEditingController(text: context.read<AppStore>().member?.name ?? '');
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _table.dispose();
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _place() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final store = context.read<AppStore>();
    try {
      final o = await store.placeOrder(mode: _mode, table: _table.text, name: _name.text, note: _note.text);
      if (!mounted) return;
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => OrderScreen(orderId: o.id, justPlaced: true)));
    } on StateError catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Troli Anda'),
        actions: [
          if (store.cart.isNotEmpty)
            TextButton(
              onPressed: () async {
                await store.clearCart();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Kosongkan'),
            ),
        ],
      ),
      bottomNavigationBar: store.cart.isEmpty
          ? null
          : TotalBar(
              label: 'Jumlah • bayar di kaunter',
              total: store.cartTotal,
              action: 'Hantar Pesanan',
              busy: _busy,
              onPressed: _place,
            ),
      body: store.cart.isEmpty
          ? const EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Troli kosong',
              message: 'Pilih makanan kegemaran dari menu Jasmine Cafe.',
            )
          : Form(
              key: _form,
              child: ContentWidth(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  children: [
                    StegoCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        children: [
                          for (final l in store.cart)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(l.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                                        Text(
                                          rm(l.price),
                                          style: const TextStyle(color: StegoColors.muted, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  QtyStepper(
                                    compact: true,
                                    value: l.qty,
                                    onChanged: (v) => store.changeCartLine(l.itemId, v - l.qty),
                                  ),
                                  SizedBox(
                                    width: 74,
                                    child: Text(
                                      rm(l.subtotal),
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const StepTitle(1, 'Cara hidangan'),
                    SegmentedButton<OrderMode>(
                      segments: const [
                        ButtonSegment(
                          value: OrderMode.dineIn,
                          label: Text('Makan di sini'),
                          icon: Icon(Icons.table_restaurant_rounded),
                        ),
                        ButtonSegment(
                          value: OrderMode.takeaway,
                          label: Text('Bungkus'),
                          icon: Icon(Icons.takeout_dining_rounded),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (s) => setState(() => _mode = s.first),
                    ),
                    const SizedBox(height: 14),
                    if (_mode == OrderMode.dineIn) ...[
                      TextFormField(
                        controller: _table,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'No. meja', prefixIcon: Icon(Icons.tag_rounded)),
                        validator: (v) => (v ?? '').trim().isEmpty ? 'Sila isi no. meja' : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nama untuk dipanggil',
                        prefixIcon: Icon(Icons.person_rounded),
                      ),
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Sila isi nama' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _note,
                      decoration: const InputDecoration(
                        labelText: 'Nota untuk dapur (pilihan)',
                        hintText: 'cth: kurang pedas, tanpa ais',
                        prefixIcon: Icon(Icons.sticky_note_2_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
