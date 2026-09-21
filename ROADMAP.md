# Roadmap da App Factory

## Fase 0 — Decisões e documentação (agora)

- [x] Definir escopo, princípios e não objetivos.
- [x] Escolher Flutter como stack inicial.
- [x] Definir monorepo com apps independentes e pacotes opcionais.
- [x] Definir configuração por app e separação de segredos.
- [ ] Escolher package namespace, conta Play, política de privacidade e app piloto.

**Saída:** documentos revisados e decisões pendentes resolvidas. Não há código nesta fase.

## Fase 1 — Fundação mínima

Construir somente o necessário para um primeiro app offline:

- projeto `apps/_template` compilável;
- `factory_core`, `factory_ui`, `factory_storage` e navegação mínima;
- convenções de lint, formatação, testes e CI;
- configuração manual por `app.yaml`, inicialmente validada de maneira simples;
- um app piloto (recomendado: Sleep Sounds) com APK de teste.

**Critério de saída:** criar e buildar um segundo app offline a partir do template exige apenas configuração, telas/conteúdo próprios e nenhuma cópia de infraestrutura interna.

## Fase 2 — Monetização opt-in

- [x] `factory_ads` com AdMob, consentimento/política aplicável, unidades de teste e placements explícitos;
- [x] `factory_billing` com compra não consumível, restauração e entitlement `remove_ads`;
- [x] cenários de erro/pending purchase e testes manuais em faixa interna do Google Play;
- [x] documentação de configuração do Play Console por app.

**Não incluir ainda:** assinaturas, paywalls universais ou configuração remota. Validar antes uma compra única real em um app.

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
