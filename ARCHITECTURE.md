# Arquitetura da App Factory

## Visão geral

O repositório será um monorepo Flutter leve. Um app é um executável Flutter independente que importa pacotes compartilhados locais. Pacotes opcionais são dependências estáticas: se o app não declara `factory_ads`, o SDK de anúncios não é incluído nem inicializado.

```text
apps/<app>/lib  ──>  packages/factory_ui, factory_core, feature packages
       │                         │
       ├────> packages/factory_ads (somente se selecionado)
       ├────> packages/factory_billing (somente se selecionado)
       └────> pacotes externos / integrações nativas
```

Não usar módulos descarregáveis, reflexão, injeção de dependência pesada ou feature flags remotas para decidir se um SDK existe. Isso encarece builds e torna privacidade, depuração e testes menos previsíveis.

## Estrutura proposta

```text
my-app-factory/
├── apps/
│   ├── _template/                 # molde mínimo, não publicado
│   └── sleep_sounds/              # cada app tem pubspec e android próprios
│       ├── app.yaml               # fonte de configuração não secreta
│       ├── lib/
│       │   ├── main.dart
│       │   ├── app.dart
│       │   ├── app_config.g.dart  # gerado; não editar manualmente
│       │   ├── features/          # lógica e telas exclusivas do app
│       │   └── content/           # catálogo/conteúdo exclusivo do app
│       ├── assets/
│       ├── android/
│       └── test/
├── packages/
│   ├── factory_core/              # erros, resultados, contratos e utilitários mínimos
│   ├── factory_ui/                # tema, componentes e tokens visuais
│   ├── factory_navigation/        # interface/implementação de rotas, quando necessária
│   ├── factory_storage/           # key-value, arquivos e migrations locais
│   ├── factory_audio/             # contratos e implementação de áudio
│   ├── factory_ads/               # AdMob atrás de AdsGateway
│   ├── factory_billing/           # Play Billing atrás de BillingGateway
│   ├── factory_analytics/         # AnalyticsSink e adaptador Firebase opcional
│   ├── factory_notifications/     # notificações locais/push, futuramente
│   └── factory_api/               # cliente HTTP e contratos, somente se necessário
├── tooling/
│   ├── app_factory/               # CLI futura: criar/validar configuração
│   └── templates/
├── docs/
│   ├── adr/                       # decisões que mudam a arquitetura
│   └── runbooks/                  # publicação, credenciais e incidentes
├── SPEC.md
├── ARCHITECTURE.md
└── ROADMAP.md
```

`factory_audio` e um futuro `factory_drawing` não devem tentar resolver toda classe de app. Eles devem fornecer primitivas reutilizáveis; a experiência do produto fica em `apps/<app>/lib/features`.

## Responsabilidades e dependências

| Camada | Pode depender de | Não deve depender de |
| --- | --- | --- |
| App | core, UI, módulos selecionados, suas features | outro app |
| Feature do app | core, UI, contratos de módulos | SDKs externos diretamente |
| Módulo de integração | core e SDK específico | UI/telas de um app |
| UI | core e Flutter | ads, billing, Firebase, backend |
| Core | Dart/Flutter mínimo | Firebase, AdMob, Billing, pacote de feature |

O sentido das dependências é sempre do app para a infraestrutura. Nenhum pacote compartilhado deve importar `apps/`.

**Cores e tema.** As cores de uma tela vêm da paleta do tema (`FactoryPalette`, em `factory_ui`), lida com `context.palette`. Nenhuma tela usa cor fixa. Trocar de tema é passar outra paleta ao `MaterialApp`. As regras e o passo a passo para criar uma paleta estão em `packages/factory_ui/README.md`.

## Comunicação entre módulos

Módulos se comunicam por contratos Dart pequenos, injetados no ponto de composição (`main.dart`/`app.dart`) do aplicativo.

Exemplo conceitual:

```text
Feature de tela ──usa──> BillingGateway (contrato)
                                  ▲
                       PlayBillingGateway (factory_billing)
```

- Retornos assíncronos usam tipos explícitos de sucesso/erro ou exceções normalizadas do core.
- Eventos de domínio são poucos e tipados, por exemplo `purchase_completed` ou `sound_started`; analytics pode observá-los se ativado.
- Não usar um event bus global como canal principal: ele oculta fluxo e dificulta testes.
- O estado pertence à feature que o produz. Somente estado verdadeiramente compartilhado (tema, direitos Premium, configuração) sobe para o nível do app.
- Ads recebe uma `AdsPolicy` do app e billing expõe `Entitlements`; o app conecta ambos. Assim, `factory_ads` não depende de billing.

