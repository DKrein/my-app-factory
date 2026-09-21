# Template de Aplicativo — App Factory

Este projeto é o molde padrão (*starter template*) para criar novos aplicativos na **App Factory**.

Ele já vem pré-configurado com a arquitetura offline-first da fábrica:
- **Tema Visual**: Material 3 escuro padronizado via `factory_ui`.
- **Persistência**: Abstração `KeyValueStore` via `factory_storage`.
- **Contratos e Erros**: Tipagem padronizada via `factory_core`.
- **Configuração Declarativa**: Arquivo `app.yaml` e constantes geradas em `app_config.g.dart`.

---

## Como criar um novo aplicativo a partir deste molde

1. **Copie a pasta `_template`**:
   ```bash
   cp -r apps/_template apps/novo_app
   ```

2. **Personalize o `app.yaml`** (`apps/novo_app/app.yaml`):
   ```yaml
   app:
     id: com.appfactory.novoapp
     name: Novo App
     version: 1.0.0+1
     support_email: suporte@exemplo.com

   modules:
     ui: true
     navigation: true
     storage: true
     audio: false     # Mude para true se usar factory_audio
     ads: false       # Mude para true se usar factory_ads
     billing: false   # Mude para true se usar factory_billing
     analytics: false
     backend: false
   ```

3. **Atualize o `pubspec.yaml`** (`apps/novo_app/pubspec.yaml`):
   - Mude o campo `name: novo_app`.
   - Descomente os pacotes adicionais necessários (`factory_audio`, `factory_ads`, `factory_billing`).

4. **Atualize o identificador Android**:
   - Ajuste o `applicationId` em `android/app/build.gradle.kts` para coincidir com o `id` do `app.yaml`.

5. **Instale as dependências e rode**:
   ```bash
   cd apps/novo_app
   ../../.tool/flutter/bin/flutter pub get
   ../../.tool/flutter/bin/flutter run
   ```

6. **Valide a conformidade do projeto**:
   ```bash
   ./tooling/check.sh
   ```
