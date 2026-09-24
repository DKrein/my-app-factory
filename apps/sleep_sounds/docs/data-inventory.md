# Inventário de dados do Sleepy Capy

Base para a seção "Segurança dos dados" da Play Console e para a política de privacidade. Levantado em 2026-09-24 a partir do **build release** (`flutter build apk --release`), do manifest mesclado e das dependências. Se uma dependência ou permissão mudar, refaça este documento.

## Resumo

- Não há conta, login, servidor próprio, analytics nem relatório de falhas.
- Tudo que o usuário cria (sessão, mixes, tema, lembrete) fica **só no aparelho**.
- O único código que fala com a internet e coleta dados é a **SDK de anúncios (AdMob)**, e só para quem **não** é Pro, depois do consentimento onde a lei exige.
- Compras passam pelo Google Play. O app não vê dado de pagamento.

## Aplicativo

| Item | Valor |
| --- | --- |
| ID do aplicativo (`applicationId`) | `com.douglaskrein.sleepsounds` |
| Versão | `2026.9.22` (código 1) |
| `minSdk` / `targetSdk` | 24 / 36 |
| Tamanho do APK release universal | 74,3 MB (o AAB entregue pela loja é menor: cada aparelho baixa só a sua arquitetura) |

## Permissões do manifest mesclado (release)

O manifest do app declara só as cinco primeiras. As demais chegam pelas bibliotecas.

| Permissão | Para que serve | Origem |
| --- | --- | --- |
| `WAKE_LOCK` | Manter o som tocando com a tela apagada. | App |
| `FOREGROUND_SERVICE` | Serviço de reprodução em primeiro plano. | App |
| `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | Tipo do serviço: reprodução de mídia. | App |
| `POST_NOTIFICATIONS` | Notificação de reprodução e lembrete de dormir. Pedida em tempo de execução. | App |
| `RECEIVE_BOOT_COMPLETED` | Reagendar o lembrete de dormir depois de reiniciar o aparelho. | App |
| `INTERNET` | Baixar anúncios. | `play-services-ads-api`, `play-services-measurement-sdk-api` e `transport-backend-cct` (todos da pilha do AdMob) |
| `ACCESS_NETWORK_STATE` | Saber se há rede. | Pilha do AdMob e `work-runtime` |
| `com.google.android.gms.permission.AD_ID`, `ACCESS_ADSERVICES_AD_ID`, `ACCESS_ADSERVICES_ATTRIBUTION`, `ACCESS_ADSERVICES_TOPICS` | ID de publicidade e APIs de anúncios do Android. | `play-services-ads-api` e `play-services-ads-identifier` |
| `com.android.vending.BILLING` | Compra do Pro. | `billing` (Play Billing) |
| `VIBRATE` | Vibração da notificação. | `flutter_local_notifications` |
| `<pacote>.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | Proteção interna do AndroidX. | AndroidX |

**Conclusão sobre `INTERNET`:** ela vem só da pilha de anúncios. O áudio toca de arquivos dentro do app, as compras falam com o app da Play Store e os links abrem no navegador. Sem anúncios, o app não precisaria de `INTERNET`.

