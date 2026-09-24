# Roteiro de teste em aparelho real

O que os testes automáticos **não** provam. Rode num celular Android de verdade (idealmente o seu S23 e, se der, um aparelho mais antigo), com o APK debug ou, melhor, um build release. Marque cada item e anote o que viu.

Como instalar: `cd apps/sleep_sounds && ../../.tool/flutter/bin/flutter build apk --debug` (ou `--release`) e passe `build/app/outputs/flutter-apk/*.apk` para o aparelho.

## 1. Áudio

| | Teste | Esperado |
| --- | --- | --- |
| ⬜ | Toque **5 sons ao mesmo tempo** (por exemplo Storm, Rain, Waves, River, Train) com o volume do aparelho alto | Sem distorção nem chiado. Ao acrescentar cada som o volume dos outros desce **suavemente**, sem degrau |
| ⬜ | Compare 1 som e 5 sons | O volume percebido é parecido, e o mix com 5 não fica muito mais alto |
| ⬜ | Deixe cada som repetir **3 voltas** de fone, em volume baixo | A emenda do loop não se ouve. Suspeitos: `storm` e `campfire` (ver `docs/audio-qa.md`). Anote os que falharem |
| ⬜ | Toque play e pause várias vezes | Sobe em ~1,5 s e desce em ~1 s, sem estalo |
| ⬜ | Coloque o **Campfire** ao lado do **Airplane** | O Campfire é bem mais baixo (28 LU de diferença, ver `docs/audio-qa.md`). Decida se incomoda; está anotado no DK-Life |
| ⬜ | Sons curtos (crickets tem 4 s) | A repetição é perceptível? Anote |

## 2. Timer

| | Teste | Esperado |
| --- | --- | --- |
| ⬜ | Timer de **15 minutos** até o fim, com fone | O som desce em **4 s** e para. O status mostra a contagem certa |
| ⬜ | Fade gradual ligado (5 min) com timer de 15 min | O volume começa a descer aos 10 min e chega a zero no fim |
| ⬜ | "Stop at" para daqui a 3 minutos | Para no horário. O status mostra "Stopping at ... · in ..." |
| ⬜ | "Stop at" com a **tela apagada** | Para no horário certo (a contagem usa o relógio, não os segundos) |
| ⬜ | Escolha uma duração personalizada (por exemplo 2h 5m) | Aparece no carrossel e persiste ao fechar e abrir o app |
| ⬜ | Fechar e abrir o app com sons selecionados | Volta com os sons e o timer, **sem tocar sozinho** |

## 3. Uma noite inteira

| | Teste | Esperado |
| --- | --- | --- |
| ⬜ | Toque 2 ou 3 sons com **timer de 9 h**, tela apagada, celular carregando ou não | Ainda toca de manhã, ou parou só quando o timer acabou. Anote a bateria gasta |
| ⬜ | Repita **sem** a exceção de bateria | Anote se o Android matou o app (se sim, o diálogo de bateria é necessário) |
| ⬜ | Ligação ou outro app de áudio no meio | O som pausa e, se for o caso, volta |
| ⬜ | Desconectar o fone / Bluetooth | O som pausa em vez de sair no alto-falante |

## 4. Bateria (diálogo em Configurações)

| | Teste | Esperado |
| --- | --- | --- |
| ⬜ | "Playback stops unexpectedly?" > **Open settings** | Abre a página de **detalhes do app** (o destino que você escolheu no S23). Confira que "Battery" está a um toque |
| ⬜ | Em outro fabricante (Xiaomi, Motorola), se tiver | Cai no lugar certo, ou na lista de bateria (o plano B) |

## 5. Lembrete de dormir

| | Teste | Esperado |
| --- | --- | --- |
| ⬜ | Ligar o lembrete | Pede a permissão de notificação, e depois o horário |
| ⬜ | Programe para daqui a 2 minutos, com o app **fechado** | A notificação aparece no horário, no idioma do aparelho |
| ⬜ | **Reinicie o celular** com o lembrete ligado e espere o horário | Aparece mesmo sem abrir o app (foi corrigido: faltavam os receivers no manifest) |
| ⬜ | Toque na notificação | Abre o app |
| ⬜ | Negar a permissão de notificação | O app não trava e o interruptor volta desligado |

## 6. Compra do Pro (faixa de teste interno, conta de teste de licença)

Pré-requisitos: produto `sleep_sounds_pro` criado e ativo, app enviado para a faixa interna, sua conta como testador de licença. Detalhes em `docs/runbooks/google_play_monetization.md`.

