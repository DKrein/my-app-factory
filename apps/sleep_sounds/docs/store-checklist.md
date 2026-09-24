# Checklist de publicação do Sleepy Capy

Tudo que a Play Console pede, com o estado de cada item. Os textos da ficha são **rascunhos** para você revisar. Os números de caracteres foram conferidos contra os limites da Play.

Legenda: ✅ pronto · 🟡 rascunho ou provisório · ⬜ falta fazer · ❓ decisão sua

## 1. Antes de gerar o pacote

| | Item | Detalhe |
| --- | --- | --- |
| ❓ | **ID do aplicativo** | Hoje `com.douglaskrein.sleepsounds`. É **permanente** depois do primeiro envio. A convenção do projeto é `com.douglaskrein.[app_name]`, que daria `sleep_sounds`. Confirme qual vale. |
| ⬜ | **Chave de envio (keystore)** | Não existe. Sem `android/key.properties` o release cai na chave de debug, e a Play rejeita. Crie fora do Git (`*.keystore` e `key.properties` já estão no `.gitignore`). Guarde a chave e a senha com backup: perder a chave complica as atualizações. |
| ⬜ | **IDs reais do AdMob** | Hoje são os de teste do Google. Crie o app no AdMob e **duas unidades de banner** (grade e Configurações). Troque em `app.yaml`, `AndroidManifest.xml` (`APPLICATION_ID`) e `AppConfig`. Publicar com ID de teste não rende nada e a conta pode ser advertida. |
| ⬜ | **`app-ads.txt`** | O AdMob recomenda publicar no site do desenvolvedor (`douglaskrein.com/app-ads.txt`) e informar o site na ficha. |
| ⬜ | **Versão** | `version` no `pubspec.yaml` e no `app.yaml` (hoje `2026.9.22+1`). O número depois do `+` é o `versionCode` e **precisa subir a cada envio**. |
| ⬜ | **Gerar o AAB** | `cd apps/sleep_sounds && ../../.tool/flutter/bin/flutter build appbundle --release` (com o JDK do projeto: `export JAVA_HOME=/home/dodo/projects/my-app-factory/.tool/jdk`). |
| ✅ | `targetSdk` 36, `minSdk` 24 | Atende à exigência atual da Play. |
| ✅ | Permissões | Só as necessárias, sem as restritas. Ver `data-inventory.md`. |

## 2. Produto do Pro (Play Console > Monetizar > Produtos no app)

| | Item | Valor |
| --- | --- | --- |
| ⬜ | ID do produto | `sleep_sounds_pro` (**exatamente** igual ao do app) |
| ⬜ | Tipo | Compra única (não consumível) |
| ⬜ | Preço | US$ 4,99, com preços regionais ativados |
| ⬜ | Nome e descrição | EN: "Sleepy Capy Pro" · "One-time purchase. Unlocks every Pro feature." PT-BR: "Sleepy Capy Pro" · "Compra única. Libera todos os recursos Pro." |
| ⬜ | Testadores de licença | Adicione seu Gmail e o dos testadores, para comprar sem cobrança na faixa interna |

Passo a passo do produto e dos testes de compra: `docs/runbooks/google_play_monetization.md`.

## 3. Ficha da loja (Presença na loja > Ficha principal)

Idioma padrão: **Inglês (en-US)**. Acrescente **Português (Brasil, pt-BR)**.

| | Campo | Limite |
| --- | --- | --- |
| 🟡 | Título | 30 |
| 🟡 | Descrição curta | 80 |
| 🟡 | Descrição completa | 4000 |
| ⬜ | Categoria | ❓ Ver abaixo |
| ✅ | Ícone 512 × 512 | 🟡 provisório, em `store/icon_512.png` |
| ✅ | Imagem de destaque 1024 × 500 | 🟡 provisória, em `store/feature_graphic_1024x500.png` |
| ⬜ | Capturas de tela (2 a 8, celular) | Ver abaixo |
| ⬜ | E-mail de contato | `contact@douglaskrein.com` |
| ⬜ | Site (opcional) | `douglaskrein.com` (e o `app-ads.txt` nele) |
| ⬜ | URL da política de privacidade | `https://douglaskrein.com/projects/sleep-sounds/privacy-policy` (a página tem de estar no ar antes de enviar) |