**Não há** `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, alarme exato, localização, contatos, câmera, microfone nem armazenamento. Um teste (`test/manifest_test.dart`) falha se algo disso aparecer no manifest do app.

### Serviço em primeiro plano (declaração da Play Console)

- Serviço: `com.ryanheise.audioservice.AudioService`, com `foregroundServiceType="mediaPlayback"`.
- Função: tocar os sons de ambiente enquanto o usuário dorme, com a tela apagada. É iniciado pelo usuário ao apertar play e some quando o som para (timer ou pausa).
- A Play Console pede a declaração do tipo `mediaPlayback` para `FOREGROUND_SERVICE_MEDIA_PLAYBACK`. Confira na hora do envio se ela pede um vídeo de demonstração.

## O que o app grava no aparelho

Tudo em `SharedPreferences` (armazenamento privado do app), pelo `factory_storage`. Nada sai do aparelho por conta do app.

| Chave | Conteúdo |
| --- | --- |
| `last_session_v1` | Sons selecionados, volume de cada um e a duração do timer da última sessão. |
| `timer_options_v1` | Fade gradual (ligado ou não, quantos minutos) e a última duração personalizada. |
| `saved_mixes` | Os mixes salvos: nome dado pelo usuário, sons, volumes e timer opcional. |
| `theme_v1` | O `id` do tema escolhido. |
| `bedtime_reminder_enabled_v1`, `bedtime_reminder_time_v1` | Se o lembrete de dormir está ligado e a que horas. |

Além disso o Android guarda o agendamento do lembrete. O `allowBackup` não foi alterado, então o Android pode incluir esses dados na cópia de segurança do aparelho do usuário (Google), sem passar pelo app.

O Pro **não** é gravado no aparelho: é perguntado à Play a cada abertura (restauração silenciosa das compras).

## O que sai do aparelho

| Destino | Quando | O que | Quem |
| --- | --- | --- | --- |
| **Google AdMob** | Só sem Pro, depois do consentimento (UMP) onde exigido, e só nas telas com banner | Pedidos de anúncio e dados que a SDK coleta (ID de publicidade, IP, dados do aparelho, interação com o anúncio, diagnósticos) | Google |
| **Google Play Billing** | Ao comprar, restaurar ou abrir o app | Consulta de compras e do produto, feita pelo app da Play Store | Google |
| **Google Play (avaliação)** | Ao tocar em "Rate Sleepy Capy" | Abre a página do app na loja | Google |
| **Navegador e e-mail** | Ao tocar em política de privacidade, créditos ou contato | Abre o link ou o e-mail no app do usuário | Terceiros, fora do app |

**Com o Pro,** a SDK de anúncios **nunca é iniciada**: a cobrança abre primeiro, e o provider de inicialização automática foi removido do manifest.

## Dependências que acessam a rede ou coletam dados

| Pacote | Faz o quê | Coleta? |
| --- | --- | --- |
| `google_mobile_ads` | Anúncios e consentimento (UMP) | **Sim** (ver acima) |
| `in_app_purchase` | Compras pelo Google Play | Não pelo app; a Play trata |
| `in_app_review` | Abre a página do app na Play | Não |
| `url_launcher` | Abre links e e-mail em outros apps | Não |
| `just_audio`, `audio_service`, `audio_session` | Tocam áudio de arquivos locais | Não |
| `flutter_local_notifications`, `timezone` | Lembrete local | Não |
| `shared_preferences` | Guarda as chaves acima | Não sai do aparelho |
| `app_settings` | Abre a tela de configurações do Android | Não |

**Não há** Firebase, analytics, crash reporting nem SDK de terceiros além do AdMob.

## O que a política de privacidade precisa dizer

O texto novo, em EN e PT, está em `privacy-policy.md`. Ele cobre esta lista; confira contra ela:

1. Quem é o desenvolvedor e como falar com ele (`contact@douglaskrein.com`).
2. Que não há conta nem coleta de dados pelo app; o que o usuário cria fica no aparelho.
3. **Anúncios:** o app mostra banners com o Google AdMob para quem não é Pro. Que o AdMob pode coletar o ID de publicidade, o endereço IP, dados do aparelho e a interação com os anúncios, e pode usar isso para personalizar anúncios; como o usuário controla isso (o formulário de consentimento onde aplicável, e as configurações de anúncios do Android); link para a política do Google.
4. **Compras:** o Pro é uma compra única pelo Google Play; o app não vê dado de pagamento; a Play trata os pagamentos.
5. **Notificações:** o lembrete de dormir é local, opcional, e o usuário pode desligar.
6. Que o app **não é voltado para crianças**.
7. Que os dados do app (sessão, mixes, tema) podem entrar na cópia de segurança do Android do usuário.
8. Como o usuário apaga tudo: desinstalar o app; o ID de publicidade se redefine nas configurações do Android.
9. Data da última atualização.

## Pendências e decisões abertas

- **`applicationId` é permanente depois da publicação.** Hoje é `com.douglaskrein.sleepsounds`, enquanto a convenção do projeto é `com.douglaskrein.[app_name]` e o namespace do código é `com.douglaskrein.sleep_sounds`. Confirme qual vale **antes** do primeiro envio.
- **Assinatura:** não existe keystore. Sem `android/key.properties`, o build release cai na chave de debug, e a Play Console rejeita esse pacote. Crie a chave de envio fora do Git (`*.keystore` e `key.properties` já estão no `.gitignore`).
- **IDs reais do AdMob:** o app e as duas telas usam hoje os IDs de teste do Google. Crie o app e **duas unidades de banner** (grade e Configurações) e troque em `app.yaml`, no `AndroidManifest.xml` (`APPLICATION_ID`) e no `AppConfig`.
