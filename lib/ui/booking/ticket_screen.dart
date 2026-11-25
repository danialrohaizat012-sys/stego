import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/format.dart';
import '../../core/links.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../widgets/common.dart';

Color bookingStatusColor(BookingStatus s) => switch (s) {
  BookingStatus.pending => const Color(0xFFB7791F),
  BookingStatus.confirmed => StegoColors.mint,
  BookingStatus.checkedIn => StegoColors.navySoft,
  BookingStatus.cancelled || BookingStatus.rejected => StegoColors.rocket,
};

/// Builds the WhatsApp summary a customer can send to Stegoland.
String bookingWhatsAppText(AppStore store, Booking b) {
  final date = longDate(parseDateKey(b.date));
  final buf = StringBuffer()
    ..writeln(b.kind == BookingKind.group ? '*Permohonan Lawatan Kumpulan*' : '*Tempahan Tiket Stegoland*')
    ..writeln('Rujukan: ${b.id}')
    ..writeln('Tarikh: $date')
    ..writeln('Slot: ${store.slotLabel(b.slotId)}');
  final g = b.group;
  if (g != null) {
    buf
      ..writeln('Institusi: ${g.institution} (${g.institutionType})')
      ..writeln('Guru PIC: ${b.contactName} • ${b.contactPhone}')
      ..writeln('Murid: ${b.children} • Guru: ${g.teachers}')
      ..writeln('Kids Meal: ${g.meals} • Iced Lemon Tea: ${g.drinks}')
      ..writeln('Sesi privasi: ${g.privateSession ? 'Ya' : 'Tidak'}');
    if (g.notes.isNotEmpty) buf.writeln('Catatan: ${g.notes}');
  } else {
    buf
      ..writeln('Nama: ${b.contactName} • ${b.contactPhone}')
      ..writeln('Kanak-kanak: ${b.children} • Penjaga: ${b.guardians}');
  }
  buf.writeln('Jumlah: ${rm(b.total)}');
  return buf.toString();
}

class TicketScreen extends StatelessWidget {
  const TicketScreen({super.key, required this.bookingId, this.justCreated = false});
  final String bookingId;
  final bool justCreated;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final b = store.bookingById(bookingId);
    if (b == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Tempahan tidak dijumpai',
          message: 'Tempahan ini mungkin telah dipadam.',
        ),
      );
    }
    final isGroup = b.kind == BookingKind.group;
    final date = parseDateKey(b.date);
    final canCancel = b.status == BookingStatus.pending || b.status == BookingStatus.confirmed;

    return Scaffold(
      backgroundColor: StegoColors.navy,
      appBar: AppBar(
        backgroundColor: StegoColors.navy,
        foregroundColor: Colors.white,
        titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(color: Colors.white),
        title: Text(isGroup ? 'Permohonan Kumpulan' : 'Tiket Anda'),
      ),
      body: SpaceBackground(
        radius: 0,
        child: ContentWidth(
          maxWidth: 520,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              if (justCreated) ...[
                const Icon(Icons.celebration_rounded, color: StegoColors.flame, size: 44),
                const SizedBox(height: 8),
                Text(
                  isGroup ? 'Permohonan dihantar!' : 'Tempahan berjaya!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  isGroup
                      ? 'Pihak Stegoland akan menghubungi anda untuk pengesahan.'
                      : 'Tunjukkan kod QR ini di kaunter semasa tiba.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 18),
              ],
              _TicketCard(booking: b, date: date, slot: store.slotLabel(b.slotId)),
              const SizedBox(height: 18),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
                onPressed: () => openWhatsApp(store.business, bookingWhatsAppText(store, b)),
                icon: const Icon(Icons.chat_rounded),
                label: Text(isGroup ? 'Hantar ke WhatsApp Stegoland' : 'Kongsi melalui WhatsApp'),
              ),
              const SizedBox(height: 10),
              if (canCancel)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                  ),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Batalkan tempahan?'),
                        content: const Text('Tempat anda akan dilepaskan kepada pengunjung lain.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Tidak')),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: StegoColors.rocket,
                              minimumSize: const Size(64, 44),
                            ),
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('Ya, batal'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) await store.setBookingStatus(b.id, BookingStatus.cancelled);
                  },
                  child: const Text('Batalkan tempahan'),
                ),
              if (justCreated) ...[
                const SizedBox(height: 4),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Selesai'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.booking, required this.date, required this.slot});
  final Booking booking;
  final DateTime date;
  final String slot;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final g = b.group;
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              children: [
                const StegoLogo(height: 56),
                const SizedBox(height: 10),
                StatusPill(b.status.label, color: bookingStatusColor(b.status)),
                const SizedBox(height: 14),
                if (b.status.isActive)
                  QrImageView(
                    data: 'STEGOLAND:${b.id}',
                    size: 190,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: StegoColors.navy),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.circle,
                      color: StegoColors.navy,
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Icon(Icons.block_rounded, size: 80, color: StegoColors.line),
                  ),
                const SizedBox(height: 6),
                SelectableText(
                  b.id,
                  style: const TextStyle(
                    fontFamily: StegoTheme.display,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const _Perforation(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              children: [
                if (g != null) LineRow('Institusi', g.institution),
                LineRow('Tarikh', longDate(date)),
                LineRow('Slot', slot),
                LineRow(g != null ? 'Murid' : 'Kanak-kanak', '${b.children}'),
                LineRow(g != null ? 'Guru' : 'Penjaga', '${b.guardians}'),
                if (g != null && g.meals > 0) LineRow('Kids Meal', '${g.meals}'),
                if (g != null && g.drinks > 0) LineRow('Iced Lemon Tea', '${g.drinks}'),
                if (g != null && g.privateSession) const LineRow('Sesi privasi', 'Ya'),
                LineRow('Nama', b.contactName),
                const Divider(height: 20),
                LineRow('Jumlah', rm(b.total), bold: true),
                LineRow('Bayaran', b.paid ? 'Telah dibayar' : 'Bayar di kaunter', muted: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Perforation extends StatelessWidget {
  const _Perforation();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        children: [
          Container(
            width: 12,
            decoration: const BoxDecoration(
              color: StegoColors.navy,
              borderRadius: BorderRadius.horizontal(right: Radius.circular(12)),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final n = (c.maxWidth / 12).floor();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(n, (_) => Container(width: 6, height: 2, color: StegoColors.line)),
                );
              },
            ),
          ),
          Container(
            width: 12,
            decoration: const BoxDecoration(
              color: StegoColors.navy,
              borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