## Configuração por aplicativo

`apps/<app>/app.yaml` é a fonte de verdade para dados não secretos e seleção de módulos. A CLI de fábrica (fase posterior) valida o arquivo e gera os artefatos repetitivos: `pubspec.yaml` com dependências locais selecionadas, `app_config.g.dart` tipado e partes previsíveis da configuração Android. Arquivos gerados são revisáveis e não contêm segredos.

Exemplo:

```yaml
app:
  id: com.example.sleepsounds
  name: Sleep Sounds
  version: 1.0.0+1
  support_email: support@example.com
  privacy_policy_url: https://example.com/privacy

modules:
  ui: true
  navigation: true
  storage: true
  audio: true
  ads: false
  billing: false
  analytics: false
  backend: false

monetization:
  ads:
    enabled: false
  billing:
    products: []
```

`support_email` e `privacy_policy_url` são dados públicos exigidos pela ficha da loja e pela tela "Sobre" do app; não são segredos e por isso ficam no `app.yaml` como qualquer outro campo de identidade.

Para um app com monetização, IDs públicos (por exemplo, ad unit IDs e product IDs) podem constar no YAML ou em uma configuração de ambiente não secreta. **Segredos** (keystore, token de serviço, chave de API privada) nunca entram no YAML nem no Git: ficam no cofre/CI e em arquivos locais ignorados pelo Git. Firebase usa o arquivo por plataforma tratado conforme o procedimento oficial e os requisitos do projeto.

Configuração de build (dev/staging/prod) deve usar variantes Flutter/Android somente quando realmente houver diferenças de ambiente, como ad unit de teste versus produção. Não criar uma matriz de flavors para cada combinação de módulo.

## Criação de um novo app

Fluxo-alvo:

1. Executar a futura CLI `create-app` a partir de um identificador e um conjunto de módulos, ou copiar `apps/_template` enquanto a CLI não existir.
2. Preencher `app.yaml`: identidade, versão, módulos e IDs públicos.
3. Rodar `validate-app`/CI, que confere combinações (por exemplo, produtos sem billing) e gera/sincroniza artefatos.
4. Implementar somente `lib/features`, `content`, assets e testes daquele app.
5. Executar builds debug e release do diretório do app; publicar o AAB gerado.

A CLI deve ser um acelerador, não uma condição para entender ou editar um aplicativo. Todo app resultante precisa continuar um projeto Flutter legível e compilável por comandos padrão.

## Monetização: desenho de contratos

`factory_billing` mantém a conexão, consulta de produtos, compra, restauração e estado de direitos. O app fornece um catálogo declarativo que mapeia IDs Play para direitos, por exemplo `remove_ads` ou `premium`.

`factory_ads` recebe placements e uma política de elegibilidade. Exemplo: `showBanner = !entitlements.has('remove_ads')`. O módulo nunca decide sozinho que uma compra remove anúncios.

Para assinaturas, o app deve tratar compra pendente, cancelamento, expiração, restauração e indisponibilidade de loja. A primeira versão pode confiar no estado retornado pela Play Store no dispositivo; validação no servidor só se torna necessária quando houver conteúdo/benefícios remotos de alto valor ou risco de fraude relevante.

## Build, qualidade e manutenção

- Um único arquivo de versões/constraints e automação de análise, testes e build para todos os apps selecionados.
- CI mínimo: format, analyze, test dos pacotes alterados e build Android de pelo menos template + app piloto.
- Cada pacote expõe uma API pública pequena; mudanças incompatíveis exigem atualização coordenada dos apps ou versionamento explícito.
- Registrar decisões duradouras em `docs/adr/`, não em comentários soltos.
- Atualizar plugins Flutter, Android Gradle Plugin e SDKs de monetização de forma programada; não misturar grandes upgrades com features de produto.

## Limites deliberados

Evitar um “design system universal” antes de dois ou três apps reais evidenciarem padrões. Começar por tokens (cores, tipografia, espaçamento) e poucos componentes. Evitar também um pacote `factory_features` genérico: funcionalidades são reutilizadas somente depois de existirem em pelo menos dois apps com necessidades semelhantes.
