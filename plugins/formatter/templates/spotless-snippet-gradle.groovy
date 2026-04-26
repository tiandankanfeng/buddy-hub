// formatter — append this to build.gradle.
// For build.gradle.kts, translate to Kotlin DSL (only the plugins{} and string
// interpolation syntax change; the spotless{} block structure is identical).
//
// Replace PROFILE_FILE below with the path to the profile XML you copied
// into your project (for the default profile: config/java-alipay-formatter.xml).

plugins {
    id 'com.diffplug.spotless' version '6.25.0'
}

spotless {
    java {
        target 'src/main/java/**/*.java', 'src/test/java/**/*.java'
        eclipse('4.26').configFile "${rootDir}/PROFILE_FILE"
        removeUnusedImports()
        trimTrailingWhitespace()
        endWithNewline()
    }
}
