import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../widgets/common.dart';

/// Branding for the end-of-day markdown. Change here to rename the feature.
abstract final class LastCallCopy {
  static const title = 'Last Call';
  static const subtitle = 'Jualan hujung hari • harga jatuh, rasa sama sedap';
}

String durationLabel(int minutes) {
  final h = minutes ~/ 60, m = minutes % 60;
  if (h == 0) return '$m min';
  return m == 0 ? '$h jam' : '$h jam $m min';
}

int discountPercent(double original, double price) =>
    original <= 0 ? 0 : (((original - price) / original) * 100).round();

/// Rebuilds its child every 30 seconds so the Last Call window and countdown
/// stay accurate while the screen is open.
class MinuteTicker extends StatefulWidget {
  const MinuteTicker({super.key, required this.builder});
  final WidgetBuilder builder;

  @override
  State<MinuteTicker> createState() => _MinuteTickerState();
}

class _MinuteTickerState extends State<MinuteTicker> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

/// Cafe section listing today's Last Call deals (or a teaser before the
/// window opens). Renders nothing when there are no deals.
class LastCallSection extends StatelessWidget {
  const LastCallSection({super.key});

  @override
  Widget build(BuildContext context) {
    return MinuteTicker(
      builder: (context) {
        final store = context.watch<AppStore>();
        final active = store.activeDeals;
        if (active.isEmpty && !store.lastCallUpcoming) return const SizedBox.shrink();
        final s = store.settings;
        final deals = (active.isNotEmpty ? active : store.todaysDeals)
            .where((d) => store.menuItem(d.itemId) != null)
            .toList();
        if (deals.isEmpty) return const SizedBox.shrink();
        final isLive = active.isNotEmpty;

        return Container(
          margin: const EdgeInsets.only(top: 14),
          padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
          decoration: BoxDecoration(color: const Color(0xFF1B1A3A), borderRadius: BorderRadius.circular(26)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    const Icon(Icons.nightlight_round, color: StegoColors.flame),
                    const SizedBox(width: 8),
                    Text(
                      LastCallCopy.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    const Spacer(),
                    StatusPill(
                      isLive
                          ? 'Tamat dalam ${durationLabel(store.lastCallMinutesLeft)}'
                          : 'Mula ${timeLabel(s.lastCallStart)}',
                      color: StegoColors.flame,
                      icon: Icons.timer_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  isLive
                      ? LastCallCopy.subtitle
                      : 'Intai dulu! Tawaran ini dibuka pada ${timeLabel(s.lastCallStart)} – ${timeLabel(s.lastCallEnd)}.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 206,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(right: 16),
                  itemCount: deals.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) => _DealCard(deal: deals[i], live: isLive),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DealCard extends StatelessWidget {
  const _DealCard({required this.deal, required this.live});
  final LastCallDeal deal;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final item = store.menuItem(deal.itemId)!;
    final qty = store.qtyInCart(deal.cartId);
    final pct = discountPercent(item.price, deal.price);

    return SizedBox(
      width: 168,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900, height: 1.2),
                    ),
                  ),
                  if (pct > 0) _Sticker(percent: pct),
                ],
              ),
              const Spacer(),
              Text(
                rm(item.price),
                style: const TextStyle(color: StegoColors.muted, decoration: TextDecoration.lineThrough, fontSize: 12),
              ),
              Text(
                rm(deal.price),
                style: const TextStyle(
                  fontFamily: StegoTheme.display,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: StegoColors.rocket,
                ),
              ),
              Text(
                'Tinggal ${deal.qtyLeft}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: deal.qtyLeft <= 3 ? StegoColors.rocket : StegoColors.muted,
                ),
              ),
              const SizedBox(height: 8),
              if (!live)
                const SizedBox(
                  height: 36,
                  child: Center(
                    child: Text(
                      'Belum dibuka',
                      style: TextStyle(color: StegoColors.muted, fontWeight: FontWeight.w700),
                    ),
                  ),
                )
              else if (qty == 0)
                SizedBox(
                  height: 36,
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      backgroundColor: StegoColors.flame,
                      foregroundColor: StegoColors.ink,
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () => store.addDealToCart(deal),
                    child: const Text('Rebut'),
                  ),
                )
              else
                Center(
                  child: _MiniStepper(
                    value: qty,
                    max: deal.qtyLeft,
                    onChanged: (v) => store.addDealToCart(deal, v - qty),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStepper extends StatelessWidget {
  const _MiniStepper({required this.value, required this.max, required this.onChanged});
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget b(IconData i, VoidCallback? f) => SizedBox(
      width: 36,
      height: 36,
      child: IconButton.filledTonal(
        padding: EdgeInsets.zero,
        iconSize: 18,
        style: IconButton.styleFrom(backgroundColor: StegoColors.skyTint, foregroundColor: StegoColors.navy),
        onPressed: f,
        icon: Icon(i),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        b(Icons.remove_rounded, () => onChanged(value - 1)),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        b(Icons.add_rounded, value < max ? () => onChanged(value + 1) : null),
      ],
    );
  }
}

/// Round yellow markdown sticker, e.g. "-40%".
class _Sticker extends StatelessWidget {
  const _Sticker({required this.percent});
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.2,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: StegoColors.flame, shape: BoxShape.circle),
        child: Text(
          '-$percent%',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: StegoColors.ink),
        ),
      ),
    );
  }
}

/// Small home-screen banner shown while Last Call is live.
class LastCallBanner extends StatelessWidget {
  const LastCallBanner({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MinuteTicker(
      builder: (context) {
        final store = context.watch<AppStore>();
        final deals = store.activeDeals.where((d) => store.menuItem(d.itemId) != null).toList();
        if (deals.isEmpty) return const SizedBox.shrink();
        final best = deals
            .map((d) => discountPercent(store.menuItem(d.itemId)!.price, d.price))
            .fold<int>(0, (a, b) => a > b ? a : b);
        return Padding(
          padding: const EdgeInsets.only(top: 14),
          child: StegoCard(
            color: const Color(0xFF1B1A3A),
            borderColor: const Color(0xFF1B1A3A),
            onTap: onTap,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const IconBadge(Icons.nightlight_round, color: StegoColors.flame),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${LastCallCopy.title} di Jasmine Cafe!',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '${deals.length} item, jimat sehingga $best% • tamat dalam ${durationLabel(store.lastCallMinutesLeft)}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white),
              ],
            ),
          ),
        );
      },
    );
  }
}
