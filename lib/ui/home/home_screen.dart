import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/links.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../booking/family_booking_screen.dart';
import '../booking/group_booking_screen.dart';
import '../cafe/last_call.dart';
import '../shell.dart';
import '../widgets/common.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final s = store.settings;
    final b = store.business;
    final today = dateOnly(store.now);
    final firstName = store.member?.name.split(' ').first;

    return SafeArea(
      bottom: false,
      child: ContentWidth(
        maxWidth: 720,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    const StegoLogo(height: 54),
                    const Spacer(),
                    IconButton.filledTonal(
                      tooltip: 'WhatsApp Stegoland',
                      style: IconButton.styleFrom(backgroundColor: StegoColors.skyTint),
                      onPressed: () => openWhatsApp(b, 'Hai Stegoland, saya ingin bertanya.'),
                      icon: const Icon(Icons.chat_rounded, color: StegoColors.navy),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              sliver: SliverList.list(
                children: [
                  Text(
                    firstName == null ? 'Hai, angkasawan cilik! 👋' : 'Hai, $firstName! 👋',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Sedia untuk misi bermain hari ini?',
                    style: TextStyle(color: StegoColors.muted, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  _Hero(dayType: store.dayType(today), price: store.childPrice(today), hours: b.openingHours),
                  LastCallBanner(onTap: () => ShellScope.of(context)?.goTo(Tabs.cafe)),
                  const SizedBox(height: 18),
                  const _QuickActions(),
                  const SizedBox(height: 22),
                  const SectionHeader('Harga Tiket'),
                  _PriceCard(settings: s),
                  const SizedBox(height: 22),
                  const SectionHeader('Zon Permainan'),
                  const _Zones(),
                  const SizedBox(height: 22),
                  _SchoolPromo(settings: s),
                  const SizedBox(height: 22),
                  const SectionHeader('Sebelum Datang'),
                  const _Rules(),
                  const SizedBox(height: 22),
                  const SectionHeader('Lokasi & Hubungi'),
                  _Contact(business: b),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.dayType, required this.price, required this.hours});
  final DayType dayType;
  final double price;
  final String hours;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SpaceBackground(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusPill('Hari ini • ${dayType.label}', color: StegoColors.flame, icon: Icons.wb_sunny_rounded),
                  const SizedBox(height: 12),
                  Text('Jom ke angkasa!', style: text.headlineMedium?.copyWith(color: Colors.white, height: 1.05)),
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Tiket kanak-kanak '),
                        TextSpan(
                          text: rm(price),
                          style: const TextStyle(color: StegoColors.flame, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(hours, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: StegoColors.flame,
                      foregroundColor: StegoColors.ink,
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: () =>
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FamilyBookingScreen())),
                    icon: const Icon(Icons.rocket_launch_rounded),
                    label: const Text('Tempah Slot'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const FloatingMascot(width: 104),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    void push(Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    final shell = ShellScope.of(context);

    final items = [
      (Icons.family_restroom_rounded, 'Tiket\nKeluarga', StegoColors.navy, () => push(const FamilyBookingScreen())),
      (Icons.school_rounded, 'Sekolah &\nKumpulan', StegoColors.rocket, () => push(const GroupBookingScreen())),
      (Icons.local_cafe_rounded, 'Jasmine\nCafe', StegoColors.jasmine, () => shell?.goTo(Tabs.cafe)),
      (Icons.confirmation_number_rounded, 'Tiket\nSaya', StegoColors.sky, () => shell?.goTo(Tabs.tickets)),
    ];

    return Row(
      children: [
        for (final (icon, label, color, onTap) in items)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: StegoCard(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                onTap: onTap,
                child: Column(
                  children: [
                    IconBadge(icon, color: color),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, height: 1.2),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.settings});
  final Settings settings;

  @override
  Widget build(BuildContext context) {
    Widget tier(String label, String sub, double price, Color color) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(18)),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 13),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(sub, style: const TextStyle(color: StegoColors.muted, fontSize: 11)),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                rm(price),
                style: const TextStyle(fontFamily: StegoTheme.display, fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );

    return StegoCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              tier('Hari Biasa', 'Ahad – Khamis', settings.weekdayPrice, StegoColors.navy),
              const SizedBox(width: 8),
              tier('Hujung Minggu', 'Jumaat & Sabtu', settings.weekendPrice, StegoColors.rocket),
              const SizedBox(width: 8),
              tier('Cuti Umum', '& cuti sekolah', settings.holidayPrice, StegoColors.jasmine),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 18, color: StegoColors.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Harga seorang kanak-kanak. Penjaga dewasa ${rm(settings.guardianPrice)} seorang.',
                  style: const TextStyle(color: StegoColors.muted, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Zones extends StatelessWidget {
  const _Zones();

  static const _zones = [
    (Icons.bubble_chart_rounded, 'Kolam Bola', 'Ball pit berwarna-warni', StegoColors.sky),
    (Icons.water_rounded, 'Gelongsor', 'Banyak gelongsor seronok', StegoColors.rocket),
    (Icons.terrain_rounded, 'Zon Memanjat', 'Halangan & panjat', StegoColors.navy),
    (Icons.donut_large_rounded, 'Tubing', 'Pengalaman tubing', StegoColors.flame),
    (Icons.child_friendly_rounded, 'Zon Bayi & Toddler', 'Selamat untuk si kecil', StegoColors.jasmine),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: _zones.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final (icon, title, sub, color) = _zones[i];
          return SizedBox(
            width: 140,
            child: StegoCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconBadge(icon, color: color),
                  const Spacer(),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(sub, style: const TextStyle(color: StegoColors.muted, fontSize: 12)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SchoolPromo extends StatelessWidget {
  const _SchoolPromo({required this.settings});
  final Settings settings;

  @override
  Widget build(BuildContext context) {
    return StegoCard(
      color: StegoColors.rocket,
      borderColor: StegoColors.rocket,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GroupBookingScreen())),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StatusPill('Untuk cikgu & tadika', color: Colors.white, icon: Icons.school_rounded),
                const SizedBox(height: 10),
                Text(
                  'Lawatan Sekolah ${rm(settings.groupChildPrice)}/murid',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  '${settings.freeTeachers} guru percuma • Kids Meal ${rm(settings.kidsMealPrice)} • '
                  'Sesi privasi +${rm(settings.privateSessionPrice)}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_forward_rounded, color: StegoColors.rocket),
          ),
        ],
      ),
    );
  }
}

class _Rules extends StatelessWidget {
  const _Rules();

  static const _rules = [
    (Icons.do_not_step_rounded, 'Wajib berstoking', 'Untuk kanak-kanak dan penjaga di kawasan bermain.'),
    (Icons.supervisor_account_rounded, 'Diiringi penjaga', 'Kanak-kanak perlu diawasi penjaga sepanjang masa.'),
    (Icons.qr_code_2_rounded, 'Tunjuk tiket QR', 'Tunjukkan tiket di kaunter untuk daftar masuk.'),
    (Icons.schedule_rounded, 'Datang awal 10 minit', 'Supaya masa bermain anda tidak terjejas.'),
  ];

  @override
  Widget build(BuildContext context) {
    return StegoCard(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Column(
        children: [
          for (final (icon, title, sub) in _rules)
            ListTile(
              leading: IconBadge(icon, size: 40, color: StegoColors.navySoft),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(sub),
            ),
        ],
      ),
    );
  }
}

class _Contact extends StatelessWidget {
  const _Contact({required this.business});
  final BusinessInfo business;

  @override
  Widget build(BuildContext context) {
    final b = business;
    Widget action(IconData icon, String label, Future<bool> Function() onTap) => Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          minimumSize: const Size(0, 64),
        ),
        onPressed: () async {
          final ok = await onTap();
          if (!ok && context.mounted) showSnack(context, 'Tidak dapat membuka $label');
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: StegoColors.navy),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: StegoColors.ink)),
          ],
        ),
      ),
    );

    return StegoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconBadge(Icons.location_on_rounded, color: StegoColors.rocket),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${b.name} & ${b.cafeName}', style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(b.address, style: const TextStyle(color: StegoColors.muted)),
                    const SizedBox(height: 6),
                    Text(b.openingHours, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              action(Icons.chat_rounded, 'WhatsApp', () => openWhatsApp(b)),
              const SizedBox(width: 8),
              action(Icons.call_rounded, 'Telefon', () => callPhone(b)),
              const SizedBox(width: 8),
              action(Icons.navigation_rounded, 'Waze', () => openWaze(b)),
              const SizedBox(width: 8),
              action(Icons.map_rounded, 'Maps', () => openMaps(b)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              action(Icons.music_note_rounded, 'TikTok', () => openTikTok(b)),
              const SizedBox(width: 8),
              action(Icons.facebook_rounded, 'Facebook', () => openFacebook(b)),
            ],
          ),
        ],
      ),
    );
  }
}
