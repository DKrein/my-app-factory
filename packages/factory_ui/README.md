# factory_ui

Tema, tokens visuais e poucos componentes compartilhados pelos apps da fábrica. Depende só do Flutter e do `factory_core`: não conhece anúncios, compras nem telas de um app.

## O que tem aqui

| Item | Para que serve |
| --- | --- |
| `FactoryPalette` | As cores de um tema (ver abaixo). |
| `factoryDarkTheme(palette)` | O `ThemeData` do app para uma paleta. |
| `FactorySpacing` | Escala de espaçamento (`xs` 4, `sm` 8, `md` 12, `lg` 16, `xl` 24, `xxl` 32). |
| `AboutScreen`, `CreditsScreen` | Tela Sobre e créditos. Não têm texto próprio: recebem tudo por `AboutLabels`, e abrem links por um callback do app. |

## Como os temas funcionam

Uma **paleta** (`FactoryPalette`) é um conjunto fixo de 10 cores com nome e `id`. Ela vai dentro do `ThemeData` como *theme extension*, e é assim que qualquer widget a encontra:

```dart
// dentro de um build (ou de um método de State)
final palette = context.palette;          // o mesmo que FactoryPalette.of(context)
Container(color: palette.surface, child: Text('oi', style: TextStyle(color: palette.ink)));
```

Trocar de tema é só entregar outra paleta ao `MaterialApp`:

```dart
MaterialApp(theme: factoryDarkTheme(FactoryPalette.amberEmber), ...)
```

O `MaterialApp` anima a troca (a extensão sabe interpolar cores), e tudo que usa `context.palette` se refaz sozinho.

**Regra do projeto: nenhuma tela usa cor fixa.** Sempre `context.palette.algo`. Como a cor depende do tema, ela não é constante: o `const` sai do widget que a usa. As únicas exceções aceitas são `Colors.transparent` e as estrelas do fundo, que são brancas em todos os temas.

### Os 10 tokens

| Token | Papel |
| --- | --- |
| `night` | Fundo da tela. A cor mais escura. |
| `surface` | Cards e itens sobre o `night`. |
| `surfaceElevated` | Folhas, diálogos, chips e o que fica acima do `surface`. |
| `moon` | Acento secundário: botão principal, links, duração selecionada. |
| `mist` | Acento principal: ícones dos sons, sliders, botões de ação. O texto sobre ele usa `night`. |
| `ink` | Texto principal. |
| `mutedInk` | Texto secundário e ícones discretos. |
| `outline` | Bordas de cards, chips e campos. |
| `activeSurface` | Fundo do card selecionado ou tocando. |
| `activeOutline` | Borda do card selecionado ou tocando. |

O separador (`divider`) não é um token editável: é branco a 8%, igual em todas as paletas.

### Paletas que já existem

`capyNight` (a padrão), `amberEmber` (âmbar, sem azul nenhum, para menos luz azul à noite), `mossForest` e `plumDusk`. A lista, na ordem em que um seletor deve mostrá-las, é `FactoryPalette.all`. `FactoryPalette.byId(id)` procura pelo `id` e cai na `capyNight` se ele não existir mais.

## Como criar uma paleta nova

1. Em `lib/src/palette.dart`, declare um `static const` novo, com o `id` (minúsculas com `_`) e o `name`. **O `id` é o que fica gravado no aparelho: depois de publicado, nunca mude.**
2. Preencha os 10 tokens partindo da `capyNight`, mantendo o papel de cada um. Todas as paletas são escuras (o app é usado na cama).
3. Acrescente a paleta a `FactoryPalette.all`.
4. Rode `flutter test` neste pacote. `test/palettes_test.dart` mede o contraste (WCAG) de cada paleta e falha dizendo qual par ficou baixo:
   - texto (`ink` e `mutedInk` sobre `night`, `surface`, `surfaceElevated`, `activeSurface`; `mist` e `moon` sobre o fundo; `night` sobre `mist` e `moon`): **4,5:1**;
   - borda do card ativo sobre o `activeSurface`: **3:1**;
   - `outline` sobre `night`: **2:1** (é só decoração).
5. Atualize o teste "the shipped palettes keep their ids" e, no app, decida se a paleta é grátis ou Pro (no Sleepy Capy, em `ProFeatures.canUseTheme`). O seletor de Configurações lista `FactoryPalette.all` sozinho.

## Testes

`flutter test` neste diretório. Os de paleta garantem contraste, ids únicos, a interpolação e que o `ThemeData` leva as cores certas.
