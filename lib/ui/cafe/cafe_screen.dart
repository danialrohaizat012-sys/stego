import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/seed.dart';
import '../../data/store.dart';
import '../widgets/common.dart';
import 'checkout_screen.dart';
import 'last_call.dart';
import 'order_screen.dart';

IconData categoryIcon(String c) => switch (c) {
  'Sarapan' => Icons.free_breakfast_rounded,
  'Ayam Goreng' => Icons.set_meal_rounded,
  'Combo' => Icons.lunch_dining_rounded,
  'Snek' => Icons.bakery_dining_rounded,
  'Kanak-kanak' => Icons.child_care_rounded,
  'Minuman' => Icons.local_drink_rounded,
  _ => Icons.restaurant_rounded,
};

class CafeScreen extends StatefulWidget {
  const CafeScreen({super.key});

  @override
  State<CafeScreen> createState() => _CafeScreenState();
}

class _CafeScreenState extends State<CafeScreen> {
  String _cat = 'Semua';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final cats = ['Semua', ...menuCategories.where((c) => store.menu.any((m) => m.category == c))];
    final items = _cat == 'Semua' ? store.menu : store.menu.where((m) => m.category == _cat).toList();
    final active = store.orders
        .where((o) => o.status != OrderStatus.completed && o.status != OrderStatus.cancelled)
        .toList();

    return Scaffold(
      backgroundColor: StegoColors.surface,
      body: SafeArea(
        bottom: false,
        child: ContentWidth(
          maxWidth: 720,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _CafeHeader(cafeName: store.business.cafeName),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(child: LastCallSection()),
              ),
              if (active.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  sliver: SliverList.separated(
                    itemCount: active.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _ActiveOrderTile(order: active[i]),
                  ),
                ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _ChipsHeader(cats: cats, selected: _cat, onSelected: (c) => setState(() => _cat = c)),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                sliver: SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _MenuTile(item: items[i]),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: store.cartCount == 0
          ? null
          : ContentWidth(
              maxWidth: 680,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: StegoColors.jasmine,
                    minimumSize: const Size.fromHeight(58),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  onPressed: () =>
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CheckoutScreen())),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text('${store.cartCount}'),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('Lihat troli')),
                      Text(rm(store.cartTotal)),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _CafeHeader extends StatelessWidget {
  const _CafeHeader({required this.cafeName});
  final String cafeName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [StegoColors.jasmine, Color(0xFF3E9C72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cafeName, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white)),
                const Text(
                  'by Stegoland',
                  style: TextStyle(color: StegoColors.flame, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pesan dari meja anda, kami hantar bila siap. Ibu bapa boleh rehat sambil anak bermain!',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
            child: const Icon(Icons.local_florist_rounded, color: Colors.white, size: 34),
          ),
        ],
      ),
    );
  }
}

class _ChipsHeader extends SliverPersistentHeaderDelegate {
  _ChipsHeader({required this.cats, required this.selected, required this.onSelected});
  final List<String> cats;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  double get minExtent => 64;
  @override
  double get maxExtent => 64;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: StegoColors.surface,
      alignment: Alignment.centerLeft,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: cats.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) => ChoiceChip(
          label: Text(cats[i]),
          selected: cats[i] == selected,
          selectedColor: StegoColors.jasmineTint,
          showCheckmark: false,
          onSelected: (_) => onSelected(cats[i]),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ChipsHeader old) => old.selected != selected || old.cats.length != cats.length;
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.item});
  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final qty = store.qtyInCart(item.id);
    return Opacity(
      opacity: item.available ? 1 : 0.5,
      child: StegoCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: StegoColors.jasmineTint, borderRadius: BorderRadius.circular(18)),
              child: Icon(categoryIcon(item.category), color: StegoColors.jasmine, size: 32),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  if (item.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: StegoColors.muted, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    item.available ? rm(item.price) : 'Habis dijual',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: item.available ? StegoColors.jasmine : StegoColors.rocket,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!item.available)
              const SizedBox.shrink()
            else if (qty == 0)
              IconButton.filled(
                tooltip: 'Tambah ${item.name}',
                style: IconButton.styleFrom(backgroundColor: StegoColors.jasmine),
                onPressed: () => store.addToCart(item),
                icon: const Icon(Icons.add_rounded),
              )
            else
              QtyStepper(compact: true, value: qty, onChanged: (v) => store.addToCart(item, v - qty)),
          ],
        ),
      ),
    );
  }
}

class _ActiveOrderTile extends StatelessWidget {
  const _ActiveOrderTile({required this.order});
  final CafeOrder order;

  @override
  Widget build(BuildContext context) {
    return StegoCard(
      color: StegoColors.flame.withValues(alpha: 0.2),
      borderColor: StegoColors.flame,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderScreen(orderId: order.id))),
      child: Row(
        children: [
          const Icon(Icons.room_service_rounded, color: StegoColors.ink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pesanan ${order.id}', style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(order.status.label, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
