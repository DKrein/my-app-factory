#!/usr/bin/env python3
"""Gera apps/sleep_sounds/docs/audio-qa.md a partir dos .ogg de apps/sleep_sounds/assets/audio.

Uso: tooling/audio/audio_qa.py [pasta_de_audio] [saida.md]

Requer ffmpeg e ffprobe. Não substitui ouvir os loops: os números só apontam
suspeitas. Também grava <nome>_check.wav (3 voltas) em --check-dir, se pedido.
"""
import array
import json
import math
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
AUDIO_DIR = ROOT / "apps/sleep_sounds/assets/audio"
OUT_MD = ROOT / "apps/sleep_sounds/docs/audio-qa.md"

SAMPLE_RATE = 48000
WINDOW = SAMPLE_RATE // 20  # 50 ms
TARGET_PEAK_DB = -3.0
MIN_DURATION_S = 30


def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True, check=True)


def probe(path):
    out = run(
        ["ffprobe", "-v", "error", "-print_format", "json", "-show_format",
         "-show_streams", str(path)]
    ).stdout
    data = json.loads(out)
    stream = data["streams"][0]
    return {
        "duration": float(data["format"]["duration"]),
        "codec": stream["codec_name"],
        "container": data["format"]["format_name"],
        "sample_rate": int(stream["sample_rate"]),
        "channels": stream["channels"],
        "bitrate": int(data["format"]["bit_rate"]) // 1000,
    }


def loudness(path):
    err = subprocess.run(
        ["ffmpeg", "-nostats", "-hide_banner", "-i", str(path), "-af",
         "ebur128=peak=sample", "-f", "null", "-"],
        capture_output=True, text=True,
    ).stderr
    summary = err[err.rfind("Summary:"):]
    lufs = float(re.search(r"I:\s+(-?[\d.]+) LUFS", summary).group(1))
    peak = float(re.search(r"Peak:\s+(-?[\d.]+) dBFS", summary).group(1))
    return lufs, peak


def decode_mono(path):
    raw = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", str(path), "-f", "f32le", "-ac", "1",
         "-ar", str(SAMPLE_RATE), "-"],
        capture_output=True, check=True,
    ).stdout
    samples = array.array("f")
    samples.frombytes(raw)
    return samples


def rms(samples, start, end):
    n = end - start
    return math.sqrt(sum(s * s for s in samples[start:end]) / n) if n else 0.0


def db(x):
    return 20 * math.log10(max(x, 1e-9))


def seam_metrics(x):
    n = len(x)
    levels = [db(rms(x, i, i + WINDOW)) for i in range(0, n - WINDOW, WINDOW)]
    steps = sorted(abs(a - b) for a, b in zip(levels, levels[1:]))
    typical = steps[int(len(steps) * 0.9)]
    level_jump = abs(db(rms(x, n - WINDOW, n)) - db(rms(x, 0, WINDOW)))

    diffs = [x[i + 1] - x[i] for i in range(0, n - 1, 7)]
    diff_rms = math.sqrt(sum(d * d for d in diffs) / len(diffs))
    click = abs(x[0] - x[-1]) / max(diff_rms, 1e-9)

    second = SAMPLE_RATE
    edge = abs(db(rms(x, n - second, n)) - db(rms(x, 0, second)))
    return {"jump": level_jump, "typical": typical, "click": click, "edge": edge}


def seam_notes(seam):
    notes = []
    if seam["jump"] > max(3.0, 1.5 * seam["typical"]):
        notes.append(f"salto de nível na emenda ({seam['jump']:.1f} dB)")
    if seam["click"] > 8:
        notes.append(f"possível clique na emenda (x{seam['click']:.0f})")
    if seam["edge"] > 3:
        notes.append(f"nível do início e do fim difere {seam['edge']:.1f} dB")
    return notes


def other_notes(info, peak):
    notes = []
    if info["duration"] < MIN_DURATION_S:
        notes.append(f"duração curta ({info['duration']:.0f} s): a repetição "
                     "tende a ser percebida")
    if abs(peak - TARGET_PEAK_DB) > 1.0:
        notes.append(f"pico {peak:.1f} dBFS, fora do alvo de "
                     f"{TARGET_PEAK_DB:.0f} dBFS")
    return notes


