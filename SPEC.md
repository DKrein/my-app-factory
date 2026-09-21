# App Factory — Especificação Técnica

## 1. Propósito

Esta fábrica é uma base reutilizável para publicar vários aplicativos Android pequenos, sem transformar o projeto em uma plataforma genérica difícil de manter. Ela separa:

- **infraestrutura reutilizável**: UI, persistência, navegação, monetização e integrações;
- **aplicativo**: identidade, telas, conteúdo e regras específicas;
- **configuração**: quais capacidades cada aplicativo usa e os identificadores externos necessários.

O alvo inicial é Android. Os aplicativos devem poder funcionar offline quando sua natureza permitir e não devem depender de backend, analytics, anúncios ou pagamentos por padrão.

## 2. Princípios e não objetivos

### Princípios

1. Simples para uma pessoa manter.
2. Offline-first; rede é uma dependência explícita, nunca implícita.
3. Cada app compila somente as integrações que usa.
4. APIs pequenas, orientadas a casos de uso, escondem SDKs de terceiros.
5. Configuração e segredos são distintos.
6. Preferir convenções a abstrações genéricas.
7. Um aplicativo pode divergir da base quando isso reduz complexidade; não há obrigação de reutilizar tudo.

### Não objetivos da primeira versão

- sistema de plugins carregados em runtime;
- marketplace interno de módulos;
- backend compartilhado, painel administrativo ou autenticação;
- suporte a iOS, embora a escolha tecnológica o preserve como opção;
- multi-tenant, sincronização entre dispositivos ou experimentos A/B;
- uma DSL que descreva telas ou aplicativos inteiros;
- pagamentos por Stripe: compras digitais no Android usam Google Play Billing.

## 3. Stack recomendada

**Recomendação: Flutter + Dart, Material 3, pacotes Flutter e projetos Android padrão gerados pelo Flutter.**

O Flutter é a melhor escolha para este objetivo específico: há alta reutilização de UI e lógica entre apps, ciclo de criação rápido para um desenvolvedor solo e uma rota futura razoável para iOS sem manter uma segunda base de telas. AdMob, Google Play Billing, notificações e Firebase possuem integrações Flutter maduras; quando necessário, código nativo Kotlin pode ser isolado atrás de um pacote.

| Critério | Flutter (recomendado) | Kotlin + Jetpack Compose | React Native |
| --- | --- | --- | --- |
| Apps Android pequenos em série | Muito rápido; uma UI reutilizável por pacote | Excelente qualidade nativa, mas maior custo para iOS | Rápido para quem já domina JS/TS |
| Reuso e monorepo | Dart packages tornam módulos claros | Ótimo com módulos Gradle, mais verboso | Bom com packages, sujeito a dependências nativas JS |
| Codex/Claude Code | Código declarativo, hot reload e testes simples; diagnóstico via `flutter` | Excelente integração com APIs Android e Gradle, porém mais arquivos/configuração | Bom, mas a ponte JS/nativo e upgrades de dependências aumentam o contexto |
| AdMob e Billing Android | Integrações disponíveis; encapsular SDKs é importante | Caminho oficial e menor camada extra | Disponível, geralmente com mais variabilidade entre bibliotecas |
| Offline, áudio, desenho e puzzles | Adequado para todos os exemplos | Excelente, especialmente para APIs Android específicas | Adequado, mas menos natural para gráficos/interações intensas |
| Manutenção solo | Uma linguagem e potencial iOS | Melhor se Android for definitivamente o único alvo | Ecossistema com maior risco de churn |
| Futuro iOS | Forte vantagem | Exige reescrita de UI/lógica de apresentação | Bom, mas não é prioridade e tem custo nativo semelhante |

### Quando escolher Kotlin em vez disso

Kotlin + Compose seria preferível se a decisão fosse “Android para sempre”, se integrações nativas complexas (serviços em foreground, wearables, widgets ou APIs de áudio muito específicas) dominassem o produto, ou se já houvesse forte experiência Kotlin. Não é a recomendação inicial porque o objetivo enfatiza velocidade entre vários apps e possibilidade futura de iOS.

