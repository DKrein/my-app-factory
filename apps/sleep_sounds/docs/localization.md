# Idiomas do Sleepy Capy

O app fala inglês (padrão e reserva) e português. Ele segue o idioma do aparelho; qualquer outro idioma cai no inglês.

## Como funciona

- Os textos ficam em `lib/l10n/app_en.arb` (modelo) e `lib/l10n/app_pt.arb`. O `flutter gen-l10n` (configurado em `l10n.yaml`, e rodado sozinho em `flutter run`, `build` e `test`) gera as classes `AppLocalizations` na mesma pasta. Os arquivos gerados são versionados.
- Em uma tela: `context.l10n.nomeDaChave` (`lib/l10n/l10n.dart`). Textos com valores são funções: `context.l10n.statusStoppingIn(remaining)`.
- Os **nomes dos sons** também são traduzidos: `soundName(context.l10n, sound)`. O catálogo (`content/sounds.dart`) guarda só o `id`, o arquivo e o ícone.
- Os componentes de `factory_ui` não têm texto: recebem tudo por parâmetro (por exemplo `AboutLabels`). Não há localização dentro de pacotes.

## Onde não há `BuildContext`

Notificações e canais do Android (o lembrete de dormir, a notificação de reprodução e o nome dos canais) são criados fora de uma tela. Elas usam `deviceL10n()`, que resolve o idioma do aparelho da mesma forma que o app. O nome de um canal de notificação, uma vez criado, o Android não muda: quem trocar de idioma depois vê o nome antigo do canal.

## Para acrescentar ou mudar um texto

1. Acrescente a chave em `app_en.arb`, com `@chave` descrevendo os parâmetros (`{"placeholders": {"n": {"type": "int"}}}`), e a tradução em `app_pt.arb`.
2. Use `context.l10n.chave` na tela.
3. `flutter test` confere: `test/l10n_test.dart` falha se faltar chave em um dos arquivos ou se os parâmetros diferirem, e `test/no_hardcoded_text_test.dart` falha se aparecer texto em inglês escrito direto no código. Só números com unidade ("15 min") passam.

## Para acrescentar um idioma

1. Crie `lib/l10n/app_xx.arb` com todas as chaves (o `l10n_test` lista as que faltam).
2. Inclua o idioma no teste de paridade e acrescente um teste da tela nesse idioma.
3. Traduza também a ficha da loja (`docs/store-checklist.md`).

## Decisões

- **Tom do português:** informal, tratando por "você" ("Escolha um som para tocar", "Valeu!").
- **Nomes dos temas** (Capy Night, Amber Ember...) e o nome do app não são traduzidos: são nomes próprios.
- **Formato de hora:** segue a configuração de 12 ou 24 horas do aparelho (no Brasil, normalmente 24 h).
- **Duração no carrossel** ("15m", "1h", "2h 30m") é igual nos dois idiomas. Só o "Off" vira "Desl.".
- **E-mail de feedback:** as linhas técnicas do corpo ("App:", "Platform:") ficam em inglês, porque quem lê é o desenvolvedor.
