import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../widgets/common.dart';

class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key, required this.orderId, this.justPlaced = false});
  final String orderId;
  final bool justPlaced;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final o = store.orders.where((x) => x.id == orderId).firstOrNull;
    if (o == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(icon: Icons.search_off_rounded, title: 'Pesanan tidak dijumpai', message: ''),
      );
    }
    const steps = [OrderStatus.received, OrderStatus.preparing, OrderStatus.ready, OrderStatus.completed];
    final current = steps.indexOf(o.status);

    return Scaffold(
      appBar: AppBar(title: Text('Pesanan ${o.id}')),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            if (justPlaced) ...[
              const Icon(Icons.check_circle_rounded, color: StegoColors.jasmine, size: 56),
              const SizedBox(height: 8),
              Text('Pesanan diterima!', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                o.mode == OrderMode.dineIn
                    ? 'Kami akan hantar ke meja ${o.table} bila siap.'
                    : 'Kami akan panggil nama "${o.customerName}" bila siap.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: StegoColors.muted),
              ),
              const SizedBox(height: 20),
            ],
            StegoCard(
              child: o.status == OrderStatus.cancelled
                  ? const Row(
                      children: [
                        Icon(Icons.cancel_rounded, color: StegoColors.rocket),
                        SizedBox(width: 10),
                        Text('Pesanan dibatalkan', style: TextStyle(fontWeight: FontWeight.w800)),
                      ],
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < steps.length; i++)
                          _StepRow(
                            label: steps[i].label,
                            done: i <= current,
                            active: i == current,
                            last: i == steps.length - 1,
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 14),
            StegoCard(
              child: Column(
                children: [
                  for (final l in o.lines) LineRow('${l.qty} × ${l.name}', rm(l.subtotal)),
                  const Divider(height: 20),
                  LineRow('Jumlah', rm(o.total), bold: true),
                  LineRow(
                    o.mode == OrderMode.dineIn ? 'Makan di sini • Meja ${o.table}' : 'Bungkus',
                    '${hhmm(o.createdAt)} • ${shortDate(o.createdAt)}',
                    muted: true,
                  ),
                  if (o.note.isNotEmpty) LineRow('Nota', o.note, muted: true),
                  const LineRow('Bayaran', 'Di kaunter', muted: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.done, required this.active, required this.last});
  final String label;
  final bool done;
  final bool active;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final color = done ? StegoColors.jasmine : StegoColors.line;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: done ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
              ),
              if (!last) Expanded(child: Container(width: 3, color: color)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 3, bottom: last ? 0 : 18),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                  color: done ? StegoColors.ink : StegoColors.muted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
