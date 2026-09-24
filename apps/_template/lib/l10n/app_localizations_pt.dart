// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get aboutTooltip => 'Sobre o app';

  @override
  String get welcome => 'Bem-vindo!';

  @override
  String get welcomeBody =>
      'Este é o ponto de partida para o seu novo aplicativo na App Factory.';

  @override
  String get persistenceActive => 'Persistência local ativa';

  @override
  String actionsSaved(int count) {
    return 'Ações realizadas e salvas no KeyValueStore: $count';
  }

  @override
  String get loadingState => 'Carregando estado...';

  @override
  String get incrementAction => 'Incrementar ação';

  @override
  String get aboutTitle => 'Sobre este aplicativo';

  @override
  String get aboutBody =>
      'Construído com Flutter sobre a base reutilizável da App Factory. Totalmente offline-first, sem dependências ocultas de rede.';
}
