# TODO do Sleepy Capy até a publicação

O app está completo em código (fases 1 a 7 do plano feitas). Falta o que é de conta, de loja e de aparelho. Detalhes de cada área: `docs/store-checklist.md`, `docs/data-inventory.md`, `docs/manual-test-plan.md`, `docs/privacy-policy.md`.

Legenda: 🧑 só você faz · 📱 precisa do aparelho · 🤖 dá para pedir ao Claude

## Antes de tudo: fazer o commit

Tudo o que foi feito está em stage (`git add`), sem commit. Confira com `git status` e commite (mensagem em inglês). Os rascunhos de mensagem estão no fim de cada resposta da sessão.

## 1. Decisões (5 minutos, e destravam o resto)

- [ ] 🧑 **`applicationId`.** Hoje `com.douglaskrein.sleepsounds`. A convenção do projeto (`com.douglaskrein.[app_name]`) daria `com.douglaskrein.sleep_sounds`. **É permanente depois do primeiro envio.** Se mudar, é nos arquivos `app.yaml`, `app_config.g.dart`, `android/app/build.gradle.kts` (`applicationId`) e no produto da Play.
- [ ] 🧑 **Categoria da loja:** Saúde e fitness (recomendada, exige a declaração de apps de saúde, rápida) ou Música e áudio.
- [ ] 🧑 **Revisar o português** em `lib/l10n/app_pt.arb`, principalmente o diálogo de bateria, os 5 benefícios do paywall e as mensagens de erro.

## 2. Conta e chaves (🧑, em ordem)

- [ ] **Chave de envio (keystore).** Sem ela o release usa a chave de debug e a Play rejeita.
  ```bash
  cd apps/sleep_sounds/android
  ../../../.tool/jdk/bin/keytool -genkeypair -v -keystore ~/sleepy-capy-upload.jks \
    -keyalg RSA -keysize 2048 -validity 10000 -alias upload
  ```
  Crie `apps/sleep_sounds/android/key.properties` (já está no `.gitignore`):
  ```
  storePassword=...
  keyPassword=...
  keyAlias=upload
  storeFile=/home/dodo/sleepy-capy-upload.jks
  ```
  **Faça backup do `.jks` e das senhas fora do computador.** Use o Play App Signing (a Play guarda a chave final; você guarda só a de envio).
- [ ] **Conta de desenvolvedor do Google Play** (se ainda não criou) e o perfil de pagamentos. Conta pessoal nova exige o teste fechado (item 6).
- [ ] **AdMob.** Crie o app Android e **duas unidades de banner** (grade e Configurações). Troque:
  - o ID do app (`ca-app-pub-...~...`) em `android/app/src/main/AndroidManifest.xml` (`APPLICATION_ID`);
  - o ID do banner em `app.yaml` e `lib/app_config.g.dart` (`bannerAdUnitId`);
  - hoje as duas telas usam o mesmo ID de teste. Para dar um ID a cada uma, peça ao Claude (item 8).
- [ ] **`app-ads.txt`** na raiz do seu site (`https://douglaskrein.com/app-ads.txt`), com uma linha do AdMob: `google.com, pub-XXXXXXXXXXXXXXXX, DIRECT, f08c47fec0942fa0` (o `pub-` é o seu ID de editor, que aparece no AdMob). Informe o site na ficha da loja.
- [ ] **Política de privacidade no site.** Troque o texto em `https://douglaskrein.com/projects/sleep-sounds/privacy-policy` pelo de `docs/privacy-policy.md` (EN e PT) e preencha a data. **O texto atual diz que não há anúncios: está errado para este app.** Peça uma revisão a quem entende de LGPD e GDPR.

## 3. Produto do Pro na Play Console (🧑)

Passo a passo completo: `docs/runbooks/google_play_monetization.md`.

- [ ] Crie o produto **`sleep_sounds_pro`**, compra única, **US$ 4,99** com preços regionais.
- [ ] Nome e descrição: EN "Sleepy Capy Pro" · "One-time purchase. Unlocks every Pro feature."; PT-BR "Sleepy Capy Pro" · "Compra única. Libera todos os recursos Pro.".
- [ ] Adicione seu Gmail e o dos testadores como **testadores de licença**.

## 4. Pacote e ficha da loja

- [ ] 🧑 Gerar o AAB (com a chave já criada):
  ```bash
  export JAVA_HOME=/home/dodo/projects/my-app-factory/.tool/jdk
  cd apps/sleep_sounds && ../../.tool/flutter/bin/flutter build appbundle --release
  ```
  O `versionCode` (o número depois do `+` em `pubspec.yaml` e `app.yaml`) **sobe a cada envio**.
