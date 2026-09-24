# ADR 0002: Compra única em vez de assinatura

- Status: aceita
- Data: 2026-09-24
- App: `apps/sleep_sounds`

## Contexto

O Sleepy Capy ainda não foi publicado, então não há compradores nem SKU legado. Um app de sons para dormir é usado em sessões longas e repetidas, mas o valor que entrega não muda de mês a mês: o catálogo é fixo e curado (ver ADR 0003) e tudo roda offline. Uma assinatura cobraria de novo por algo que já existe.

## Decisão

- **Compra única, não assinatura.** Produto não consumível `sleep_sounds_pro`, que concede o entitlement `pro`. O `factory_billing` continua genérico e não conhece esse nome.
- **Preço:** US$ 4,99, com preços regionais ativados no Play Console. O app mostra o preço que a loja devolve. O valor `$4.99` no código é só o fallback de preview e de testes.
- **O Pro cobra por capacidade, não por conteúdo.** Nenhum som fica trancado, e nada que é grátis hoje passa para trás do paywall.

| Grátis | Pro |
| --- | --- |
| Os 17 sons, mixagem, timer (Off, 15m a 12h), 1 mix salvo, lembrete de dormir, restaurar a última sessão, tema atual | Volume individual por som, mixes salvos ilimitados, timer com fade gradual, duração personalizada e "parar às HH:MM", temas extras (ver `themes.md`), sem anúncios |
| Banner apenas na grade e em Configurações | Nenhum SDK de anúncio inicializado |
| 1 mix salvo | Mixes salvos ilimitados |

- **Uma única fonte da decisão:** `ProFeatures` (`lib/features/pro/pro_features.dart`). Telas e regras perguntam a ele, e ninguém confere o entitlement direto.
- **Proibido:** paywall na abertura, durante a reprodução, contagem regressiva, preço riscado falso, e pedido de avaliação junto ao paywall. O paywall abre só por um cadeado numa função Pro ou pelo item em Configurações.
- **Anúncios:** só banner, sem interstitial nem rewarded em nenhuma hipótese.

## Consequências

- Receita depende de conversão única, sem recorrência. Compensa não ter cancelamento, expiração nem renovação para tratar.
- O estado da compra vem do dispositivo (Play Billing). Não há validação em servidor nesta versão, o que é aceitável para um produto de US$ 4,99 sem conteúdo remoto.
- Trocar para assinatura no futuro exigiria um novo SKU, e quem já comprou o Pro teria de ser respeitado.

## Anúncios: como isso é garantido no código

- A cobrança abre primeiro e restaura em silêncio o que o usuário já comprou (a loja só informa as compras quando perguntada, e os direitos ficam em memória). Só depois, se o usuário não é Pro, a SDK de anúncios é iniciada, já com o fluxo de consentimento (UMP) onde a lei exige.
- O manifest remove o `MobileAdsInitProvider`, que iniciaria a SDK sozinha na abertura. Sem isso, o Pro teria a SDK ativa mesmo sem o app pedir.
- Um banner só é construído depois que a SDK está pronta. Se o anúncio falha ou nunca chega, o espaço reservado é zero.
- Só existem dois posicionamentos: `bannerHome` (na grade) e `bannerSettings` (em Configurações). Um teste varre o código e falha se aparecer interstitial, rewarded ou outro posicionamento.
- As duas telas usam hoje a mesma unidade de anúncio. Crie unidades separadas no AdMob antes da publicação.
