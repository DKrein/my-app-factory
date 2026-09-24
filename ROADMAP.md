# Roadmap da App Factory

## Fase 0 — Decisões e documentação (agora)

- [x] Definir escopo, princípios e não objetivos.
- [x] Escolher Flutter como stack inicial.
- [x] Definir monorepo com apps independentes e pacotes opcionais.
- [x] Definir configuração por app e separação de segredos.
- [x] Escolher o app piloto: Sleep Sounds.
- [x] Definir o package namespace Android: sempre `com.douglaskrein.[app_name]`.
- [ ] Criar a conta de desenvolvedor no Google Play.
- [ ] Publicar a política de privacidade em uma URL pública.

**Saída:** documentos revisados e decisões pendentes resolvidas. Não há código nesta fase.

## Fase 1 — Fundação mínima

Construir somente o necessário para um primeiro app offline:

- [x] projeto `apps/_template` compilável;
- [x] `factory_core`, `factory_ui` e `factory_storage`;
- [ ] navegação mínima (`factory_navigation` ainda é um placeholder; os apps usam `Navigator` direto);
- [x] convenções de lint e testes (`tooling/check.sh`);
- [ ] CI que rode o `check.sh` e um build Android;
- [ ] configuração manual por `app.yaml`, inicialmente validada de maneira simples (o arquivo existe, mas nada confere `app.yaml` × Gradle × `app_config.g.dart`);
- [x] um app piloto (Sleep Sounds) com APK/AAB de teste gerado (ainda falta testar em aparelho).

**Critério de saída:** criar e buildar um segundo app offline a partir do template exige apenas configuração, telas/conteúdo próprios e nenhuma cópia de infraestrutura interna.

## Fase 2 — Monetização opt-in

- [x] `factory_ads` com AdMob, consentimento/política aplicável, unidades de teste e placements explícitos;
- [x] `factory_billing` com compra não consumível, restauração e entitlements definidos pelo app (o Sleepy Capy usa `pro`; o pacote não conhece o nome);
- [x] cenários de erro/pending purchase e testes manuais em faixa interna do Google Play;
- [x] documentação de configuração do Play Console por app.

**Não incluir ainda:** assinaturas, paywalls universais ou configuração remota. Validar antes uma compra única real em um app.

**Estado do piloto (Sleepy Capy):** a compra única virou o produto Pro, a US$ 4,99 (ADR 0002 do app), com paywall próprio do app, sem paywall universal. A cobrança restaura as compras em silêncio ao abrir, a SDK de anúncios só inicia para quem não é Pro e o `factory_ads` só constrói banner depois de a SDK estar pronta. Ainda falta validar tudo isso com compra real na faixa interna do Play.

### Sleepy Capy: do código à publicação

O app está completo em código. O que falta é de conta e de loja; o estado de cada item está em `apps/sleep_sounds/docs/store-checklist.md`.

- [x] Correções, reprodução com fade, catálogo revisado (`docs/audio-qa.md`), acabamento visual e créditos de áudio;
- [x] Sleepy Capy Pro: volume por som, mixes salvos, timer Pro, temas, paywall e anúncios só na grade e em Configurações;
- [x] Ícone, splash nativa e inglês/português;
- [x] Inventário de dados e checklist da loja (`data-inventory.md`, `store-checklist.md`) e roteiro de teste em aparelho (`manual-test-plan.md`);
- [ ] Decidir o `applicationId` (permanente depois do envio), criar a chave de envio e os IDs reais do AdMob;
- [ ] Política de privacidade no ar, com as seções de anúncios e compras;
- [ ] Capturas de tela e arte final do ícone (hoje provisórios);
- [ ] Rodar o roteiro de teste em aparelho e a compra na faixa interna;
- [ ] Teste fechado com 12 testadores por 14 dias (conta pessoal nova) e envio para produção.

## Fase 3 — Assinaturas e métricas, se justificadas

- catálogo de assinatura mensal/anual e entitlement Premium;
- lifecycle de assinatura e estados de UX;
- `factory_analytics` somente com um plano de eventos e privacidade;
- validar métricas que orientem uma decisão de produto concreta.

**Critério de entrada:** existir um app cujo valor recorrente justifique assinatura; não adicionar apenas porque o módulo pode existir.

## Fase 4 — Automação de fábrica

- CLI `create-app`, `validate-app` e geração de artefatos previsíveis a partir de `app.yaml`;
- checagem de módulos/configurações incompatíveis;
- automação de builds de release e checklist de publicação.

A CLI entra depois de criar pelo menos dois apps manualmente. Isso evita automatizar prematuramente um fluxo que ainda vai mudar.

## Fase futura — Backend e módulos especializados

Somente guiado por necessidade de um app publicado:

- API/backend para sincronização, catálogo remoto ou contas;
- notificações push;
- desenho/colorir, puzzles e outros módulos específicos;
- iOS, começando por um app com boa validação no Android.

## Riscos e mitigação

| Risco | Impacto | Mitigação |
| --- | --- | --- |
| Abstração cedo demais | Base genérica e lenta de mudar | Extrair módulos de feature somente após dois usos reais. |
| Atualizações de SDK/Flutter | Builds quebrados e dívida de manutenção | Atualizações periódicas pequenas e CI com build Android. |
| Políticas Play/AdMob/privacidade | Rejeição ou atraso de publicação | Checklist por app para Data safety, consentimento, classificação e política de privacidade. |
| Billing mal testado | Perda de receita ou usuários sem acesso | Testar compra, pendência, cancelamento e restore em faixas internas. |
| Monorepo acoplar apps publicados | Regressões entre produtos | APIs pequenas, testes de pacote e tags/releases por app. |
| Muitas combinações de módulos | Explosão de testes | Testar perfis representativos: offline, ads, ads+compra, assinatura. |
| Dependência de backend prematura | Custo e operação contínua | Default offline; aprovar backend com caso de uso, custo e owner claros. |

## Perguntas para a revisão de arquitetura

1. O primeiro app piloto será Sleep Sounds ou há outro com prioridade comercial?
2. Os apps serão publicados sob uma única conta Google Play e um namespace comum?
3. Haverá requisito de idiomas além de português desde o primeiro app?
4. Quais dados, se algum, podem ser coletados por apps com analytics/anúncios?
5. A compra “remover anúncios” será a primeira monetização a validar antes de assinaturas?
