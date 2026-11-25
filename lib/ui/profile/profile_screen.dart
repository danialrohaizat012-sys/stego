import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/links.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/seed.dart';
import '../../data/store.dart';
import '../admin/admin_screen.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final m = store.member;
    final b = store.business;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            if (m != null) _MemberCard(member: m) else const _JoinCard(),
            if (m != null) ...[
              const SizedBox(height: 22),
              const SectionHeader('Tebus Ganjaran'),
              for (final r in defaultRewards)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RewardTile(reward: r, points: m.points),
                ),
              const Text(
                'Dapat 1 mata bagi setiap RM1 yang dibelanjakan (selepas daftar masuk / pesanan selesai).',
                style: TextStyle(color: StegoColors.muted, fontSize: 12),
              ),
            ],
            if (store.vouchers.isNotEmpty) ...[
              const SizedBox(height: 22),
              const SectionHeader('Baucar Saya'),
              for (final v in store.vouchers)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: StegoCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const IconBadge(Icons.card_giftcard_rounded, color: StegoColors.rocket),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(v.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                              SelectableText(v.code, style: const TextStyle(color: StegoColors.muted)),
                            ],
                          ),
                        ),
                        const Text('Tunjuk di kaunter', style: TextStyle(fontSize: 12, color: StegoColors.muted)),
                      ],
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 22),
            const SectionHeader('Tentang Stegoland'),
            StegoCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.chat_rounded, color: StegoColors.navy),
                    title: const Text('WhatsApp kami'),
                    subtitle: Text(b.phone),
                    onTap: () => openWhatsApp(b),
                  ),
                  ListTile(
                    leading: const Icon(Icons.music_note_rounded, color: StegoColors.navy),
                    title: const Text('TikTok'),
                    subtitle: Text(b.tiktok),
                    onTap: () => openTikTok(b),
                  ),
                  ListTile(
                    leading: const Icon(Icons.facebook_rounded, color: StegoColors.navy),
                    title: const Text('Facebook'),
                    subtitle: const Text('Stegoland Indoor Playground'),
                    onTap: () => openFacebook(b),
                  ),
                  ListTile(
                    leading: const Icon(Icons.location_on_rounded, color: StegoColors.navy),
                    title: const Text('Lokasi'),
                    subtitle: Text(b.address),
                    onTap: () => openMaps(b),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            StegoCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings_rounded, color: StegoColors.rocket),
                title: const Text('Mod Staf / Admin', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text('Urus tempahan, pesanan kafe, menu & harga'),
                trailing: const Icon(Icons.lock_rounded),
                onTap: () => _openAdmin(context),
              ),
            ),
            const SizedBox(height: 24),
            const Center(child: StegoLogo(height: 44)),
            const SizedBox(height: 6),
            const Center(
              child: Text('Versi 1.0.0', style: TextStyle(color: StegoColors.muted, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAdmin(BuildContext context) async {
    final store = context.read<AppStore>();
    final pin = await showDialog<String>(context: context, builder: (_) => const _PinDialog());
    if (pin == null || !context.mounted) return;
    if (!store.checkPin(pin)) return showSnack(context, 'PIN salah');
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminScreen()));
  }
}

class _PinDialog extends StatefulWidget {
  const _PinDialog();

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('PIN Staf'),
      content: TextField(
        controller: _c,
        autofocus: true,
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: 6,
        decoration: const InputDecoration(hintText: '••••', counterText: ''),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
          onPressed: () => Navigator.pop(context, _c.text),
          child: const Text('Masuk'),
        ),
      ],
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member});
  final Member member;

  @override
  Widget build(BuildContext context) {
    final m = member;
    return SpaceBackground(
      radius: 26,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const StatusPill('STEGO MEMBER', color: StegoColors.flame, icon: Icons.verified_rounded),
                const Spacer(),
                IconButton(
                  tooltip: 'Edit profil',
                  onPressed: () => _edit(context),
                  icon: const Icon(Icons.edit_rounded, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(m.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white)),
            Text('${m.id} • ${m.phone}', style: TextStyle(color: Colors.white.withValues(alpha: 0.75))),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${m.points}',
                  style: const TextStyle(
                    fontFamily: StegoTheme.display,
                    color: StegoColors.flame,
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 8),
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    'mata',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                const Spacer(),
                Text(
                  'Ahli sejak ${monthShort(m.joined)} ${m.joined.year}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final store = context.read<AppStore>();
    final name = TextEditingController(text: member.name);
    final phone = TextEditingController(text: member.phone);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Edit profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nama'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'No. telefon'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty && phone.text.trim().isNotEmpty) {
      await store.updateMember(name: name.text.trim(), phone: phone.text.trim());
    }
    name.dispose();
    phone.dispose();
  }
}

class _JoinCard extends StatefulWidget {
  const _JoinCard();

  @override
  State<_JoinCard> createState() => _JoinCardState();
}

class _JoinCardState extends State<_JoinCard> {
  final _name = TextEditingController();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StegoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Jadi Stego Member', style: Theme.of(context).textTheme.titleLarge),
          const Text('Percuma! Kumpul mata dan tebus ganjaran.', style: TextStyle(color: StegoColors.muted)),
          const SizedBox(height: 14),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nama'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'No. telefon'),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () {
              if (_name.text.trim().isEmpty || _phone.text.replaceAll(RegExp(r'\D'), '').length < 9) {
                return showSnack(context, 'Sila isi nama dan no. telefon yang sah');
              }
              context.read<AppStore>().updateMember(name: _name.text.trim(), phone: _phone.text.trim());
            },
            child: const Text('Daftar'),
          ),
        ],
      ),
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({required this.reward, required this.points});
  final Reward reward;
  final int points;

  @override
  Widget build(BuildContext context) {
    final can = points >= reward.cost;
    return StegoCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          IconBadge(Icons.redeem_rounded, color: can ? StegoColors.rocket : StegoColors.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(reward.description, style: const TextStyle(color: StegoColors.muted, fontSize: 12)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: (points / reward.cost).clamp(0, 1).toDouble(),
                    minHeight: 5,
                    backgroundColor: StegoColors.surface,
                    color: StegoColors.flame,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            onPressed: can
                ? () async {
                    final code = await context.read<AppStore>().redeem(reward);
                    if (code != null && context.mounted) showSnack(context, 'Berjaya! Kod baucar: $code');
                  }
                : null,
            child: Text('${reward.cost} mata'),
          ),
        ],
      ),
    );
  }
}
