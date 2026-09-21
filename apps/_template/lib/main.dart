import 'package:factory_storage/factory_storage.dart';
import 'package:factory_ui/factory_ui.dart';
import 'package:flutter/material.dart';

import 'app_config.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await SharedPreferencesStore.create();

  runApp(
    TemplateApp(storage: storage),
  );
}

class TemplateApp extends StatelessWidget {
  const TemplateApp({super.key, this.storage});

  final KeyValueStore? storage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.name,
      debugShowCheckedModeBanner: false,
      theme: factoryDarkTheme(),
      home: HomePage(storage: storage ?? MemoryKeyValueStore()),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.storage});

  final KeyValueStore storage;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _counterKey = 'starter_counter';
  int _counter = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final raw = await widget.storage.readString(_counterKey);
    if (raw != null && mounted) {
      setState(() {
        _counter = int.tryParse(raw) ?? 0;
        _loaded = true;
      });
    } else if (mounted) {
      setState(() => _loaded = true);
    }
  }

  Future<void> _increment() async {
    setState(() => _counter++);
    await widget.storage.writeString(_counterKey, _counter.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.name),
        backgroundColor: FactoryColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Sobre o App',
            onPressed: () => _showAbout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(FactorySpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bem-vindo!',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: FactorySpacing.sm),
              const Text(
                'Este é o ponto de partida para o seu novo aplicativo na App Factory.',
                style: TextStyle(color: FactoryColors.mutedInk),
              ),
              const SizedBox(height: FactorySpacing.xl),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(FactorySpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.storage, color: FactoryColors.mist),
                          const SizedBox(width: FactorySpacing.md),
                          Text(
                            'Persistência Local Ativa',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: FactorySpacing.md),
                      Text(
                        _loaded
                            ? 'Ações realizadas e salvas no KeyValueStore: $_counter'
                            : 'Carregando estado...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: FactorySpacing.lg),
                      FilledButton.icon(
                        onPressed: _increment,
                        icon: const Icon(Icons.add),
                        label: const Text('Incrementar Ação'),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Center(
                child: Text(
                  '${AppConfig.applicationId} v${AppConfig.version}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: FactoryColors.mutedInk,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: FactoryColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(FactorySpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sobre este Aplicativo',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: FactorySpacing.md),
              Text(
                'Construído com Flutter sobre a base reutilizável da App Factory. '
                'Totalmente offline-first, sem dependências ocultas de rede.',
                style: TextStyle(color: FactoryColors.mutedInk),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
