import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../booking/family_booking_screen.dart';
import '../booking/ticket_screen.dart';
import '../cafe/order_screen.dart';
import '../widgets/common.dart';

class MyTicketsScreen extends StatelessWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final today = dateKey(store.now);
    final upcoming =
        store.myBookings
            .where((b) => b.status.isActive && b.status != BookingStatus.checkedIn && b.date.compareTo(today) >= 0)
            .toList()
          ..sort((a, b) => '${a.date}${a.slotId}'.compareTo('${b.date}${b.slotId}'));
    final past = store.myBookings.where((b) => !upcoming.contains(b)).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tiket & Pesanan'),
          bottom: const TabBar(
            labelStyle: TextStyle(fontWeight: FontWeight.w800, fontFamily: StegoTheme.body),
            tabs: [
              Tab(text: 'Tiket'),
              Tab(text: 'Pesanan Kafe'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BookingList(upcoming: upcoming, past: past),
            _OrderList(orders: store.orders),
          ],
        ),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  const _BookingList({required this.upcoming, required this.past});
  final List<Booking> upcoming;
  final List<Booking> past;

  @override
  Widget build(BuildContext context) {
    if (upcoming.isEmpty && past.isEmpty) {
      return EmptyState(
        icon: Icons.confirmation_number_outlined,
        title: 'Belum ada tiket',
        message: 'Tempah slot bermain dan tiket anda akan muncul di sini.',
        action: FilledButton.icon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FamilyBookingScreen())),
          icon: const Icon(Icons.rocket_launch_rounded),
          label: const Text('Tempah Sekarang'),
        ),
      );
    }
    return ContentWidth(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          if (upcoming.isNotEmpty) ...[
            const SectionHeader('Akan datang'),
            for (final b in upcoming)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: BookingTile(booking: b),
              ),
          ],
          if (past.isNotEmpty) ...[
            const SectionHeader('Sejarah'),
            for (final b in past)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: BookingTile(booking: b),
              ),
          ],
        ],
      ),
    );
  }
}

class BookingTile extends StatelessWidget {
  const BookingTile({super.key, required this.booking, this.onTap, this.trailing});
  final Booking booking;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final store = context.read<AppStore>();
    final b = booking;
    final d = parseDateKey(b.date);
    final isGroup = b.kind == BookingKind.group;
    return StegoCard(
      padding: const EdgeInsets.all(14),
      onTap:
          onTap ?? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TicketScreen(bookingId: b.id))),
      child: Row(
        children: [
          Container(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isGroup ? StegoColors.rocket.withValues(alpha: 0.1) : StegoColors.skyTint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  dayShort(d),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: StegoColors.muted),
                ),
                Text(
                  '${d.day}',
                  style: const TextStyle(fontFamily: StegoTheme.display, fontSize: 22, fontWeight: FontWeight.w700),
                ),
                Text(monthShort(d), style: const TextStyle(fontSize: 11, color: StegoColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isGroup ? b.group!.institution : '${b.children} kanak-kanak • ${b.guardians} penjaga',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  isGroup ? '${b.children} murid • ${store.slotLabel(b.slotId)}' : store.slotLabel(b.slotId),
                  style: const TextStyle(color: StegoColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    StatusPill(b.status.label, color: bookingStatusColor(b.status)),
                    if (b.paid) const StatusPill('Dibayar', color: StegoColors.mint, icon: Icons.check_rounded),
                  ],
                ),
              ],
            ),
          ),
          trailing ?? Text(rm(b.total), style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({required this.orders});
  final List<CafeOrder> orders;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Belum ada pesanan',
        message: 'Pesanan Jasmine Cafe anda akan muncul di sini.',
      );
    }
    return ContentWidth(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        itemCount: orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final o = orders[i];
          return StegoCard(
            padding: const EdgeInsets.all(14),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderScreen(orderId: o.id))),
            child: Row(
              children: [
                const IconBadge(Icons.receipt_long_rounded, color: StegoColors.jasmine),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.id, style: const TextStyle(fontWeight: FontWeight.w900)),
                      Text(
                        '${o.itemCount} item • ${shortDate(o.createdAt)}, ${hhmm(o.createdAt)}',
                        style: const TextStyle(color: StegoColors.muted, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      StatusPill(o.status.label, color: orderStatusColor(o.status)),
                    ],
                  ),
                ),
                Text(rm(o.total), style: const TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
          );
        },
      ),
    );
  }
}

Color orderStatusColor(OrderStatus s) => switch (s) {
  OrderStatus.received => StegoColors.navySoft,
  OrderStatus.preparing => const Color(0xFFB7791F),
  OrderStatus.ready => StegoColors.jasmine,
  OrderStatus.completed => StegoColors.muted,
  OrderStatus.cancelled => StegoColors.rocket,
};
