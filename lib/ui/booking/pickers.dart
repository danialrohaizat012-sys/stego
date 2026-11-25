import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../widgets/common.dart';

/// Horizontal strip of the next [days] days, coloured by price tier.
class DateStrip extends StatelessWidget {
  const DateStrip({super.key, required this.selected, required this.onSelected, this.days = 45, this.showPrice = true});

  final DateTime selected;
  final ValueChanged<DateTime> onSelected;
  final int days;
  final bool showPrice;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final today = dateOnly(store.now);
    return SizedBox(
      height: showPrice ? 112 : 94,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days,
        clipBehavior: Clip.none,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final d = today.add(Duration(days: i));
          final isSel = dateOnly(selected) == d;
          final type = store.dayType(d);
          final open = store.slotsFor(d).isNotEmpty;
          final accent = switch (type) {
            DayType.weekday => StegoColors.navy,
            DayType.weekend => StegoColors.rocket,
            DayType.holiday => StegoColors.jasmine,
          };
          return Semantics(
            button: true,
            selected: isSel,
            label: '${longDate(d)}, ${type.label}',
            child: GestureDetector(
              onTap: open ? () => onSelected(d) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 66,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSel ? StegoColors.navy : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSel ? StegoColors.navy : StegoColors.line, width: 1.5),
                ),
                child: Opacity(
                  opacity: open ? 1 : 0.35,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        i == 0 ? 'Hari ini' : dayShort(d),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSel ? Colors.white70 : StegoColors.muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${d.day}',
                        style: TextStyle(
                          fontFamily: StegoTheme.display,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: isSel ? Colors.white : StegoColors.ink,
                        ),
                      ),
                      Text(
                        monthShort(d),
                        style: TextStyle(fontSize: 11, color: isSel ? Colors.white70 : StegoColors.muted),
                      ),
                      if (showPrice) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(color: isSel ? StegoColors.flame : accent, shape: BoxShape.circle),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class DayTypeLegend extends StatelessWidget {
  const DayTypeLegend({super.key});

  @override
  Widget build(BuildContext context) {
    Widget dot(Color c, String l) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          l,
          style: const TextStyle(fontSize: 12, color: StegoColors.muted, fontWeight: FontWeight.w600),
        ),
      ],
    );
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: [
        dot(StegoColors.navy, 'Hari biasa'),
        dot(StegoColors.rocket, 'Hujung minggu'),
        dot(StegoColors.jasmine, 'Cuti umum'),
      ],
    );
  }
}

/// Grid of time slots for a date showing remaining capacity.
class SlotPicker extends StatelessWidget {
  const SlotPicker({
    super.key,
    required this.date,
    required this.selectedId,
    required this.onSelected,
    this.needed = 1,
    this.requireEmpty = false,
  });

  final DateTime date;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  /// Seats the user needs — slots with fewer remaining are disabled.
  final int needed;

  /// For private sessions: slot must have no bookings at all.
  final bool requireEmpty;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final slots = store.slotsFor(date);
    final friday = date.weekday == DateTime.friday && store.settings.fridayPrayerBreak;

