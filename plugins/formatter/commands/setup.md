---
description: One-shot setup that integrates the formatter profile into the current Java project via Spotless.
---

# formatter — Project Setup

You are helping the user wire up **Spotless + the active formatter profile**
into their Java project so the plugin's hooks can do their job.

The active profile defaults to `java-alipay` (Alipay Convention / Alibaba Java
Coding Guidelines). If the user has set `BUDDY_FORMATTER_PROFILE` to something
else, use that profile id instead and locate the corresponding file under
`${CLAUDE_PLUGIN_ROOT}/config/profiles/<id>.xml`.

## Your responsibilities

1. **Detect project layout**
   - Look for `pom.xml` (Maven), `build.gradle` / `build.gradle.kts` (Gradle),
     in that order, starting from the current working directory and walking
     up if needed.
   - If neither is found, tell the user this plugin only supports Maven /
     Gradle Java projects today and stop.

2. **Copy the profile into the project**
   - Source: `${CLAUDE_PLUGIN_ROOT}/config/profiles/<profile-id>.xml`
     (default: `java-alipay.xml`).
   - Destination: `<project-root>/config/<profile-id>-formatter.xml` (e.g.
     `config/java-alipay-formatter.xml`). Create the `config/` directory if
     missing.
   - If the destination already exists, diff it against the source. If
     unchanged, skip. If different, ask the user before overwriting.

3. **Inject the Spotless plugin declaration**
   - For **Maven**: open `pom.xml`. If `spotless-maven-plugin` is not already
     present inside `<build><plugins>`, insert the snippet from
     `${CLAUDE_PLUGIN_ROOT}/templates/spotless-snippet-pom.xml`. Replace the
     placeholder `<!-- PROFILE_FILE -->` with the actual destination path you
     used in step 2. Be surgical — do not reformat the rest of the file.
   - For **Gradle (Groovy)**: append the content of
     `${CLAUDE_PLUGIN_ROOT}/templates/spotless-snippet-gradle.groovy` to
     `build.gradle`, after substituting the placeholder, unless
     `com.diffplug.spotless` is already applied.
   - For **Gradle (Kotlin DSL)**: translate the Groovy snippet to Kotlin DSL
     and append to `build.gradle.kts`, unless already applied.

4. **Verify the integration**
   - Run a dry check:
     - Maven: `mvn -q spotless:check` — it's OK if it reports violations; we
       just want the plugin to resolve.
     - Gradle: `./gradlew -q spotlessCheck` (or system `gradle` if no wrapper).
   - If the command cannot even resolve the plugin, surface the full error
     and stop.

5. **Write a summary**
   - Tell the user:
     - the profile that is now active
     - where the profile XML was placed
     - what was added to `pom.xml` / `build.gradle`
     - that from now on every `Edit`/`Write` on relevant files will be
       auto-formatted
     - how to toggle strict mode: `export BUDDY_FORMATTER_STRICT=1`
     - how to temporarily disable: `export BUDDY_FORMATTER_DISABLED=1`
     - how to switch profiles: `export BUDDY_FORMATTER_PROFILE=<id>` (only
       `java-alipay` ships with v1)

## Guardrails

- **Never** overwrite files without explicit consent if they already exist
  with different content.
- **Never** edit files outside the detected project root.
- If `pom.xml` looks auto-generated or heavily customized (e.g. Spring Boot
  parent with complex profiles), show the user the snippet and ask to
  confirm before inserting, rather than editing blindly.
- If you cannot complete the setup cleanly, print the exact two things the
  user needs to paste in manually:
  1. The Spotless plugin block, with `<!-- PROFILE_FILE -->` substituted.
  2. The `cp` command to copy the profile XML into their project.

Proceed step by step and print each action as you go.
