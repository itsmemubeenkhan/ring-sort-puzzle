allprojects {
    repositories {
        maven { url = uri("file:///home/hatch/local-m2") }
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Offline build fix: AGP disables its lint annotation-extraction tasks in this
// setup, which breaks downstream syncReleaseLibJars (missing typedefs.txt).
// Lint itself is disabled (see app/build.gradle.kts), so force-enabling these
// tasks is safe: they now run with the cached lint artifacts and produce the
// expected outputs.
gradle.taskGraph.whenReady {
    allTasks.filter { it.name.contains("extract") && it.name.contains("Annotations") }.forEach {
        println("FORCING ENABLED: ${it.path} (was enabled=${it.enabled})")
        it.enabled = true
    }
}
