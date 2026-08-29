# kloop

Engenharia de loop para o [opencode](https://opencode.ai): agentes especializados em cada fase da programação **debatem entre si em rounds** para resolver conflitos e produzir código correto.

## Como funciona

```
Usuário → /kloop [pedido]
            │
            └─ kloop (orquestrador)
                 │
                 ├─ Round N (1..5):
                 │     1. kloop-architect  → design (round 1) ou resposta a conflitos de design
                 │     2. kloop-coder      → implementa / resolve conflitos por ID
                 │     3. ┬ kloop-reviewer → conflitos semânticos ou APPROVED   (paralelo,
                 │       │ kloop-analyst   → riscos security/perf ou CLEAR        contexto
                 │       └ kloop-tester    → lint/typecheck/build/test ou GREEN   isolado)
                 │     4. kloop funde conflitos, registra o round, decide: convergiu? próximo round?
                 │
                 └─ Convergência (APPROVED + CLEAR + GREEN) ou round 5 → ESCALATED
```

Os críticos rodam **isolados**: não veem o histórico do debate nem a saída uns dos outros — cada um critica com independência total. O orquestrador é o único que funde, roteia e persiste.

## Papéis

| Agent | Mode | Modelo | Permissão | Papel |
|---|---|---|---|---|
| `kloop` | primary | glm-5.3 | — | Orquestra rounds, funde conflitos, decide convergência |
| `kloop-architect` | subagent | glm-5.3 | — | Design: contratos, APIs, arquivos, tradeoffs |
| `kloop-coder` | subagent | glm-5.3 | edit+bash | Diffs mínimos; resolve conflitos por ID |
| `kloop-reviewer` | subagent | glm-5.3 | edit: deny | Crítica semântica request × design × diff |
| `kloop-analyst` | subagent | glm-5.2 | edit: deny | STRIDE-lite + heurísticas de performance |
| `kloop-tester` | subagent | glm-5.3-flash | edit: deny | Executa checks; falhas viram conflitos |

Modelos do provider `zhipuai-coding-plan` (GLM Coding Plan da Z.ai).

## Protocolo

### Formato de conflito

Todo crítico emite conflitos no formato exato (o orquestrador funde e renumera por round):

```
C-N | severidade: critical|major|minor | tipo: design|code|test|security|performance | evidência: ... | correção esperada: ...
```

### Rounds

1. **Round 1**: architect desenha → coder implementa → reviewer + analyst + tester criticam em paralelo.
2. **Round N**: orquestrador funde conflitos (dedupe, renumera `C-01..C-nn`, classifica design × code) → se houver conflito de design, architect revisa primeiro → coder resolve o resto → crítica paralela novamente.
3. **Roteamento**: conflito `design` → architect; `code`/`test`/`security`/`performance` → coder (security/perf têm prioridade).

### Terminação

| Veredito | Condição |
|---|---|
| **CONVERGED** | reviewer APPROVED + analyst CLEAR + tester GREEN, zero critical/major abertos |
| **ESCALATED** | round 5 encerrado com critical/major abertos (lista de decisões para o dev) |
| **DEADLOCK** | architect detecta requisitos contraditórios — aborta imediatamente |

Minor conflicts podem persistir como *known issues* no veredito final.

## Artefatos

Cada loop persiste o debate completo em `spec/loops/[NNN]-[slug]/debate.md`: request, design, arquivos alterados e tabela de conflitos (OPEN/RESOLVED) por round, com veredito final.

## Instalação

A instalação no opencode é **por cópia** — este repo é o source of truth:

```bash
git clone git@github.com:K77-dev/kloop.git
cd kloop && ./install.sh
```

Reinstale (`./install.sh`) após qualquer alteração no repo. Os arquivos instalados vivem em `~/.config/opencode/agents/kloop*.md` e `~/.config/opencode/commands/kloop.md`.

## Uso

```
/kloop adicionar paginação cursor-based no endpoint de listagem de pedidos
```

Ou selecione o agent `kloop` em `/agents` e descreva o pedido. O orquestrador pergunta se algo estiver ambíguo antes de iniciar o loop.

## Relação com o kspec

Independente e coexistente. O kspec cobre o fluxo espec-documentado (PRD → Tech Spec → Tasks → QA → PR); o kloop é codificação iterativa com debate. Se `spec/tasks/[slug]/prd.md` existir, o architect do kloop usa como contexto opcional.
