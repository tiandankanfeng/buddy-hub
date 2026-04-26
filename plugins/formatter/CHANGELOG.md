# Changelog — formatter

All notable changes to the `formatter` plugin are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this plugin adheres to [Semantic Versioning](https://semver.org/).

## [1.0.0] — 2026-04-21

### Added
- Initial release.
- **`java-alipay` profile** — Eclipse JDT formatter profile encoding the
  Alipay Convention (Alibaba Java Coding Guidelines). Bundled at
  `config/profiles/java-alipay.xml`.
- **`PostToolUse` hook** (`scripts/format.sh`) — single-file format on every
  `Edit` / `Write` / `MultiEdit` for files matching the active profile.
- **`Stop` hook** (`scripts/check.sh`) — end-of-turn `spotless:check` over
  changed files of the active profile's language.
- **`/formatter:setup` command** — one-shot project integration (copies
  the active profile XML + adds the Spotless plugin to Maven/Gradle).
- **`java-alipay` skill** — authoring guidance for Java convention rules
  the formatter cannot auto-fix.
- Maven and Gradle (Groovy + Kotlin DSL) Spotless snippet templates.
- `BUDDY_FORMATTER_PROFILE` / `BUDDY_FORMATTER_STRICT` / `BUDDY_FORMATTER_DEBUG` /
  `BUDDY_FORMATTER_DISABLED` environment switches.
- Smoke-test suite (`tests/smoke.sh`) covering routing, env toggles, and
  recursion guard.
