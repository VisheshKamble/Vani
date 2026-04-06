import org.gradle.api.file.Directory
import org.gradle.api.tasks.Delete
import org.gradle.api.tasks.compile.JavaCompile

allprojects {
    repositories {
        google()
        mavenCentral()
    }

    gradle.projectsEvaluated {
        tasks.withType<JavaCompile> {
            val compileTask = this
            compileTask.options.compilerArgs.addAll(
                listOf(
                    "-Xlint:-unchecked",
                    "-Xlint:-deprecation",
                    "-Xlint:-options"
                )
            )
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    // Keep external plugin projects (e.g. pub cache on C:) on their default
    // build directories to avoid cross-drive path errors on Windows.
    val rootDirPath = rootProject.projectDir.absolutePath
    val subprojectDirPath = project.projectDir.absolutePath
    if (subprojectDirPath.startsWith(rootDirPath, ignoreCase = true)) {
        val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    } else {
        // Force plugin modules outside the repo (e.g. pub cache) to build in
        // their own folder so Java/Kotlin tasks don't mix different drive roots.
        project.layout.buildDirectory.value(project.layout.projectDirectory.dir("build"))
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
