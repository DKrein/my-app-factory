# ADR 0003: Catálogo enxuto e curado

- Status: aceita
- Data: 2026-09-24
- App: `apps/sleep_sounds`

## Contexto

Apps de sons para dormir costumam competir por quantidade ("100 sons"). O Sleepy Capy tem 17 sons, e cada som a mais custa: tamanho do app (o áudio já é a maior parte dos 74 MB do APK universal), tempo de revisão de cada loop, créditos e licenças a manter, e um seletor mais difícil de percorrer no escuro.

## Decisão

- **O catálogo fica enxuto e curado.** Não vai crescer para dezenas de sons. Isso só funciona se **cada som for muito bom**.
- **Nenhum som fica trancado atrás do Pro.** O Pro cobra por capacidade (ADR 0002). Um catálogo pequeno e inteiro grátis é uma escolha de produto, e faz o Pro parecer justo.
- **Um som novo só entra se passar em todos os itens:**
  1. **Loop sem emenda audível**, ouvido de fone, 3 voltas seguidas. `tooling/audio/audio_qa.py` aponta suspeitos, mas a decisão é de ouvido. Refazer com `tooling/audio/make_loop.sh` quando precisar.
  2. **Duração de pelo menos ~30 s**, para a repetição não ser notada (hoje só 6 sons ficam abaixo disso, e estão anotados em `docs/audio-qa.md`).
  3. **Loudness compatível** com os demais, e pico próximo de -3 dBFS.
  4. **Licença CC0 ou CC BY 4.0**, com a linha em `assets/credits.json` (autor, título original, link, licença, e "edited" se o som foi alterado). Um teste confere que todo som do catálogo tem crédito.
  5. **Nome e ícone próprios**, sem repetir o de outro som, e o nome traduzido nos dois idiomas.
- O que já se sabe que falta (não bloqueia a publicação): `storm` e `campfire` têm emenda suspeita; `crickets` tem só 4 s; o loudness dos sons vai de -43 a -14,7 LUFS. Está registrado no DK-Life.

## Consequências

- O app continua pequeno e o seletor cabe em poucas linhas.
- Cada som é revisado individualmente, o que dá trabalho mas mantém o nível.
- A pressão por "mais sons" vira uma decisão explícita: para mudar este ADR, escreva outro.
