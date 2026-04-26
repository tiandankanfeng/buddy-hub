---
name: java-alipay
description: "Authoring guidance for writing Java code that adheres to the Alipay Convention (derived from the Alibaba Java Coding Guidelines). Use this skill when generating, editing, or reviewing Java code in a project where the formatter plugin is installed with the java-alipay profile active (the default). Covers the layout rules Spotless will auto-enforce, plus the naming, structural, and idiom rules the formatter cannot fix automatically."
---

# Java — Alipay Convention Authoring Guide

The `formatter` plugin (profile `java-alipay`) will automatically fix
**layout** issues on every edit via Spotless. You do not need to hand-format
code. However, the formatter cannot fix **naming**, **structure**, or
**idiom** issues — so keep the rules below in mind while writing.

## Layout (auto-fixed by Spotless — don't fight it)

- **Indent**: 4 spaces, never tabs.
- **Line width**: 100 columns. Long lines are re-wrapped.
- **Braces**: K&R style, `{` at end of line.
- **Spaces**: one space after every comma; spaces around binary operators;
  no space after unary operators; no space inside parentheses.
- **Blank lines**: one between methods, one after imports, zero before the
  first class member.
- **`@formatter:off` / `@formatter:on`** comments exist but are disabled by
  default (`use_on_off_tags=false`). Don't rely on them.

## Naming (the formatter does NOT fix these)

- Classes: `UpperCamelCase` — e.g. `OrderService`, never `orderService` or
  `OrderSERVICE`.
- Methods and local variables: `lowerCamelCase` — e.g. `getUserById`.
- Constants (`static final`): `UPPER_SNAKE_CASE` — e.g. `MAX_RETRY_COUNT`.
- Packages: all lowercase, no underscores — e.g. `com.alipay.order.service`.
- Abstract classes: prefix `Abstract` or `Base`.
- Exceptions: suffix `Exception`.
- Test classes: suffix `Test`.
- Boolean fields: **no** `is` prefix in POJOs (serialization frameworks get
  confused). Prefer `deleted` over `isDeleted`.

## Structure

- **No magic numbers**. Extract to a named constant if the value is reused or
  semantically meaningful.
- **Avoid `Executors.newFixedThreadPool` / `newCachedThreadPool`**. Use
  `ThreadPoolExecutor` directly with an explicit bounded queue.
- **Never use `Date` for new code**; use `java.time.LocalDateTime` /
  `Instant`.
- **Collection literals**: prefer `List.of(...)` / `Map.of(...)` for
  immutable small collections (Java 9+).
- **Log placeholders**, never string concatenation:
  `log.info("user {} logged in", userId);` — not
  `log.info("user " + userId ...)`.
- **Avoid `SELECT *`** in SQL, JPA, or MyBatis queries — list columns
  explicitly.
- **`equals` on constants first**: `"ADMIN".equals(role)` — never
  `role.equals("ADMIN")`.

## Imports

- No wildcard imports (`import java.util.*;`).
- One import per line.
- Imports are grouped and alphabetized; the formatter will reorder them.

## Javadoc

- All `public` classes and `public` methods exposed as API need Javadoc.
- Use `@param`, `@return`, `@throws` consistently.
- The formatter does **not** reformat Javadoc content by default
  (`comment.format_javadoc_comments=false`), so write it cleanly yourself.

## What happens when you finish editing

Nothing on your end — the `PostToolUse` hook runs `spotless:apply` for you
automatically, and the `Stop` hook does a final `spotless:check` before the
turn ends. If either fails, you'll see a stderr line prefixed
`[formatter]`.
