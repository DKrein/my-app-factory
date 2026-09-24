// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get homeTitle => 'Hora do capi-cochilo';

  @override
  String get timerTitle => 'Timer Capy';

  @override
  String get windDownTitle => 'Para relaxar';

  @override
  String get tooltipSettings => 'Configurações';

  @override
  String get tooltipPause => 'Pausar';

  @override
  String get tooltipPlay => 'Tocar';

  @override
  String get selectSoundToPlay => 'Escolha um som para tocar';

  @override
  String get proIsOn => 'Pro ativado. Valeu!';

  @override
  String get timerOptions => 'Opções do timer';

  @override
  String get timerOptionsPro => 'Opções do timer (Pro)';

  @override
  String get saveMix => 'Salvar mix';

  @override
  String get saveMixPro => 'Salvar mix (Pro)';

  @override
  String get statusPaused => 'Pausado';

  @override
  String get statusPlaying => 'Tocando';

  @override
  String statusStoppingIn(String time) {
    return 'Para em $time';
  }

  @override
  String statusStoppingAt(String clock, String time) {
    return 'Para às $clock · em $time';
  }

  @override
  String statusWithFade(String status, int minutes) {
    return '$status · o volume desce nos últimos $minutes min';
  }

  @override
  String get timerOff => 'Desl.';

  @override
  String get volumeLocked => 'Volume, um recurso Pro';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get tooltipCloseSettings => 'Fechar configurações';

  @override
  String get proTitle => 'Sleepy Capy Pro';

  @override
  String get proCardBody =>
      'Volume de cada som, mixes salvos e mais. Uma compra só, sem anúncios.';

  @override
  String get seePro => 'Conhecer o Pro';

  @override
  String get proThanks => 'Obrigado por apoiar o Sleepy Capy.';

  @override
  String get restorePurchase => 'Restaurar compra';

  @override
  String get bedtimeReminder => 'Lembrete de dormir';

  @override
  String reminderDaily(String time) {
    return 'Todo dia às $time';
  }

  @override
  String get reminderOff => 'Desligado';

  @override
  String get reminderPickerHelp => 'Que horas?';

  @override
  String get rateApp => 'Avaliar o Sleepy Capy';

  @override
  String get sendFeedback => 'Enviar feedback';

  @override
  String get playbackStops => 'O som para sozinho?';

  @override
  String get aboutItem => 'Sobre';

  @override
  String get batteryTitle => 'Otimização de bateria';

  @override
  String get batteryBody =>
      'O Android pode encerrar apps em segundo plano para economizar bateria, e isso pode interromper o som durante a noite.\n\nToque em Abrir configurações, escolha Bateria e permita o uso sem restrições para o Sleepy Capy. Os nomes exatos mudam de aparelho para aparelho.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get openSettings => 'Abrir configurações';

  @override
  String get close => 'Fechar';

  @override
  String get aboutTitle => 'Sobre';

  @override
  String get aboutVersion => 'Versão';

  @override
  String get aboutPrivacyPolicy => 'Política de privacidade';

  @override
  String get aboutContact => 'Contato';

  @override
  String get aboutLicenses => 'Licenças de código aberto';

  @override
  String get aboutAudioCredits => 'Créditos de áudio';

  @override
  String creditLine(String title, String author) {
    return '\"$title\", de $author';
  }

  @override
  String changesLine(String changes) {
    return 'Alterações: $changes';
  }

  @override
  String get creditChangesEdited => 'Cortado, em loop e com o volume ajustado.';

  @override
  String get mixSaveTitle => 'Salvar mix';

  @override
  String get mixRenameTitle => 'Renomear mix';

  @override
  String get mixSaveAction => 'Salvar';

  @override
  String get mixRenameAction => 'Renomear';

  @override
  String get mixDeleteAction => 'Apagar';

  @override
  String get mixNameLabel => 'Nome';

  @override
  String get mixNameTaken => 'Esse nome já existe. Escolha outro.';

  @override
  String mixIncludeTimer(String label) {
    return 'Incluir o timer ($label)';
  }

  @override
  String mixDeleteTitle(String name) {
    return 'Apagar \"$name\"?';
  }

  @override
  String get timerSheetTitle => 'Opções do timer';

  @override
  String get fadeSection => 'Diminuir o volume';

  @override
  String get fadeGradually => 'Diminuir o volume aos poucos';

  @override
  String fadeOnHint(int minutes) {
    return 'O volume vai baixando nos últimos $minutes min.';
  }

  @override
  String get fadeOffHint => 'Desligado: o som some nos últimos 4 s.';

  @override
  String get customDuration => 'Duração personalizada';

  @override
  String get stopAtSection => 'Parar às';

  @override
  String get setAction => 'Definir';

  @override
  String inTime(String time) {
    return 'em $time';
  }

  @override
  String get paywallSubtitle =>
      'Uma compra só, sua para sempre. Sem assinatura.';

  @override
  String get paywallOwnedTitle => 'Você tem o Pro';

  @override
  String get paywallFeatureVolume => 'Ajuste o volume de cada som';

  @override
  String get paywallFeatureMixes => 'Salve quantos mixes quiser';

  @override
  String get paywallFeatureTimer =>
      'Diminua o volume aos poucos, escolha qualquer duração ou pare num horário';

  @override
  String get paywallFeatureThemes => 'Mais temas para a noite';

  @override
  String get paywallFeatureNoAds => 'Sem anúncios';

  @override
  String get paywallFreeNote =>
      'Os 17 sons, a mixagem e o timer continuam grátis.';

  @override
  String paywallPrice(String price) {
    return '$price · compra única';
  }

  @override
  String get getPro => 'Quero o Pro';

  @override
  String get restorePurchases => 'Restaurar compras';

  @override
  String get tryAgain => 'Tentar de novo';

  @override
  String get paywallStoreUnreachable =>
      'Não deu para acessar a loja agora. Confira a conexão e tente de novo.';

  @override
  String get paywallPending =>
      'Esperando o pagamento ser confirmado. O Pro liga sozinho assim que for.';

  @override
  String get paywallPurchaseFailed =>
      'A compra não foi concluída. Tente de novo.';

  @override
  String get paywallRestoreFailed =>
      'Não deu para verificar suas compras. Confira a conexão e tente de novo.';

  @override
  String get paywallNothingToRestore =>
      'Não encontramos nenhuma compra anterior do Pro nesta conta Google.';

  @override
  String get themeTitle => 'Tema';

  @override
  String get themeProNote => 'Os temas extras fazem parte do Sleepy Capy Pro.';

  @override
  String themeProLabel(String name) {
    return '$name, tema Pro';
  }

  @override
  String get audioChannelName => 'Reprodução de sons';

  @override
  String get reminderChannelName => 'Lembrete de dormir';

  @override
  String get reminderChannelDescription =>
      'Lembrete diário para relaxar e dormir';

  @override
  String get reminderNotificationTitle => 'Hora do capi-cochilo!';

  @override
  String get reminderNotificationBody =>
      'Hora do capi-cochilo! Vamos ficar quentinhos e com soninho.';

  @override
  String get soundRain => 'Chuva';

  @override
  String get soundRainTent => 'Chuva na barraca';

  @override
  String get soundWaves => 'Ondas';

  @override
  String get soundAirplane => 'Avião';

  @override
  String get soundRiver => 'Rio';

  @override
  String get soundForestRain => 'Chuva na floresta';

  @override
  String get soundCampfire => 'Fogueira';

  @override
  String get soundStream => 'Riacho';

  @override
  String get soundStorm => 'Tempestade';

  @override
  String get soundWinter => 'Inverno';

  @override
  String get soundTrain => 'Trem';

  @override
  String get soundCatPurring => 'Gato ronronando';

  @override
  String get soundBirds => 'Pássaros';

  @override
  String get soundCrickets => 'Grilos';

  @override
  String get soundWind => 'Vento';

  @override
  String get soundChimes => 'Sinos de vento';

  @override
  String get soundClock => 'Relógio';
}
