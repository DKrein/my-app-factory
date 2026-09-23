import 'package:factory_storage/factory_storage.dart';
import 'package:factory_ui/factory_ui.dart';
import 'package:flutter/material.dart';

const splashTaglines = [
  'Sleeping like a capybara with a full belly.',
  "Have you ever seen a capybara complain about a bad night's sleep?",
  'Keep calm and capy-sleep on.',
  'Time to capybara down and drift away.',
  'Sweet dreams, little capy-dreamer.',
  'No worries, just capy-naps.',
  'Life is better with a little more capy-sleep.',
  'Let your worries float away like a sleepy capybara.',
  'A cozy capybara is a sleepy capybara.',
  "Tonight, we're taking it easy — capy-easy.",
];

class AppSplashScreen extends StatefulWidget {
  const AppSplashScreen({super.key, required this.storage, required this.next});

  final KeyValueStore storage;
  final Widget next;

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen> {
  static const _taglineIndexKey = 'splash_tagline_index_v1';
  static const _splashDuration = Duration(milliseconds: 3500);

  String _tagline = splashTaglines.first;

  @override
  void initState() {
    super.initState();
    _pickTagline();
    Future.delayed(_splashDuration, _goToNext);
  }

  Future<void> _pickTagline() async {
    final stored = await widget.storage.readString(_taglineIndexKey);
    final index = int.tryParse(stored ?? '') ?? 0;
    if (mounted) {
      setState(() => _tagline = splashTaglines[index % splashTaglines.length]);
    }
    await widget.storage.writeString(
      _taglineIndexKey,
      '${(index + 1) % splashTaglines.length}',
    );
  }

  void _goToNext() {
    if (!mounted) return;
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => widget.next));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: FactoryColors.night,
    body: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sleepy Capy',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: FactoryColors.ink,
              ),
            ),
            const SizedBox(height: 20),
            Image.asset('assets/branding/icon_foreground.png', width: 200),
            const SizedBox(height: 24),
            Text(
              _tagline,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: FactoryColors.mutedInk,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
