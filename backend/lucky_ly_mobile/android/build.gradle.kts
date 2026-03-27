
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Workaround for older plugins (e.g. ar_flutter_plugin 0.7.3) that do not
// declare android.namespace, which is required by AGP 8+.
fun org.gradle.api.Project.applyNamespaceWorkaroundIfNeeded() {
    if (name != "ar_flutter_plugin") return

    val androidExt = extensions.findByName("android") ?: return
    val getNamespace = androidExt.javaClass.methods.find { it.name == "getNamespace" }
    val setNamespace = androidExt.javaClass.methods.find {
        it.name == "setNamespace" && it.parameterTypes.size == 1
    }

    val currentNamespace = getNamespace?.invoke(androidExt) as? String
    if (currentNamespace.isNullOrBlank()) {
        setNamespace?.invoke(androidExt, "io.carius.lars.ar_flutter_plugin")
    }
}

subprojects {
    if (state.executed) {
        applyNamespaceWorkaroundIfNeeded()
    } else {
        afterEvaluate {
            applyNamespaceWorkaroundIfNeeded()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
