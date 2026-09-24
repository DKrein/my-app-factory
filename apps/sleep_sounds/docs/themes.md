# Temas do Sleepy Capy

Como o app escolhe, guarda e aplica o tema. O mecanismo das paletas (tokens, como criar uma nova) está em `packages/factory_ui/README.md`.

## Quais temas existem

| Tema | `id` | Quem usa |
| --- | --- | --- |
| Capy Night | `capy_night` | Todos. É o único grátis e o padrão. |
| Amber Ember | `amber_ember` | Pro |
| Moss Forest | `moss_forest` | Pro |
| Plum Dusk | `plum_dusk` | Pro |

A regra "só a Capy Night é grátis" vive em um lugar só: `ProFeatures.canUseTheme` (`lib/features/pro/pro_features.dart`). Nenhuma tela decide isso sozinha.

## Como a escolha é guardada e aplicada

- **`ThemeController`** (`lib/features/theme/theme_controller.dart`) guarda só a escolha, como o `id` da paleta, na chave **`theme_v1`** do `factory_storage`. Um `id` que não existe mais volta como Capy Night.
- **`SleepSoundsApp`** (`lib/main.dart`) decide a paleta que é de fato desenhada (`_palette`): a escolhida, **a menos que ela exija Pro e o usuário não tenha Pro**, caso em que mostra a Capy Night. Ela reconstrói o `MaterialApp` quando muda a escolha, o Pro ou o estado da loja.
- **Se o Pro acabar** (reembolso, por exemplo), o app volta para a Capy Night, mas **a escolha continua gravada**: se o Pro voltar, o tema volta junto.
- **Antes de a loja responder**, o app mostra a paleta gravada (senão quem é Pro veria a Capy Night piscar a cada abertura). Assim que a loja responde e o usuário não é Pro, ele passa para a Capy Night.
- **Estrelas do fundo:** brancas em todos os temas (`StarfieldBackground`), só a cor de base segue a paleta.

## O seletor

Fica em Configurações, logo abaixo do card do Pro (`lib/features/theme/theme_picker.dart`). Mostra uma amostra por paleta com as próprias cores dela (fundo, card, acento) e o nome. A paleta em uso tem um visto. Sem Pro, as três extras mostram um cadeado, e tocar em uma abre o paywall, sem mudar o tema. Com Pro, tocar aplica e grava na hora.

A lista vem de `FactoryPalette.all`, então uma paleta nova aparece no seletor sem mexer nele.

## Para acrescentar uma paleta

1. Crie a paleta e cumpra o contraste, como descrito em `packages/factory_ui/README.md`.
2. Ela já aparece no seletor. Decida em `ProFeatures.canUseTheme` se é grátis ou Pro (hoje: só a Capy Night é grátis).
3. Atualize o texto do ADR 0002 se a lista de temas grátis mudar.

## Limitação conhecida

A splash nativa do Android (a tela que aparece antes de o Flutter iniciar) usa sempre o azul da Capy Night (`flutter_native_splash`, cor `0B1020`). Quem usa outro tema vê esse azul por uma fração de segundo ao abrir. Trocar isso exigiria gerar a splash por tema, o que o Android não faz em tempo de execução.
