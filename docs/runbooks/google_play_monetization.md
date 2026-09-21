# Runbook: Configuração do Google Play Console e Monetização (Fase 2)

Este runbook descreve o procedimento operacional para configurar o Google Play Console, Google Play Billing e Google AdMob para qualquer aplicativo produzido pela **App Factory**, bem como o roteiro de testes manuais em faixa interna.

---

## 1. Configuração do Google Play Billing (IAP)

### 1.1. Pré-requisitos
- Conta de desenvolvedor do Google Play ativa.
- Perfil para pagamentos (Google Payments Merchant Account) vinculado à conta do Google Play Console.
- Aplicativo cadastrado no Play Console com o mesmo `package_name` (ex: `com.appfactory.sleepsounds`) definido no `app.yaml` e no `android/app/build.gradle.kts`.

### 1.2. Cadastro de Produtos no Aplicativo (In-App Products)
1. No menu lateral do Play Console, navegue até: **Monetizar com o Play > Produtos no app** (*In-app products*).
2. Clique em **Criar produto**.
3. Preencha os campos:
   - **ID do produto**: Deve corresponder exatamente ao ID declarado no catálogo do app (ex: `sleep_sounds_remove_ads`).
   - **Nome**: Ex: `Remover Anúncios`.
   - **Descrição**: Ex: `Desativa permanentemente todos os banners e anúncios do aplicativo.`
   - **Preço padrão**: Defina o valor (ex: `R$ 9,90`). O Google Play calculará os preços locais para outros países automaticamente.
4. Clique em **Salvar** e em seguida em **Ativar**.

> [!IMPORTANT]
> O Google Play Billing só permite carregar e testar produtos se o aplicativo tiver pelo menos uma versão (AAB) enviada e aprovada em uma faixa de teste (Teste interno ou Teste fechado) com a permissão `com.android.vending.BILLING` declarada no Manifesto (incluída automaticamente pelo plugin `in_app_purchase`).

### 1.3. Configuração de Contas de Teste de Licença (License Testing)
Para testar compras sem ser cobrado financeiramente:
1. No menu principal do Play Console (fora do app), vá em **Configurações > Teste de licença**.
2. Adicione os endereços de e-mail das contas Google (@gmail.com) que serão usadas nos dispositivos de teste.
3. Em **Resposta da licença**, mantenha `RESPOND_NORMALLY`.
4. Em **Cobrança de teste**, selecione `Cartão de crédito de teste com cobrança aprovada` ou selecione na hora da compra.

---

## 2. Publicação na Faixa de Teste Interno (Internal Testing)

1. No diretório do aplicativo (ex: `apps/sleep_sounds`), gere o pacote de release:
   ```bash
   flutter build appbundle --release
   ```
2. No Play Console, vá em **Testar e lançar > Teste interno** (*Internal testing*).
3. Crie uma nova versão e faça o upload do arquivo `.aab` gerado em `build/app/outputs/bundle/release/app-release.aab`.
4. Na aba **Testadores**, crie ou selecione uma lista de e-mails contendo os mesmos testadores configurados no passo 1.3.
5. Copie o **Link de adesão ao teste** (ex: `https://play.google.com/apps/testing/...`).
6. No dispositivo Android de teste, abra o link no navegador, clique em **Aceitar convite** e baixe o aplicativo diretamente da Google Play Store.

---

## 3. Roteiro de Testes Manuais de Faturamento

Ao abrir o app instalado via faixa de teste interno com a conta de testador:

### Teste A: Compra Única Bem-Sucedida
1. Toque no botão de compra (ex: "Remover Anúncios").
2. O modal nativo da Google Play abrirá com a mensagem *"Esta é uma compra de teste. Você não será cobrado."*.
3. Selecione o método **Cartão de teste que sempre é aprovado**.
4. Toque em **Comprar**.
5. **Resultado Esperado:**
   - O app recebe o evento `PurchaseProgressStatus.purchased`.
   - O entitlement `remove_ads` é registrado no `EntitlementStore`.
   - O banner de anúncio desaparece instantaneamente via `AdsPolicy`.
   - O app chama `completePurchase` no gateway, confirmando a transação.

