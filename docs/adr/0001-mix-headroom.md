# ADR 0001: Headroom do mix (atenuação automática por número de faixas)

- Status: aceita
- Data: 2026-09-24
- App: `apps/sleep_sounds`

## Contexto

Cada som do Sleepy Capy tocava com volume fixo de 0,7 e vários sons somavam. Os `.ogg` estão normalizados para −3 dBFS de pico, então cada faixa a 0,7 chega a −6,1 dBFS. Somar faixas sobe o volume percebido e aproxima o pico de 0 dBFS. No Android, o mixer do sistema satura (clipa) se a soma passar de 1,0.

## Medição antes (ffmpeg, mix em ponto flutuante, 120 s, loops reais)

| Mix | Ganho por faixa | Pico | RMS |
| --- | --- | --- | --- |
| 1 som (airplane) | 0,700 | −6,1 dBFS | −19,1 dBFS |
| 3 altos (airplane, waves, river) | 0,700 | −2,0 dBFS | −16,8 dBFS |
| 5 altos (airplane, waves, river, winter, wind) | 0,700 | **−1,0 dBFS** | −15,7 dBFS |
| 5 típicos (storm, rain, waves, river, train) | 0,700 | −2,9 dBFS | −19,7 dBFS |
| 5 com add-ons (rain, waves, birds, chimes, cat purring) | 0,700 | −2,4 dBFS | −19,7 dBFS |

Nenhuma combinação clipou na janela medida, mas a margem com 5 sons altos é de 1 dB, e picos coincidentes fora da janela podem passar de 0 dBFS. O problema mais claro é o volume percebido: 5 sons típicos ficam cerca de 7 dB mais altos que a média de um som sozinho.

## Decisão

Cada faixa toca com ganho

```
g_i = 0.7 · v_i / sqrt(max(1, Σ v_j²))
```

em que `v_i` é o volume individual da faixa (1,0 enquanto não existir controle por som). Sons de ambiente são descorrelacionados, então as potências somam. Com `1/sqrt(n)`, a potência do mix fica igual à de um som médio a 0,7, e com um som só nada muda.

A mudança de ganho ao adicionar ou remover um som é uma rampa linear de 250 ms, nunca um degrau. Implementação: `PlaybackController.gainFor` e `AudioGateway.fadeTo`.

## Medição depois

| Mix | Ganho por faixa | Pico | RMS |
| --- | --- | --- | --- |
| 1 som (airplane) | 0,700 | −6,1 dBFS | −19,1 dBFS |
| 3 altos | 0,404 | −6,8 dBFS | −21,6 dBFS |
| 5 altos | 0,313 | −8,0 dBFS | −22,7 dBFS |
| 5 típicos | 0,313 | −9,9 dBFS | −26,7 dBFS |
| 5 com add-ons | 0,313 | −9,4 dBFS | −26,7 dBFS |

O pico com 5 sons cai para no mínimo 8 dB abaixo de 0 dBFS. O RMS do mix passa a ser a média de potência dos sons que o compõem (5 típicos: −26,7 dB medido, −26,6 dB pela conta), em vez de crescer com a contagem.

## Consequências

- Ao passar de 1 para 2 sons, o primeiro cai 3 dB. É intencional, e a rampa evita o degrau.
- Os sons têm loudness bem diferentes entre si (RMS de −19 a −53 dBFS a 0,7), porque foram normalizados por pico, não por loudness. Isso é um problema separado do headroom.
- Falta confirmar em aparelho real: 5 sons simultâneos, sem distorção, volume estável ao adicionar sons.
