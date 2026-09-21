#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
flutter_bin="$root_dir/.tool/flutter/bin/flutter"

if [[ ! -x "$flutter_bin" ]]; then
  echo "Flutter local não encontrado em .tool/flutter." >&2
  exit 1
fi

projects=(
  "packages/factory_core"
  "packages/factory_ui"
  "packages/factory_storage"
  "packages/factory_navigation"
  "packages/factory_audio"
  "packages/factory_ads"
  "packages/factory_billing"
  "apps/_template"
  "apps/sleep_sounds"
)

for project in "${projects[@]}"; do
  echo "==> $project"
  (cd "$root_dir/$project" && "$flutter_bin" analyze && "$flutter_bin" test)
done

echo "Validação concluída."
