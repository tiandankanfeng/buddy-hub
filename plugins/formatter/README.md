# formatter

> A Claude Code plugin that auto-formats source files after each edit, with
> a final style-check gate when Claude finishes a turn. v1 ships with the
> **Alipay Convention** profile for Java (derived from the Alibaba Java
> Coding Guidelines); the profile architecture supports adding more
> languages and styles over time.

[![Claude Code plugin](https://img.shields.io/badge/Claude%20Code-plugin-6E56CF)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)]()

## What it does

- **PostToolUse hook** — after Claude edits any file in the active profile's
  language, runs Spotless (`spotless:apply`) on just that one file, using the
  profile XML shipped with the plugin.
- **Stop hook** — before Claude declares a task done, runs `spotless:check`
  over every relevant file changed in the session. Warns by default, blocks
  in strict mode.
- **`/formatter:setup` command** — one-shot integration that copies the
  profile into your project and wires up the Spotless Maven / Gradle plugin.
- **Authoring skill** — a language-specific `SKILL.md` that Claude consults
  while writing code, covering the parts of the convention the formatter
  can't auto-fix (naming, structure, idioms).

## Bundled profiles

| Profile id    | Language | Style                                                      |
|---------------|----------|------------------------------------------------------------|
| `java-alipay` | Java     | Alipay Convention (Alibaba Java Coding Guidelines) — default |

More profiles can be added by dropping a new XML/config file into
`config/profiles/` and a matching skill under `skills/`. See
[Adding a profile](#adding-a-profile).

## Requirements

- Claude Code **v2.1** or later.
- A **Maven** or **Gradle** Java project (for the default profile). Multi-
  module repos work as long as each module can run `spotless:apply`
  independently.
- `mvn` or `gradle` (or `./gradlew`) on PATH.
- `jq` (preferred) or `python3` on PATH — used to parse hook stdin.
- JDK 8+ (whatever your project already needs).

## Installation

### Option A — From buddy-hub Marketplace (recommended)

```bash
# 1. Add the Marketplace (one-time)
claude plugin marketplace add KaverinX/buddy-hub

# 2. Install the plugin
claude plugin install formatter@buddy-hub
```

### Option B — Local development

```bash
git clone https://github.com/KaverinX/buddy-hub.git ~/buddy-hub
claude plugin install ~/buddy-hub/plugins/formatter
```

### Update

```bash
# Update the Marketplace
claude plugin marketplace update KaverinX/buddy-hub

# Update the plugin
claude plugin update formatter@buddy-hub
```

## First-time project setup

Open a Claude Code session inside your Java project and run:

```
/formatter:setup
```

Claude will:

1. Detect whether the project is Maven or Gradle.
2. Copy the active profile's XML into `<project>/config/`.
3. Add the `spotless-maven-plugin` / `com.diffplug.spotless` declaration to
   your build file (asking before overwriting anything).
4. Run a one-off `spotless:check` to confirm the plugin resolves.

From then on, every edit Claude makes to a matching file is auto-formatted.

## Configuration

All switches are environment variables; no config file needed.

| Variable                   | Effect |
|----------------------------|--------|
| `BUDDY_FORMATTER_PROFILE`     | Profile id to activate (default: `java-alipay`). |
| `BUDDY_FORMATTER_STRICT=1`    | Treat format failures as hook blocks (exit 2). Use in CI or when you want "no dirty commit" guarantees. |
| `BUDDY_FORMATTER_DEBUG=1`     | Verbose logging to stderr. |
| `BUDDY_FORMATTER_DISABLED=1`  | Skip the hooks entirely. Useful for one-off sessions on non-standard projects. |

Set them in your shell, in a `.envrc`, or in the Claude Code launch command.

## How it works internally

```
┌──────────────────┐   ┌────────────────────┐   ┌────────────────────┐
│ Claude edits a   │   │ PostToolUse hook   │   │ mvn spotless:apply │
│ file matching    │──▶│ format.sh          │──▶│  -DspotlessFiles=  │
│ the active       │   │ (reads stdin JSON, │   │      <abs path>    │
│ profile          │   │ finds project root)│   │                    │
└──────────────────┘   └────────────────────┘   └────────────────────┘

┌──────────────────┐   ┌────────────────────┐
│ Claude ends the  │   │ Stop hook          │
│ turn             │──▶│ check.sh           │
│                  │   │ (git diff + check) │
└──────────────────┘   └────────────────────┘
```

The `java-alipay` profile XML is an Eclipse JDT `CodeFormatterProfile`
(version 11), ~270 settings encoding the Alipay / Alibaba layout convention.
Spotless embeds an Eclipse JDT engine and reads this XML directly — no IDE
needed.

## Adding a profile

1. Drop a new profile file into `config/profiles/<id>.xml` (or `.toml`,
   `.json`, etc. — file format depends on the target language's formatter).
2. Extend `profile_language()` and `profile_handles_file()` in
   `scripts/lib/common.sh` with the new id and its file extensions.
3. Optionally add a `skills/<id>/SKILL.md` with authoring guidance.
4. Bump `version` in `.claude-plugin/plugin.json`.

## Troubleshooting

**The hook runs but nothing happens.** Set `BUDDY_FORMATTER_DEBUG=1` and edit a
matching file. You should see `[formatter]` lines in the Claude Code
verbose log (toggle with `Ctrl+O`).

**Hook logs `Spotless is not configured`.** Run `/formatter:setup`
inside the project once.

**Hook is slow (>10s per save).** First-time Maven invocation downloads the
Spotless JARs and the Eclipse JDT engine. Subsequent runs go through the
local `~/.m2` cache and should be 2–5 seconds. If it's still slow, install
`mvnd` (the Maven daemon) — the hook uses it automatically when present.

**Gradle users: single-file formatting takes a whole Gradle startup.** Keep
the Gradle daemon enabled (on by default in 8.x+) and use `./gradlew` rather
than a system `gradle`.

**The hook is blocking my session.** Unset `BUDDY_FORMATTER_STRICT` or set
`BUDDY_FORMATTER_DISABLED=1`.

## Uninstalling

```bash
claude plugin uninstall formatter@buddy-hub
```

To also remove Spotless from your project, delete the plugin block from
your `pom.xml` / `build.gradle` and remove the profile XML under `config/`.

## Contributing

PRs and issues welcome. If you want to tweak the `java-alipay` profile, edit
`config/profiles/java-alipay.xml` — it's a standard Eclipse JDT profile you
can open in any Eclipse-compatible IDE (IntelliJ via Eclipse Formatter
plugin, Eclipse itself, VS Code via redhat.java, etc.).

## License

MIT. See `LICENSE`.

## Credits

- **`java-alipay` profile**: derives from the publicly-known Alibaba Java
  Coding Guidelines layout rules.
- **Formatting engine**: [Spotless](https://github.com/diffplug/spotless).
- **Eclipse JDT core**: Eclipse Foundation.
