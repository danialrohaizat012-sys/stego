import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../data/store.dart';
import 'widgets/common.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _join() {
    if (!_form.currentState!.validate()) return;
    context.read<AppStore>().completeOnboarding(name: _name.text, phone: _phone.text);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: StegoColors.navy,
      body: SpaceBackground(
        radius: 0,
        child: SafeArea(
          child: ContentWidth(
            maxWidth: 520,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              children: [
                const SizedBox(height: 12),
                const StegoLogo(height: 150),
                const SizedBox(height: 18),
                Text(
                  'Selamat datang ke Stegoland!',
                  textAlign: TextAlign.center,
                  style: text.headlineMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tempah slot bermain, urus lawatan sekolah dan pesan makanan Jasmine Cafe — semua dalam satu app.',
                  textAlign: TextAlign.center,
                  style: text.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                ),
                const SizedBox(height: 24),
                const _Perks(),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Daftar Stego Member', style: text.titleLarge),
                        const SizedBox(height: 4),
                        const Text(
                          'Percuma. Kumpul mata setiap kali bermain & makan.',
                          style: TextStyle(color: StegoColors.muted),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Nama penuh',
                            prefixIcon: Icon(Icons.person_rounded),
                          ),
                          validator: (v) => (v ?? '').trim().isEmpty ? 'Sila isi nama' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'No. telefon',
                            hintText: '01X-XXX XXXX',
                            prefixIcon: Icon(Icons.phone_rounded),
                          ),
                          validator: (v) =>
                              (v ?? '').replaceAll(RegExp(r'\D'), '').length < 9 ? 'No. telefon tidak sah' : null,
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: _join,
                          icon: const Icon(Icons.rocket_launch_rounded),
                          label: const Text('Jom Mula!'),
                        ),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: () => context.read<AppStore>().completeOnboarding(),
                          child: const Text('Teruskan sebagai tetamu'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Perks extends StatelessWidget {
  const _Perks();

  @override
  Widget build(BuildContext context) {
    Widget perk(IconData icon, String label) => Expanded(
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: StegoColors.flame),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
    return Row(
      children: [
        perk(Icons.event_available_rounded, 'Tempah\nslot'),
        perk(Icons.school_rounded, 'Lawatan\nsekolah'),
        perk(Icons.local_cafe_rounded, 'Jasmine\nCafe'),
        perk(Icons.stars_rounded, 'Mata\nganjaran'),
      ],
    );
  }
}