- [ ] 🧑 Preencher a ficha com os textos EN e PT de `docs/store-checklist.md` (título, descrição curta e completa, já conferidos nos limites).
- [ ] 🧑 Conteúdo do app: anúncios (sim), público 18+ (não é para crianças), classificação de conteúdo, ID de publicidade (sim), serviço em primeiro plano `mediaPlayback` (texto pronto no checklist) e a **Segurança dos dados** (proposta no checklist; **confira contra o guia de divulgação de dados do AdMob**).
- [ ] 🧑 **Capturas de tela** (2 a 8, celular, em pé). Lista das seis sugeridas em `docs/store-checklist.md`. Duas opções:
  - tirar do aparelho, com o tema escuro (mais fiel);
  - pedir ao Claude para gerar a partir do app (item 8).
- [ ] 🧑 Trocar o ícone 512 e a imagem de destaque provisórios quando tiver a arte final (`apps/sleep_sounds/store/`). Para regenerar tudo a partir de um novo `assets/branding/source/capybara.png`, rode `tooling/branding/make_icons.sh`.

## 5. Testes no aparelho (📱)

- [ ] Rodar `docs/manual-test-plan.md` no S23 (e num aparelho mais antigo, se tiver). Os mais importantes:
  - 5 sons juntos sem distorção;
  - timer de 15 min até o fim, com fade;
  - **uma noite inteira com a tela apagada**;
  - **o lembrete de dormir, inclusive depois de reiniciar o celular** (foi corrigido na auditoria, e só o aparelho confirma);
  - o banner ainda carrega depois de eu ter removido o provider automático da SDK;
  - o ícone temático (Android 13+) e a splash.
- [ ] Subir na **faixa de teste interno** e testar compra (aprovada, recusada, cancelada, pendente), restauração ao reabrir e reembolso.

## 6. Teste fechado e produção

- [ ] 🧑 **Conta pessoal nova: teste fechado com 12 testadores por 14 dias seguidos** antes de pedir a produção. É o prazo mais longo, então **comece cedo**: assim que o AAB e a ficha estiverem prontos. Junte os 12 testadores (amigos, família, grupos de testadores) antes de abrir a faixa.
- [ ] 🧑 Ler o relatório de pré-lançamento da Play Console e corrigir o que aparecer.
- [ ] 🧑 Pedir acesso à produção e publicar.
- [ ] 🧑 Depois: conferir o preço regional do produto, as primeiras avaliações e o Android vitals. Guardar o AAB de cada versão.

## 7. Áudio (sem pressa, não bloqueia a publicação)

- [ ] 📱 Ouvir 3 voltas de cada som de fone e anotar emendas audíveis. Suspeitos em `docs/audio-qa.md`: `storm` e `campfire`. `crickets` tem só 4 s.
- [ ] 🧑 Refazer com `tooling/audio/make_loop.sh` os que falharem (precisa da gravação original, que não está no repositório).
- [ ] 🧑 Decidir se normaliza o loudness dos 17 sons (hoje de -43 a -14,7 LUFS; o `campfire` quase não se ouve ao lado do `airplane`). Está no DK-Life.

## 8. O que dá para pedir ao Claude numa próxima sessão

- [ ] 🤖 **Capturas de tela geradas a partir do app**, em EN e PT, com os temas (mais rápido que tirar do aparelho).
- [ ] 🤖 **Um ID de anúncio para cada tela:** acrescentar `banner_settings_ad_unit_id` ao `app.yaml` e ao `AppConfig`, e usar na tela de Configurações.
- [ ] 🤖 **Um chip "+ Salvar este mix"** quando há sons ativos e nenhum mix salvo. Sem a linha Favorites, um usuário novo só descobre o ícone de marcador por acaso.
- [ ] 🤖 **Normalizar o loudness** dos 17 sons (ajuste de ganho nos `.ogg`, sem mexer nos loops).
- [ ] 🤖 **Aumentar a velocidade das estrelas do fundo** (pendência no DK-Life).
- [ ] 🤖 **Trocar uma paleta do Pro** (por exemplo pelo Deep Ocean, azul-petróleo). É só uma entrada em `FactoryPalette` e o teste de contraste confere.
- [ ] 🤖 Ajustar qualquer coisa que o roteiro de teste no aparelho mostrar.

## Limitações conhecidas (para não se surpreender)

- A splash nativa do Android é sempre azul Capy Night, mesmo com outro tema (o Android não gera a splash por tema em tempo de execução).
- Um canal de notificação, depois de criado, o Android não renomeia: quem trocar de idioma vê o nome antigo do canal.
- Nomes dos temas e o nome do app não são traduzidos (são nomes próprios).
- O e-mail de feedback tem as linhas técnicas ("App:", "Platform:") em inglês, porque quem lê é você.
