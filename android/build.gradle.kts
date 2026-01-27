allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.layout.buildDirectory.value(rootProject.layout.projectDirectory.dir("../build"))

subprojects {
    val rootBuildDir = rootProject.layout.buildDirectory.get().asFile
    val projectDir = project.layout.projectDirectory.asFile
    
    val rootDrive = rootBuildDir.absolutePath.take(1).lowercase()
    val projectDrive = projectDir.absolutePath.take(1).lowercase()

    // Only relocate build directory if on the same drive (fixes Windows cross-drive issues)
    if (rootDrive == projectDrive) {
        val newSubprojectBuildDir: Directory = rootProject.layout.buildDirectory.get().dir(project.name)
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    }
}


subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