### Convenções iniciais

- Flutter stable e Dart compatível com a versão estável adotada pelo repositório.
- Material 3, tema próprio mínimo e componentes de `factory_ui`.
- Gerência de estado por feature com `ChangeNotifier`/`ValueNotifier` inicialmente; introduzir Riverpod somente quando um app tiver estado compartilhado assíncrono ou múltiplas dependências que justifiquem.
- Rotas nomeadas simples ou `go_router` apenas no pacote de navegação quando houver mais de poucas telas/deep links.
- Testes unitários para regras e testes de widget para fluxos críticos. Testes de integração apenas para compra/restauração e jornadas de maior risco.

Não fixar versões de dependências neste documento: elas devem ser centralizadas e atualizadas deliberadamente, com builds de exemplo em CI.

## 4. Modelos de monetização

| Modelo | Módulos | Comportamento |
| --- | --- | --- |
| Gratuito offline | nenhum monetizador | Não inicializa SDK de rede; funcionalidades locais disponíveis sem conta. |
| Gratuito com anúncios | `factory_ads` | Anúncios configuráveis por placement; falha de rede não bloqueia o app. |
| Compra única | `factory_billing` | Produtos Play Console mapeados por IDs; direito (entitlement) persistido e restaurável. |
| Assinatura | `factory_billing` | Planos mensal/anual mapeados a direitos Premium; estado vem do Google Play. |
| Híbrido | ads + billing | Um entitlement, por exemplo `remove_ads`, altera a política de exibição. |

O aplicativo específico decide *onde* há anúncio e *o que* uma compra desbloqueia. O módulo de billing não deve conhecer telas, preços, pacotes de conteúdo ou regras de negócio de cada app.

## 5. Analytics e backend

### Analytics (opcional)

Usar Firebase Analytics quando forem necessárias métricas de aquisição, retenção, funil de compra, uso de conteúdo ou medição de anúncios. Para um app simples/offline, manter desligado reduz dependências, coleta de dados, requisitos de privacidade e trabalho de configuração. Um módulo `factory_analytics` expõe apenas eventos de domínio selecionados; Firebase é um adaptador substituível, não uma dependência do core.

Antes de ativá-lo, definir eventos realmente úteis, política de retenção, consentimento quando aplicável, divulgação de dados no Google Play e uma política de privacidade.

### Backend (opcional)

Adicionar somente quando houver uma necessidade impossível ou inconveniente de resolver no dispositivo: catálogo de conteúdo atualizável, sincronização/backup de usuário, contas, conteúdo pago entregue remotamente, recursos sociais, configuração remota, moderação ou processamento pesado. Começar com uma API pequena e um contrato versionado; não criar backend “para o futuro”. Firebase pode ser avaliado nessa fase, mas não deve vazar para o core.

## 6. Critérios de aceite da infraestrutura inicial

1. É possível criar um app Android offline com core, UI, storage e navegação sem dependências de ads, billing, analytics ou backend.
2. É possível criar outro app que inclua ads e billing sem alterar o anterior.
3. Identificadores de AdMob, produtos Play e Firebase não aparecem no código compartilhado.
4. O app compila com uma configuração inválida rejeitada cedo por validação/CI.
5. Uma compra restaurada atualiza os direitos do app e pode remover anúncios.
6. Cada app pode gerar APK/AAB de release com package name, ícone, nome e versionamento próprios.

## 7. Decisões pendentes

- Nome/namespace Android e conta Google Play que publicarão os apps.
- Política de privacidade, consentimento e classificação etária por tipo de app.
- Se conteúdo comum será versionado em pacotes ou copiado para cada app (a recomendação é conteúdo específico permanecer no app).
- Primeiro app piloto: recomenda-se **Sleep Sounds**, por validar offline, storage, áudio e navegação sem misturar monetização na fundação.
- Política de versões: `main` sempre verde; apps publicados recebem tags por app, por exemplo `sleep-sounds-v1.2.0`.