**Categoria (decisão sua):** "Saúde e fitness" descreve melhor um app de sono, mas obriga a preencher a declaração de apps de saúde (o app não coleta dados de saúde, então é rápido). "Música e áudio" tem menos formulário. Recomendo **Saúde e fitness** se você aceitar a declaração, senão Música e áudio.

### Inglês (en-US)

**Título (25/30):** Sleepy Capy: Sleep Sounds

**Descrição curta (75/80):** Mix calming sounds, set a sleep timer and drift off with a sleepy capybara.

**Descrição completa (1256/4000):**

```
Sleepy Capy helps you fall asleep with calming sounds, mixed the way you like.

17 SOUNDS FOR THE NIGHT
Rain, waves, a river, a campfire, a train, wind chimes, crickets, a purring cat and more. Play as many as you like at the same time. The volume balances itself as you add sounds, so the mix never gets harsh.

A SLEEP TIMER THAT LETS GO GENTLY
Choose from 15 minutes to 12 hours, or leave it off. The sound always fades out before it stops, so nothing jolts you awake.

SAVE YOUR MIX
Save your sounds and timer as a mix and bring them back with one tap.

BEDTIME REMINDER
An optional daily nudge to wind down.

WORKS WITH THE SCREEN OFF
Keep playing all night, with play and pause in the notification. The sounds are inside the app, so they play offline.

SLEEPY CAPY PRO
One purchase, no subscription:
• Set the volume of each sound
• Save as many mixes as you like
• Fade out slowly over the last minutes, set any length, or stop at a set time
• More night themes
• No ads
The rest stays free: all 17 sounds, mixing, the timer and one saved mix.

The app is free and shows a small banner ad. No account, no sign-up. Your mixes stay on your phone.

Sound credits: recordings from freesound.org (CC0 and CC BY 4.0). See Settings > About > Audio credits.
```

### Português (pt-BR)

**Título (29/30):** Sleepy Capy: Sons para Dormir

**Descrição curta (77/80):** Misture sons relaxantes, ligue o timer e adormeça com uma capivara sonolenta.

**Descrição completa (1346/4000):**

```
O Sleepy Capy ajuda você a pegar no sono com sons relaxantes, misturados do seu jeito.

17 SONS PARA A NOITE
Chuva, ondas, um rio, uma fogueira, um trem, sinos de vento, grilos, um gato ronronando e mais. Toque quantos quiser ao mesmo tempo. O volume se equilibra sozinho conforme você acrescenta sons, então a mistura nunca fica áspera.

UM TIMER QUE SE DESPEDE COM CALMA
Escolha de 15 minutos a 12 horas, ou deixe desligado. O som sempre vai sumindo antes de parar, para nada acordar você de susto.

SALVE SEU MIX
Salve seus sons e o timer como um mix e traga tudo de volta com um toque.

LEMBRETE DE DORMIR
Um aviso diário, opcional, para começar a relaxar.

FUNCIONA COM A TELA APAGADA
Toque a noite toda, com tocar e pausar na notificação. Os sons já vêm dentro do app, então tocam sem internet.

SLEEPY CAPY PRO
Uma compra só, sem assinatura:
• Ajuste o volume de cada som
• Salve quantos mixes quiser
• Diminua o volume aos poucos nos últimos minutos, escolha qualquer duração ou pare num horário
• Mais temas para a noite
• Sem anúncios
O resto continua grátis: os 17 sons, a mixagem, o timer e um mix salvo.

O app é grátis e mostra um pequeno banner de anúncio. Sem conta, sem cadastro. Seus mixes ficam no seu celular.

Créditos dos sons: gravações do freesound.org (CC0 e CC BY 4.0). Veja em Configurações > Sobre > Créditos de áudio.
```

### Capturas de tela a tirar (celular, em pé)

Mostre o app real, com o tema escuro. Sugestão de seis, em ordem:
1. Tela principal com três sons ativos (equalizador, sliders de volume).
2. O timer, com a folha de opções aberta (Pro).
3. Os mixes salvos (chips) e o diálogo de salvar.
4. Configurações com o seletor de tema.
5. Um tema alternativo aplicado (Amber Ember, por exemplo).
6. O paywall.