| | Teste | Esperado |
| --- | --- | --- |
| ⬜ | Abrir o paywall pelo card de Configurações | Mostra o **preço da loja** (não o de US$ 4,99 fixo) |
| ⬜ | Comprar com o cartão de teste que **sempre aprova** | Fecha o paywall, "Pro is on", banners somem, sliders e temas liberam |
| ⬜ | **Fechar e abrir o app** | Continua Pro (a restauração silenciosa). Nenhuma mensagem de "restaurado" |
| ⬜ | Cartão de teste **que sempre recusa** | Mensagem "A compra não foi concluída" e dá para tentar de novo |
| ⬜ | **Cancelar** na tela de pagamento | Volta ao paywall sem mensagem de erro |
| ⬜ | Pagamento **pendente** (cartão de teste "lento") | Mensagem de espera, botão desativado; ao aprovar, o Pro liga sozinho |
| ⬜ | Sem internet, abrir o paywall | Mostra "não deu para acessar a loja" com "Tentar de novo" |
| ⬜ | Desinstalar, reinstalar e abrir | Volta Pro sozinho ou por "Restore purchases" |
| ⬜ | Reembolsar a compra na Play Console e abrir o app | Volta a ser grátis e o tema volta para Capy Night (a escolha fica gravada) |
| ⬜ | Toque no cadeado do volume, do timer, do mix (2º) e de um tema | Cada um abre o paywall |
| ⬜ | O paywall **nunca** aparece sozinho (abrir o app, tocar sons) | Correto |

## 7. Anúncios

Use os IDs de teste do Google até publicar. Depois, **nunca clique em anúncio real do seu próprio app**.

| | Teste | Esperado |
| --- | --- | --- |
| ⬜ | Abrir o app sem Pro | Banner aparece na grade e em Configurações. Nenhum durante a reprodução |
| ⬜ | O banner **não cobre** o último cartão da grade | A lista tem espaço reservado embaixo |
| ⬜ | Sem internet | Sem banner, **sem buraco** no layout |
| ⬜ | Com Pro | Nenhum banner, e a SDK não sobe (no `adb logcat` não deve aparecer `MobileAds`) |
| ⬜ | Primeira abertura em conta **do EEA** (ou com VPN/região de teste) | O formulário de consentimento aparece antes dos anúncios |
| ⬜ | O banner ainda carrega **sem o provider automático** que removi | Se não carregar, avise: o provider é o primeiro suspeito |

## 8. Visual

| | Teste | Esperado |
| --- | --- | --- |
| ⬜ | Ícone no launcher (redondo e quadrado, no Samsung) | Capivara inteira, sem cortar o travesseiro nem o "zZz" |
| ⬜ | **Ícone temático** (Android 13+: Papel de parede e estilo > Ícones temáticos) | A capivara é reconhecível, com rosto |
| ⬜ | Splash no Android 12 ou mais novo, e em um mais antigo | Fundo navy com o capivara, e abre direto no app |
| ⬜ | Os 4 temas | Legíveis, sem texto ilegível nem borda sumindo. Estrelas brancas |
| ⬜ | Fonte grande (Configurações do Android > Tamanho da fonte no máximo) | Cards e diálogos sem cortar texto |
| ⬜ | Tela pequena ou com zoom de exibição | Nada estoura |

## 9. Idiomas

| | Teste | Esperado |
| --- | --- | --- |
| ⬜ | Aparelho em **português (Brasil)** | Todo o app em português, hora em 24 h, notificação em português |
| ⬜ | Aparelho em outro idioma (por exemplo francês) | Cai no inglês |
| ⬜ | Leia o português inteiro | Anote o que soar estranho (`lib/l10n/app_pt.arb`) |

## 10. Restante

| | Teste | Esperado |
| --- | --- | --- |
| ⬜ | Configurações > Sobre > Privacy Policy, Contact, Licenses, Audio credits | Abre o navegador, o e-mail, a página de licenças e a lista de créditos. O **Train** mostra "CC BY 4.0" e as alterações |
| ⬜ | Salvar um mix com timer personalizado | Sem erro; o chip carrega tudo de volta |
| ⬜ | Mixes: salvar 1 (grátis), tentar o 2º | Abre o paywall |
| ⬜ | Rotação da tela | Nada quebra (o app não trava a orientação) |
| ⬜ | Instalar por cima de uma versão anterior | Mantém sessão, mixes e tema |
