#!/usr/bin/env bash
#
# make_loop.sh — gera um arquivo de ambiência com loop sem emenda.
#
# Uso:
#   ./make_loop.sh entrada.wav saida.ogg [inicio] [duracao] [crossfade]
#
# Exemplo:
#   ./make_loop.sh chuva_bruta.wav rain.ogg 20 60 4
#   (pega 60s a partir do segundo 20, com 4s de crossfade → loop de 56s)
#
# Requer: ffmpeg
#
# Como funciona:
#   1. corta o trecho escolhido, remove rumble/DC offset e padroniza 48kHz estéreo
#   2. faz o "crossfade circular": o fim da gravação é misturado com o começo,
#      usando curvas de potência constante (qsin) para não haver queda de volume
#   3. normaliza o pico para -3 dBFS (todos os sons ficam no mesmo nível)
#   4. exporta em OGG Vorbis, que faz loop sem gap (MP3 NÃO faz: o encoder
#      adiciona padding no início e no fim e você ouve um clique a cada volta)
#   5. gera um arquivo _check.wav com 4 voltas, para você conferir de fone

set -euo pipefail

if [ $# -lt 2 ]; then
  sed -n '2,20p' "$0"
  exit 1
fi

IN="$1"
OUT="$2"
START="${3:-0}"
DUR="${4:-60}"
XF="${5:-4}"

command -v ffmpeg >/dev/null || { echo "ffmpeg não encontrado"; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "→ 1/4 cortando trecho (início ${START}s, duração ${DUR}s) e limpando"
ffmpeg -hide_banner -loglevel error -y \
  -ss "$START" -t "$DUR" -i "$IN" \
  -af "highpass=f=30" \
  -ar 48000 -ac 2 -c:a pcm_s24le "$TMP/seg.wav"

echo "→ 2/4 crossfade circular (${XF}s)"
ffmpeg -hide_banner -loglevel error -y -i "$TMP/seg.wav" -filter_complex \
  "[0:a]atrim=start=${XF},asetpts=N/SR/TB[a]; \
   [0:a]atrim=end=${XF},asetpts=N/SR/TB[b]; \
   [a][b]acrossfade=d=${XF}:c1=qsin:c2=qsin[out]" \
  -map "[out]" -c:a pcm_s24le "$TMP/loop.wav"

echo "→ 3/4 normalizando pico para -3 dBFS"
MAX=$(ffmpeg -hide_banner -i "$TMP/loop.wav" -af volumedetect -f null - 2>&1 \
      | awk -F': ' '/max_volume/ {print $2}' | tr -d ' dB')
GAIN=$(awk -v m="$MAX" 'BEGIN { printf "%.2f", -3 - m }')
echo "   pico atual: ${MAX} dB → ganho aplicado: ${GAIN} dB"

echo "→ 4/4 exportando OGG Vorbis"
ffmpeg -hide_banner -loglevel error -y -i "$TMP/loop.wav" \
  -af "volume=${GAIN}dB" \
  -c:a libvorbis -q:a 5 "$OUT"

CHECK="${OUT%.*}_check.wav"
ffmpeg -hide_banner -loglevel error -y -stream_loop 3 -i "$OUT" \
  -c:a pcm_s16le "$CHECK"

echo
echo "Pronto: $OUT"
echo "Confira o loop (4 voltas) em: $CHECK"
echo "Ouça de fone, em volume baixo, prestando atenção nos pontos de emenda."
