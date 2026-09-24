# my-app-factory

## Flutter / Android

O Flutter, o Android SDK e o JDK ficam dentro do projeto, em `.tool/` (não versionado). Não existe `flutter` no PATH nem instalação global: sempre use o caminho do projeto e não instale nada com sudo.

Dentro de `apps/<app>`:

```bash
export JAVA_HOME=/home/dodo/projects/my-app-factory/.tool/jdk
../../.tool/flutter/bin/flutter test
../../.tool/flutter/bin/flutter build apk --debug
```

- APK sai em `apps/<app>/build/app/outputs/flutter-apk/`.
- Validação geral da fundação: `./tooling/check.sh`.
- `android/local.properties` já aponta para `.tool/flutter` e `.tool/android-sdk`.