def build_check(path, check_dir):
    check_dir.mkdir(parents=True, exist_ok=True)
    out = check_dir / f"{path.stem}_check.wav"
    run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-stream_loop",
         "2", "-i", str(path), "-c:a", "pcm_s16le", str(out)])


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    check_dir = None
    if "--check-dir" in sys.argv:
        check_dir = Path(sys.argv[sys.argv.index("--check-dir") + 1])
        args = [a for a in args if a != str(check_dir)]
    audio_dir = Path(args[0]) if args else AUDIO_DIR
    out_md = Path(args[1]) if len(args) > 1 else OUT_MD

    rows, seam_flagged, other_flagged = [], [], []
    for path in sorted(audio_dir.glob("*.ogg")):
        info = probe(path)
        lufs, peak = loudness(path)
        seam = seam_metrics(decode_mono(path))
        notes = seam_notes(seam)
        if check_dir:
            build_check(path, check_dir)
        rows.append((path.name, info, lufs, peak, seam, notes))
        if notes:
            seam_flagged.append((path.name, notes))
        if other_notes(info, peak):
            other_flagged.append((path.name, other_notes(info, peak)))

    lines = [
        "# QA de áudio",
        "",
        "Gerado por `tooling/audio/audio_qa.py`. Refaça o relatório depois de "
        "trocar qualquer som.",
        "",
        "| Arquivo | Duração | Formato | Bitrate | Pico | Loudness | "
        "Salto na emenda | Loop audível? |",
        "| --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for name, info, lufs, peak, seam, notes in rows:
        fmt = f"{info['codec']} {info['sample_rate'] / 1000:g} kHz " \
              f"{'estéreo' if info['channels'] == 2 else 'mono'}"
        status = "suspeito" if notes else "sem indício"
        lines.append(
            f"| {name} | {info['duration']:.1f} s | {fmt} | "
            f"{info['bitrate']} kbps | {peak:.1f} dBFS | {lufs:.1f} LUFS | "
            f"{seam['jump']:.1f} dB (típico {seam['typical']:.1f}) | "
            f"{status}; **ouvir** |"
        )
    lines += [
        "",
        "## Como ler",
        "",
        "- **Pico** e **Loudness** vêm de `ebur128` (pico de amostra, loudness "
        "integrado). O alvo do `make_loop.sh` é pico de -3 dBFS.",
        "- **Salto na emenda**: diferença de nível entre os últimos e os primeiros "
        "50 ms do arquivo (o ponto onde o loop volta ao início), ao lado da "
        "variação típica entre janelas vizinhas (percentil 90).",
        "- **Loop audível?** é uma heurística sobre a emenda. Marca suspeito se "
        "houver salto de nível, possível clique (degrau entre a última e a "
        "primeira amostra muito maior que o normal) ou nível de início e fim "
        "diferentes. Sons com transientes (relógio, fogueira, sinos) enganam "
        "a métrica. **A confirmação é ouvir 3 voltas seguidas de fone**, em "
        "volume baixo (use `--check-dir` para gerar os `_check.wav`).",
        "",
        "## Emenda suspeita",
        "",
    ]
    if seam_flagged:
        for name, notes in seam_flagged:
            lines.append(f"- `{name}`: " + "; ".join(notes))
    else:
        lines.append("Nenhum arquivo foi marcado pelos números.")

    lines += ["", "## Outras observações", ""]
    for name, notes in other_flagged:
        lines.append(f"- `{name}`: " + "; ".join(notes))
    lufs_values = [r[2] for r in rows]
    quietest = min(rows, key=lambda r: r[2])
    loudest = max(rows, key=lambda r: r[2])
    lines.append(
        f"- Loudness entre os arquivos: de {quietest[2]:.1f} LUFS "
        f"(`{quietest[0]}`) a {loudest[2]:.1f} LUFS (`{loudest[0]}`), "
        f"{max(lufs_values) - min(lufs_values):.0f} LU de diferença. Os "
        "arquivos foram normalizados por pico, não por loudness."
    )
    lines += [
        "",
        "Para refazer um som, use `tooling/audio/make_loop.sh` a partir da "
        "gravação original.",
    ]
    out_md.parent.mkdir(parents=True, exist_ok=True)
    out_md.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"{len(rows)} arquivos, {len(seam_flagged)} com emenda suspeita -> {out_md}")


if __name__ == "__main__":
    main()
