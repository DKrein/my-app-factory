# QA de áudio

Gerado por `tooling/audio/audio_qa.py`. Refaça o relatório depois de trocar qualquer som.

| Arquivo | Duração | Formato | Bitrate | Pico | Loudness | Salto na emenda | Loop audível? |
| --- | --- | --- | --- | --- | --- | --- | --- |
| airplane.ogg | 37.0 s | vorbis 48 kHz estéreo | 124 kbps | -3.0 dBFS | -14.7 LUFS | 0.2 dB (típico 2.9) | sem indício; **ouvir** |
| birds.ogg | 17.0 s | vorbis 48 kHz estéreo | 166 kbps | -4.7 dBFS | -17.8 LUFS | 2.4 dB (típico 4.0) | sem indício; **ouvir** |
| campfire.ogg | 37.0 s | vorbis 48 kHz estéreo | 153 kbps | -3.4 dBFS | -43.0 LUFS | 7.2 dB (típico 4.6) | suspeito; **ouvir** |
| cat_purring.ogg | 22.0 s | vorbis 48 kHz estéreo | 107 kbps | -3.1 dBFS | -22.9 LUFS | 0.3 dB (típico 4.9) | sem indício; **ouvir** |
| chimes.ogg | 17.0 s | vorbis 48 kHz estéreo | 164 kbps | -2.9 dBFS | -17.5 LUFS | 1.3 dB (típico 3.3) | sem indício; **ouvir** |
| clock.ogg | 17.0 s | vorbis 48 kHz estéreo | 128 kbps | -3.4 dBFS | -25.9 LUFS | 0.1 dB (típico 14.0) | sem indício; **ouvir** |
| crickets_chirping.ogg | 4.0 s | vorbis 44.1 kHz mono | 114 kbps | -5.3 dBFS | -17.8 LUFS | 2.2 dB (típico 16.4) | sem indício; **ouvir** |
| rain.ogg | 36.7 s | vorbis 48 kHz estéreo | 154 kbps | -4.0 dBFS | -22.7 LUFS | 0.5 dB (típico 1.3) | sem indício; **ouvir** |
| rain_forest.ogg | 42.0 s | vorbis 48 kHz estéreo | 156 kbps | -4.6 dBFS | -17.3 LUFS | 0.1 dB (típico 0.9) | sem indício; **ouvir** |
| rain_tent.ogg | 24.0 s | vorbis 48 kHz estéreo | 168 kbps | -3.7 dBFS | -29.5 LUFS | 0.5 dB (típico 5.9) | sem indício; **ouvir** |
| river.ogg | 37.0 s | vorbis 48 kHz estéreo | 153 kbps | -3.2 dBFS | -17.1 LUFS | 0.3 dB (típico 1.3) | sem indício; **ouvir** |
| storm.ogg | 44.0 s | vorbis 48 kHz estéreo | 141 kbps | -2.7 dBFS | -26.5 LUFS | 2.0 dB (típico 2.8) | suspeito; **ouvir** |
| stream.ogg | 37.0 s | vorbis 48 kHz estéreo | 211 kbps | -3.6 dBFS | -29.8 LUFS | 1.0 dB (típico 3.7) | sem indício; **ouvir** |
| train.ogg | 37.0 s | vorbis 48 kHz estéreo | 135 kbps | -3.0 dBFS | -28.7 LUFS | 1.7 dB (típico 5.2) | sem indício; **ouvir** |
| waves.ogg | 37.0 s | vorbis 48 kHz estéreo | 153 kbps | -3.4 dBFS | -17.3 LUFS | 0.3 dB (típico 1.6) | sem indício; **ouvir** |
| wind.ogg | 22.0 s | vorbis 48 kHz estéreo | 85 kbps | -3.1 dBFS | -20.3 LUFS | 2.2 dB (típico 2.9) | sem indício; **ouvir** |
| winter.ogg | 37.0 s | vorbis 48 kHz estéreo | 164 kbps | -2.9 dBFS | -21.5 LUFS | 1.3 dB (típico 3.7) | sem indício; **ouvir** |

## Como ler

- **Pico** e **Loudness** vêm de `ebur128` (pico de amostra, loudness integrado). O alvo do `make_loop.sh` é pico de -3 dBFS.
- **Salto na emenda**: diferença de nível entre os últimos e os primeiros 50 ms do arquivo (o ponto onde o loop volta ao início), ao lado da variação típica entre janelas vizinhas (percentil 90).
- **Loop audível?** é uma heurística sobre a emenda. Marca suspeito se houver salto de nível, possível clique (degrau entre a última e a primeira amostra muito maior que o normal) ou nível de início e fim diferentes. Sons com transientes (relógio, fogueira, sinos) enganam a métrica. **A confirmação é ouvir 3 voltas seguidas de fone**, em volume baixo (use `--check-dir` para gerar os `_check.wav`).

## Emenda suspeita

- `campfire.ogg`: salto de nível na emenda (7.2 dB)
- `storm.ogg`: nível do início e do fim difere 8.0 dB

## Outras observações

- `birds.ogg`: duração curta (17 s): a repetição tende a ser percebida; pico -4.7 dBFS, fora do alvo de -3 dBFS
- `cat_purring.ogg`: duração curta (22 s): a repetição tende a ser percebida
- `chimes.ogg`: duração curta (17 s): a repetição tende a ser percebida
- `clock.ogg`: duração curta (17 s): a repetição tende a ser percebida
- `crickets_chirping.ogg`: duração curta (4 s): a repetição tende a ser percebida; pico -5.3 dBFS, fora do alvo de -3 dBFS
- `rain_forest.ogg`: pico -4.6 dBFS, fora do alvo de -3 dBFS
- `rain_tent.ogg`: duração curta (24 s): a repetição tende a ser percebida
- `wind.ogg`: duração curta (22 s): a repetição tende a ser percebida
- Loudness entre os arquivos: de -43.0 LUFS (`campfire.ogg`) a -14.7 LUFS (`airplane.ogg`), 28 LU de diferença. Os arquivos foram normalizados por pico, não por loudness.

Para refazer um som, use `tooling/audio/make_loop.sh` a partir da gravação original.