    if (slots.isEmpty) {
      return const StegoCard(
        child: Row(
          children: [
            Icon(Icons.event_busy_rounded, color: StegoColors.muted),
            SizedBox(width: 12),
            Expanded(child: Text('Tiada slot dibuka untuk tarikh ini. Sila pilih tarikh lain.')),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth > 520 ? 3 : 2;
            const gap = 10.0;
            final w = (c.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final s in slots)
                  SizedBox(
                    width: w,
                    child: _SlotTile(slot: s, date: date, store: store, picker: this),
                  ),
              ],
            );
          },
        ),
        if (friday)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Row(
              children: [
                Icon(Icons.mosque_rounded, size: 16, color: StegoColors.muted),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Hari Jumaat: rehat solat Jumaat, slot tengah hari ditutup.',
                    style: TextStyle(color: StegoColors.muted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({required this.slot, required this.date, required this.store, required this.picker});
  final TimeSlot slot;
  final DateTime date;
  final AppStore store;
  final SlotPicker picker;

  @override
  Widget build(BuildContext context) {
    final left = store.remaining(date, slot.id);
    final cap = store.settings.slotCapacity;
    final booked = store.bookedChildren(date, slot.id);
    final enabled = left >= picker.needed && (!picker.requireEmpty || booked == 0);
    final selected = picker.selectedId == slot.id;
    final ratio = cap == 0 ? 1.0 : (cap - left) / cap;
    final barColor = ratio > 0.85
        ? StegoColors.rocket
        : ratio > 0.6
        ? StegoColors.flame
        : StegoColors.mint;

    final status = left == 0
        ? (store.isPrivate(date, slot.id) ? 'Sesi privasi' : 'Penuh')
        : picker.requireEmpty && booked > 0
        ? 'Ada tempahan'
        : '$left tempat lagi';

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: '${timeLabel(slot.start)} hingga ${timeLabel(slot.end)}, $status',
      child: Material(
        color: selected ? StegoColors.navy : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: selected ? StegoColors.navy : StegoColors.line, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? () => picker.onSelected(slot.id) : null,
          child: Opacity(
            opacity: enabled ? 1 : 0.45,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${timeLabel(slot.start)} –\n${timeLabel(slot.end)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      height: 1.25,
                      color: selected ? Colors.white : StegoColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: ratio.clamp(0, 1).toDouble(),
                      minHeight: 5,
                      backgroundColor: selected ? Colors.white24 : StegoColors.surface,
                      color: barColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white70 : StegoColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Numeric field with − / + buttons; good for large counts like 45 students.
class CountField extends StatefulWidget {
  const CountField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.helper,
    this.icon,
    this.min = 0,
    this.max = 500,
  });

  final String label;
  final String? helper;
  final IconData? icon;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  State<CountField> createState() => _CountFieldState();
}

class _CountFieldState extends State<CountField> {
  late final _c = TextEditingController(text: '${widget.value}');

  @override
  void didUpdateWidget(CountField old) {
    super.didUpdateWidget(old);
    if ('${widget.value}' != _c.text && int.tryParse(_c.text) != widget.value) {
      _c.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _set(int v) {
    final clamped = v.clamp(widget.min, widget.max);
    _c.text = '$clamped';
    widget.onChanged(clamped);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (widget.icon != null) ...[
          IconBadge(widget.icon!, size: 42, color: StegoColors.navySoft),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              if (widget.helper != null)
                Text(widget.helper!, style: const TextStyle(color: StegoColors.muted, fontSize: 12)),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Kurang',
          style: IconButton.styleFrom(backgroundColor: StegoColors.skyTint, foregroundColor: StegoColors.navy),
          onPressed: widget.value > widget.min ? () => _set(widget.value - 1) : null,
          icon: const Icon(Icons.remove_rounded),
        ),
        SizedBox(
          width: 56,
          child: TextField(
            controller: _c,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
            decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10)),
            onChanged: (t) {
              final v = int.tryParse(t);
              if (v != null) widget.onChanged(v.clamp(widget.min, widget.max));
            },
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Tambah',
          style: IconButton.styleFrom(backgroundColor: StegoColors.skyTint, foregroundColor: StegoColors.navy),
          onPressed: widget.value < widget.max ? () => _set(widget.value + 1) : null,
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}

/// Numbered step header used in booking forms.
class StepTitle extends StatelessWidget {
  const StepTitle(this.number, this.title, {super.key, this.trailing});
  final int number;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: StegoColors.flame, shape: BoxShape.circle),
            child: Text(
              '$number',
              style: const TextStyle(fontWeight: FontWeight.w900, color: StegoColors.ink),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
          ?trailing,
        ],
      ),
    );
  }
}

/// Sticky bottom bar with total + primary action.
class TotalBar extends StatelessWidget {
  const TotalBar({
    super.key,
    required this.label,
    required this.total,
    required this.action,
    required this.onPressed,
    this.busy = false,
  });
  final String label;
  final double total;
  final String action;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 12,
      shadowColor: Colors.black26,
      child: SafeArea(
        top: false,
        child: ContentWidth(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(color: StegoColors.muted, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        rm(total),
                        style: const TextStyle(
                          fontFamily: StegoTheme.display,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: busy ? null : onPressed,
                  child: busy
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : Text(action),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