### Teste B: Pagamento Pendente (Pending Purchase)
1. Toque em "Remover Anúncios".
2. No modal do Google Play, escolha **Cartão de teste com aprovação lenta (alguns minutos)**.
3. Conclua a solicitação.
4. **Resultado Esperado:**
   - O app recebe `PurchaseProgressStatus.pending`.
   - A interface exibe aviso de "Transação em processamento" e **não** desbloqueia o entitlement prematuramente.
   - Após alguns minutos, quando o Google Play processar a aprovação, o listener de stream recebe `purchased` e ativa o `remove_ads`.

### Teste C: Compra Recusada ou Cancelada
1. Toque em "Remover Anúncios".
2. Selecione **Cartão de teste que sempre é recusado** ou feche o modal.
3. **Resultado Esperado:**
   - O app recebe `PurchaseProgressStatus.canceled` ou `error`.
   - Nenhum direito é concedido; o app permanece funcionando normalmente sem travar.

### Teste D: Restauração de Compras (Restore Purchases)
1. Com uma compra previamente realizada, desinstale o app do dispositivo ou limpe todos os dados do app em *Configurações do Android > Aplicativos > Armazenamento > Limpar dados*.
2. Abra o app novamente.
3. Acesse a tela de configurações e toque em **Restaurar compras**.
4. **Resultado Esperado:**
   - O app consulta o histórico da conta na Google Play Store.
   - A compra não consumível é detectada e o status `PurchaseProgressStatus.restored` é emitido.
   - O entitlement `remove_ads` é restaurado com sucesso.

### Teste E: Inicialização Offline
1. Após a compra ter sido efetuada e gravada no storage local (`factory_storage`).
2. Coloque o dispositivo em Modo Avião (sem internet).
3. Abra o app.
4. **Resultado Esperado:**
   - O app inicializa sem anúncios imediatamente, honrando o cache offline sem esperar resposta da rede.

---

## 4. Configuração do Google AdMob

### 4.1. Cadastro do App e Blocos de Anúncios
1. No painel do [Google AdMob](https://admob.google.com/):
   - Adicione o aplicativo informando se já está listado no Google Play ou não.
   - Copie o **ID do Aplicativo AdMob** (ex: `ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY`).
   - Configure o ID no `AndroidManifest.xml` do app:
     ```xml
     <meta-data
         android:name="com.google.android.gms.ads.APPLICATION_ID"
         android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"/>
     ```
2. Crie os blocos de anúncio (Ad Units):
   - **Banner**: tipo padrão adaptável (320x50).
   - Copie o ID do bloco (ex: `ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ`).

### 4.2. Dispositivos de Teste no AdMob
> [!CAUTION]
> Nunca clique nos seus próprios anúncios de produção. Sempre cadastre os dispositivos de teste no AdMob para evitar suspensão da conta por tráfego inválido.
1. No console do AdMob, vá em **Configurações > Dispositivos de teste**.
2. Adicione o dispositivo informando o **ID de publicidade (AAID)** do aparelho.
3. Enquanto desenvolve localmente, utilize as constantes oficiais fornecidas pelo pacote:
   - `AdmobTestUnits.androidBanner`
   - `AdmobTestUnits.androidInterstitial`

### 4.3. Privacidade e Consentimento (UMP / GDPR / LGPD)
1. No console do AdMob, acesse **Privacidade e mensagens**.
2. Ative a mensagem para regulamentações europeias (GDPR).
3. No código Flutter do app, invoque:
   ```dart
   final adsGateway = GoogleMobileAdsGateway();
   await adsGateway.requestConsentAndInitialize();
   ```
4. Se o usuário estiver em região que exige consentimento, o formulário oficial UMP será renderizado na tela antes de veicular anúncios personalizados.