Para o português, refaça com o aparelho em português. Posso gerar essas imagens a partir do app se você preferir, mas capturas reais de um aparelho são mais fiéis.

## 4. Conteúdo do app (Política > Conteúdo do app)

| | Item | Resposta proposta |
| --- | --- | --- |
| ⬜ | Política de privacidade | A URL acima |
| ⬜ | Anúncios | **Sim**, o app contém anúncios (banner do AdMob, sem interstitial nem rewarded) |
| ⬜ | Acesso ao app | Sem restrição, sem login |
| ⬜ | Público-alvo e conteúdo | **18 anos ou mais**. **Não** é voltado para crianças, e não entra no programa Em Família |
| ⬜ | Classificação de conteúdo (IARC) | Questionário: sem violência, sem conteúdo sexual, sem linguagem imprópria, sem drogas, sem jogo de azar, sem conteúdo gerado por usuários, sem compartilhar localização. Há compras digitais. Resultado esperado: **Livre** |
| ⬜ | Compras no app | Sim (produto único, Pro) |
| ⬜ | ID de publicidade | **Sim, usa** (o AdMob usa). Finalidade: publicidade |
| ⬜ | Apps de saúde | Só se escolher a categoria Saúde e fitness: não é app médico e não coleta dados de saúde |
| ⬜ | Serviços em primeiro plano | Tipo `mediaPlayback`. Texto abaixo |
| ⬜ | Segurança dos dados | Proposta abaixo |

### Serviço em primeiro plano (texto para a Play Console)

> The app plays ambient sounds for sleeping. When the user taps play, a media playback foreground service keeps the audio running with the screen off, with a media notification that has play and pause. The service stops when the user pauses, when the sleep timer ends, or when the app is closed.

Confira, na hora do envio, se ela pede um vídeo de demonstração.

### Segurança dos dados (proposta)

Base: `data-inventory.md`. **Antes de enviar, confira contra o guia oficial de divulgação de dados do AdMob** (a lista de tipos que a SDK coleta muda entre versões) e o inventário.

| Pergunta | Resposta |
| --- | --- |
| O app coleta ou compartilha algum tipo de dado? | **Sim**, por causa da SDK de anúncios |
| Todos os dados são criptografados em trânsito? | Sim (HTTPS) |
| Oferece forma de pedir exclusão de dados? | O app não tem conta nem guarda dados de usuário em servidor. A SDK do Google trata os dados de anúncio. O usuário redefine o ID de publicidade nas configurações do Android |
| **ID do dispositivo ou outros** (ID de publicidade) | Coletado e **compartilhado** com o Google (AdMob). Finalidade: publicidade ou marketing, e prevenção de fraude. Não opcional para quem vê anúncios |
| **Localização aproximada** (derivada do IP) | Coletada e compartilhada com o Google. Finalidade: publicidade |
| **Atividade no app** (interações com anúncios) | Coletada e compartilhada. Finalidade: publicidade |
| **Informações e desempenho do app** (diagnósticos, falhas da SDK) | Coletadas e compartilhadas. Finalidade: análise e prevenção de fraude |
| Informações pessoais, financeiras, saúde, mensagens, fotos, áudio, contatos | **Não coletados pelo app.** As compras são tratadas pelo Google Play |

Com o Pro, a SDK nunca é iniciada, mas o formulário descreve o app como um todo, então as respostas acima valem.

## 5. Testes antes da produção

| | Item | Detalhe |
| --- | --- | --- |
| ⬜ | Faixa de teste interno | Para testar compra, restauração e anúncios com contas de teste. Roteiro em `manual-test-plan.md` |
| ⬜ | **Teste fechado: 12 testadores por 14 dias** | Exigência para **conta pessoal nova**: antes de pedir acesso à produção, o app precisa estar em teste fechado com pelo menos 12 testadores que permaneçam inscritos por 14 dias seguidos. Comece cedo: é o prazo mais longo do processo |
| ⬜ | Relatório de pré-lançamento | Rode e leia os avisos da Play Console |

## 6. Depois de publicar

- Conferir que o produto aparece com o preço regional.
- Acompanhar as primeiras avaliações e a taxa de falhas (Android vitals).
- Guardar o AAB e o mapeamento de símbolos de cada versão.
