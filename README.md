# buddy-hub

**[English](./README.md)** | **[中文](./README_zh.md)**

> A Claude Code Plugin Marketplace by Velpro

A curated collection of Claude Code plugins focused on **developer workflow automation**, **code quality enforcement**, and **multi-agent collaboration**.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

---

## Quick Start

### Install Marketplace

```bash
claude plugin marketplace add KaverinX/buddy-hub
```

### Update Marketplace

```bash
claude plugin marketplace update KaverinX/buddy-hub
```

### Remove Marketplace

```bash
claude plugin marketplace remove KaverinX/buddy-hub
```

---

## Plugin Management

Once the marketplace is added, manage individual plugins:

```bash
# Install a plugin
claude plugin install flowsmith@buddy-hub

# Update a plugin
claude plugin update flowsmith@buddy-hub

# Uninstall a plugin
claude plugin uninstall flowsmith@buddy-hub

# List installed plugins
claude plugin list
```

---

## Available Plugins

### 🔨 [flowsmith](./plugins/flowsmith) — State-Machine-Driven Development SOP

**Role: Core Orchestrator** | `v1.0.0` | 6 commands, 4 agents, 3 skills

Enforces a strict five-phase development cycle: **PLANNING → ARCHITECTURE → IMPLEMENTATION → OPTIMIZATION → REVIEW → DONE**. Prevents "skip thinking, jump to coding" by requiring explicit input/output contracts at each stage.

**Key Features:**
- FSM-enforced phase transitions — no skipping allowed
- 4 independent-context subagents: Optimizer + Architecture / Security / Logic reviewers
- 3 phase-specific skills guiding planning, architecture design, and implementation discipline
- PostToolUse hook for automatic state validity checks
- Cross-task knowledge accumulation via `.sop/lessons.md`

```bash
claude plugin install flowsmith@buddy-hub
```

See [flowsmith README](./plugins/flowsmith/README.md) for details.

---

### 🔍 [code-archaeologist](./plugins/code-archaeologist) — Legacy Code Archaeology & Refactoring Aid

**Role: Legacy Code Analyst** | `v1.0.0` | 6 commands, 3 agents, 1 skill

Before refactoring, splitting, or deleting legacy code, dispatches three independent archaeologists to perform deep due diligence across three dimensions — preventing 90% of refactoring accidents.

**Key Features:**
- Three-dimensional parallel analysis: History + Dependency + Intent
- Detects hidden dependencies invisible to IDEs (reflection, config-driven calls, serialization contracts)
- Generates "uncrossable red lines" to prevent refactoring regressions
- Auto-injects archaeological conclusions into flowsmith's planning constraints
- Decision matrix produces actionable refactoring strategy recommendations

```bash
claude plugin install code-archaeologist@buddy-hub
```

---

### 👥 [co-review](./plugins/co-review) — Team Collaboration Review

**Role: Team Health Inspector** | `v1.0.0` | 4 commands, 3 agents, 1 skill

Horizontal code review for multi-author scenarios. Instead of reviewing individual code quality (flowsmith handles that), analyzes team collaboration health, interface conflicts, and completion signals.

**Key Features:**
- Three-layer architecture: Contribution profiling + Completion assessment + Collaboration risk detection
- Independent-context subagents prevent analysis contamination
- Pure-terminal TUI dashboard (`bash scripts/tui/dashboard.sh`)
- Privacy-first: per-person feedback strictly isolated — no cross-person comparison, no attitude judgment
- 5-level merge strategy: `merge-now` → `staged` → `coordinate` → `block` → `escalate`

```bash
claude plugin install co-review@buddy-hub
```

---

### 🎨 [formatter](./plugins/formatter) — Code Style Guardian

**Role: Code Style Guardian** | `v1.1.0` | 1 command, 2 hooks, 1 skill

Edit-time auto-formatting plus session-end style gate. Injects team coding conventions into Claude's editing actions, eliminating style debates.

**Key Features:**
- Built-in Alipay/Alibaba Java coding convention profile (~270 Eclipse JDT rules)
- PostToolUse hook: auto-format on every file edit
- Stop hook: global style check on all changed files before session ends
- Supports both Maven and Gradle projects with one-shot setup
- Extensible profile architecture — drop new XML to add language support

```bash
claude plugin install formatter@buddy-hub
```

---

## Ecosystem Architecture

The plugins form an interconnected ecosystem, not isolated tools:

```
                    ┌─────────────────────────────┐
                    │    🔨 flowsmith (Core)       │
                    │  State-machine orchestrator  │
                    │  PLAN → ARCH → IMPL → DONE  │
                    └──────┬──────────┬────────────┘
                           │          │
              Hook: detect │          │ Hook: detect
              refactor     │          │ multi-author
              intent       │          │ after review
                           ▼          ▼
              ┌────────────────┐  ┌────────────────┐   ┌────────────────┐
              │ 🔍 code-       │  │ 👥 co-review   │   │ 🎨 formatter   │
              │ archaeologist  │  │                │   │                │
              │                │  │ Reads .sop/*   │   │  Orthogonal    │
              │ Injects into ──┼──▶ Reads .arch/*  │   │  No state      │
              │ plan.md        │  │ for red lines  │   │  interaction   │
              └────────────────┘  └────────────────┘   └────────────────┘
                           │          │
                           ▼          ▼
                    ┌─────────────────────────────┐
                    │   📚 Shared Knowledge Layer  │
                    │  .sop/lessons.md — all R/W   │
                    │  .archaeology/report.md      │
                    └─────────────────────────────┘
```

