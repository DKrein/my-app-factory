#!/usr/bin/env bash
#
# make_icons.sh — gera os ícones do Sleepy Capy e os ativos provisórios da
# loja a partir de assets/branding/source/capybara.png.
#
# Uso (a partir da raiz do repositório):
#   tooling/branding/make_icons.sh
#
# Depois, para aplicar nos recursos do Android:
#   cd apps/sleep_sounds
#   ../../.tool/flutter/bin/dart run flutter_launcher_icons
#   ../../.tool/flutter/bin/dart run flutter_native_splash:create
#
# Requer: ffmpeg (com os filtros geq e drawtext).
#
# Quando a arte final chegar, troque o capybara.png e rode de novo. Os ativos
# da loja (apps/sleep_sounds/store) são PROVISÓRIOS até lá.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
app="$root/apps/sleep_sounds"
brand="$app/assets/branding"
store="$app/store"
src="$brand/source/capybara.png"
font="$root/.tool/flutter/bin/cache/artifacts/material_fonts/Roboto-Bold.ttf"

# A área realmente visível de um ícone adaptativo redondo é um círculo de
# 66 dp em um quadro de 108 dp (raio de 30% do quadro). O pixel mais distante
# do centro na arte fica a 685,9 px de um quadro de 1254 px; para caber no
# círculo, a arte é reduzida para 562 px em 1024 (fator 0,4479). Se a arte
# mudar, recalcule esse número.
fg_art=562
# O ícone legado é um quadrado cheio, que o launcher recorta sozinho.
legacy_art=830

mkdir -p "$store"

echo "→ 1/5 primeiro plano adaptativo (arte em ${fg_art}px dentro de 1024)"
ffmpeg -hide_banner -loglevel error -y -i "$src" \
  -vf "scale=${fg_art}:${fg_art}:flags=lanczos,format=rgba,pad=1024:1024:(ow-iw)/2:(oh-ih)/2:color=black@0" \
  -frames:v 1 -update 1 "$brand/icon_foreground.png"

echo "→ 2/5 ícone monocromático (Android 13+): alfa segue a luminosidade, então rosto e contornos aparecem"
ffmpeg -hide_banner -loglevel error -y -i "$brand/icon_foreground.png" \
  -vf "format=rgba,geq=r=255:g=255:b=255:a='alpha(X,Y)*(0.25+0.75*(0.299*r(X,Y)+0.587*g(X,Y)+0.114*b(X,Y))/255)'" \
  -frames:v 1 -update 1 "$brand/icon_monochrome.png"

echo "→ 3/5 ícone legado (quadrado cheio, ${legacy_art}px sobre o fundo)"
ffmpeg -hide_banner -loglevel error -y -i "$brand/icon_background.png" -i "$src" \
  -filter_complex "[1:v]scale=${legacy_art}:${legacy_art}:flags=lanczos[a];[0:v][a]overlay=(W-w)/2:(H-h)/2,format=rgb24" \
  -frames:v 1 -update 1 "$brand/icon_legacy.png"

echo "→ 4/5 ícone da loja 512x512 (PROVISÓRIO)"
ffmpeg -hide_banner -loglevel error -y -i "$brand/icon_legacy.png" \
  -vf "scale=512:512:flags=lanczos,format=rgba" -frames:v 1 -update 1 "$store/icon_512.png"

echo "→ 5/5 imagem de destaque 1024x500 (PROVISÓRIA)"
ffmpeg -hide_banner -loglevel error -y \
  -f lavfi -i "color=c=0x0B1020:s=1024x500" \
  -i "$brand/starfield.png" -i "$src" \
  -filter_complex "
    [1:v]format=rgba,split=6[s0][s1][s2][s3][s4][s5];
    [0:v][s0]overlay=0:0[b0];[b0][s1]overlay=480:0[b1];[b1][s2]overlay=960:0[b2];
    [b2][s3]overlay=0:480[b3];[b3][s4]overlay=480:480[b4];[b4][s5]overlay=960:480[b5];
    [2:v]scale=440:440:flags=lanczos[cap];
    [b5][cap]overlay=540:30,
    drawtext=fontfile='${font}':text='Sleepy Capy':fontcolor=0xF4F7FF:fontsize=86:x=70:y=(h-text_h)/2" \
  -frames:v 1 -update 1 "$store/feature_graphic_1024x500.png"

echo
echo "Pronto. Confira: $brand e $store"
