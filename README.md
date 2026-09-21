# App Factory

Monorepo Flutter para aplicativos Android pequenos, offline-first e com
integrações opcionais. A documentação de produto e arquitetura está em
[SPEC.md](SPEC.md), [ARCHITECTURE.md](ARCHITECTURE.md) e [ROADMAP.md](ROADMAP.md).

## Começar

O SDK Flutter usado localmente fica em `.tool/flutter` (não versionado).

```bash
cd apps/sleep_sounds
../../.tool/flutter/bin/flutter pub get
../../.tool/flutter/bin/flutter run
```

Para validar a fundação:

```bash
./tooling/check.sh
```

## Estrutura atual

- `apps/_template`: ponto de partida para um novo aplicativo offline.
- `apps/sleep_sounds`: aplicativo piloto, com catálogo e interface inicial.
- `packages/`: contratos e UI compartilhados, sem SDKs de ads, billing ou
  analytics.