### Plugin Relationships

| From | To | Mechanism | Description |
|------|----|-----------|-------------|
| flowsmith | code-archaeologist | Hook trigger | Detects refactor/split/migrate keywords → suggests `/arch-init` |
| flowsmith | co-review | Hook trigger | After `/sop-review` completes + multi-author detected → suggests `/scope-review` |
| code-archaeologist | flowsmith | `/arch-handoff` | Injects conclusions into `plan.md` constraints & prerequisites |
| code-archaeologist | co-review | Shared artifacts | Red line list feeds into collaboration risk detection |
| co-review | flowsmith | Context read | Reads `.sop/` artifacts for more precise analysis |
| co-review | code-archaeologist | Context read | Reads `.archaeology/report.md` for boundary violation checks |
| formatter | *(none)* | Orthogonal | Operates independently — no state interaction with other plugins |
| **All plugins** | `lessons.md` | Shared R/W | Cross-task knowledge accumulation and injection |

---

## Project Structure

```
buddy-hub/
├── .claude-plugin/
│   └── marketplace.json          # Marketplace metadata
├── .github/workflows/
│   └── static.yml                # GitHub Pages deployment
├── index.html                    # Interactive marketplace website
├── README.md                     # English documentation
├── README_zh.md                  # Chinese documentation
├── LICENSE                       # MIT License
└── plugins/
    ├── flowsmith/                # SOP workflow engine
    │   ├── commands/             # 6 slash commands
    │   ├── agents/               # 4 independent-context subagents
    │   ├── skills/               # 3 phase-specific skills + reference docs
    │   └── hooks/                # State validation hook
    ├── code-archaeologist/       # Legacy code archaeology
    │   ├── commands/             # 6 slash commands
    │   ├── agents/               # 3 dimensional archaeologists
    │   ├── skills/               # Refactoring strategy skill + decision matrix
    │   └── hooks/                # Refactor intent detection hook
    ├── co-review/                # Team collaboration review
    │   ├── commands/             # 4 slash commands
    │   ├── agents/               # 3 independent analyzers
    │   ├── skills/               # Merge strategy skill + scoring rubric
    │   ├── hooks/                # Multi-author detection hook
    │   └── scripts/tui/          # Terminal dashboard
    └── formatter/                # Code style guardian
        ├── commands/             # 1 setup command
        ├── skills/               # Java-Alipay authoring guidance
        ├── hooks/                # Format + check hooks
        └── config/profiles/      # Eclipse JDT formatter profiles
```

---

## Roadmap

| Status | Plugin | Description | Connects To |
|--------|--------|-------------|-------------|
| 🟢 Development | **release-captain** | Standardized release orchestration with multi-language Changelog sync, semantic versioning, and release gates. Bridges flowsmith's DONE phase to "shipped". | flowsmith, co-review |
| 🟡 Backlog | **knowledge-base v2** | Cross-project experience hub. Aggregates all plugins' `lessons.md` into a global semantic index with vector DB search and injection. | flowsmith, code-archaeologist, co-review |
| 🔵 Research | **Project Insight UI** | Web-based interactive dashboard evolved from co-review's TUI. Real-time code evolution curves, team health heatmaps, and refactoring risk radar. | co-review, code-archaeologist, flowsmith |

---

## Vision

We believe AI-assisted coding should not mean "write more bugs faster." It should mean **"build truly reliable software with engineering discipline."**

1. **Process as Guardrails** — State machines enforce "think before code." Every phase has explicit contracts. No skipping.
2. **Knowledge Compounds** — `lessons.md` is a living knowledge base. Every task completion, every review finding, every archaeological conclusion flows back — so the next task stands on the shoulders of history.
3. **Multi-Agent Isolation** — Each analysis dimension runs in independent context. Security review isn't distracted by optimization suggestions. Team analysis isn't contaminated by individual bias.
4. **Privacy First** — Team collaboration analysis strictly isolates per-person data. No horizontal comparison, no attitude judgment, no leaking others' info.
5. **Archaeology Before Action** — Understand before refactoring: why was it written this way? Who depends on it? Which complexity is necessary? This framework prevents 90% of refactoring accidents.
6. **Full Development Lifecycle** — From idea to production: Planning → Design → Code → Format → Archaeology → Review → Team Collaboration → Release. Every stage has a dedicated plugin.

---

## Author

**Velpro**
Email: [xvelpro8@gmail.com](mailto:xvelpro8@gmail.com)
GitHub: [@KaverinX](https://github.com/KaverinX)

---

## License

MIT © Velpro
