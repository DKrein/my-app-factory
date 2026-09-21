import 'package:factory_ui/factory_ui.dart';
import 'package:flutter/material.dart';

import 'app_config.g.dart';

void main() => runApp(const SleepSoundsApp());

class SleepSoundsApp extends StatelessWidget {
  const SleepSoundsApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: AppConfig.name,
    debugShowCheckedModeBanner: false,
    theme: factoryDarkTheme(),
    home: const LibraryPage(),
  );
}

class Sound {
  const Sound(this.name, this.detail, this.icon, this.color);
  final String name, detail;
  final IconData icon;
  final Color color;
}

const sounds = [
  Sound(
    'Chuva suave',
    'Gotas constantes em uma janela tranquila',
    Icons.water_drop_outlined,
    Color(0xFF7DA9E8),
  ),
  Sound(
    'Ondas noturnas',
    'Mar lento e distante',
    Icons.waves_outlined,
    Color(0xFF8ED9C7),
  ),
  Sound(
    'Ruído marrom',
    'Grave contínuo e aconchegante',
    Icons.graphic_eq,
    Color(0xFFC7A6F5),
  ),
  Sound(
    'Ventilador',
    'Sopro uniforme para abafar distrações',
    Icons.air_outlined,
    Color(0xFFF1C589),
  ),
];

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  Sound? selected;
  final favorites = <String>{};

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Boa noite',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
              IconButton(
                onPressed: _settings,
                icon: const Icon(Icons.tune_outlined),
                tooltip: 'Configurações',
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Escolha um som e deixe o dia baixar o volume.',
            style: TextStyle(color: FactoryColors.mutedInk),
          ),
          const SizedBox(height: 28),
          Card(
            child: ListTile(
              onTap: selected == null ? null : () => _player(selected!),
              leading: CircleAvatar(
                child: Icon(selected?.icon ?? Icons.nightlight_round),
              ),
              title: Text(selected?.name ?? 'Escolha um som'),
              subtitle: Text(
                selected == null ? 'Sua noite começa aqui' : 'Tocando agora',
              ),
              trailing: Icon(
                selected == null ? Icons.arrow_downward : Icons.play_arrow,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Para desacelerar',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sounds.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: .88,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (_, i) => _card(sounds[i]),
          ),
        ],
      ),
    ),
  );

  Widget _card(Sound sound) {
    final favorite = favorites.contains(sound.name);
    return Card(
      child: InkWell(
        onTap: () {
          setState(() => selected = sound);
          _player(sound);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(
                    () => favorite
                        ? favorites.remove(sound.name)
                        : favorites.add(sound.name),
                  ),
                  icon: Icon(
                    favorite ? Icons.favorite : Icons.favorite_border,
                    color: favorite
                        ? FactoryColors.mist
                        : FactoryColors.mutedInk,
                  ),
                ),
              ),
              Icon(sound.icon, size: 34, color: sound.color),
              const Spacer(),
              Text(sound.name, style: Theme.of(context).textTheme.titleMedium),
              Text(
                sound.detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: FactoryColors.mutedInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _settings() => showModalBottomSheet<void>(
    context: context,
    backgroundColor: FactoryColors.surfaceElevated,
    builder: (_) => const Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'Configurações\n\nTema escuro\nTimer com pausa suave',
        style: TextStyle(fontSize: 18),
      ),
    ),
  );
  void _player(Sound sound) => showModalBottomSheet<void>(
    context: context,
    backgroundColor: FactoryColors.surfaceElevated,
    builder: (_) => Player(sound: sound),
  );
}

class Player extends StatefulWidget {
  const Player({super.key, required this.sound});
  final Sound sound;
  @override
  State<Player> createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  bool playing = true;
  int timer = 0;
  double volume = .7;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: widget.sound.color.withValues(alpha: .25),
            child: Icon(widget.sound.icon, size: 52, color: widget.sound.color),
          ),
          const SizedBox(height: 16),
          Text(
            widget.sound.name,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          IconButton.filled(
            onPressed: () => setState(() => playing = !playing),
            icon: Icon(playing ? Icons.pause : Icons.play_arrow),
            tooltip: playing ? 'Pausar' : 'Tocar',
          ),
          Slider(value: volume, onChanged: (v) => setState(() => volume = v)),
          Wrap(
            spacing: 8,
            children: [0, 15, 30, 45, 60]
                .map(
                  (m) => ChoiceChip(
                    label: Text(m == 0 ? 'Sem timer' : '$m min'),
                    selected: timer == m,
                    onSelected: (_) => setState(() => timer = m),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    ),
  );
}
