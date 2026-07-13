import org.gradle.api.DefaultTask
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.file.FileTree
import org.gradle.api.file.FileSystemOperations
import org.gradle.api.tasks.OutputDirectory
import org.gradle.api.tasks.TaskAction
import javax.inject.Inject

plugins {
    id("com.android.application")
}

val mnAnimat3DRoot = providers.gradleProperty("mnAnimat3DRoot").orNull
    ?.let { file(it).canonicalFile }
    ?: rootProject.projectDir.parentFile.canonicalFile

abstract class SyncMNAnimat3DWebAssets @Inject constructor(
    private val fileSystemOperations: FileSystemOperations
) : DefaultTask() {
    @get:Internal
    abstract val webRoot: DirectoryProperty

    @get:InputFiles
    @get:PathSensitive(PathSensitivity.RELATIVE)
    val webFiles: FileTree
        get() = webRoot.asFileTree.matching {
            include(
                "index.html",
                "styles.css",
                "manifest.webmanifest",
                "service-worker.js",
                "src/**",
                "lib/**",
                "assets/icon.svg",
                "assets/characters/LICENSES.md",
                "assets/characters/rain/ATTRIBUTION.txt",
                "assets/characters/rain/controller-manifest.json",
                "assets/characters/rain/rain-lumina.glb",
                "assets/characters/snow/ATTRIBUTION.txt",
                "assets/characters/snow/controller-manifest.json",
                "assets/characters/snow/snow-lumina.glb",
                "assets/characters/blocky/ATTRIBUTION.txt",
                "assets/characters/blocky/KENNEY_LICENSE.txt",
                "assets/characters/blocky/controller-manifest.json",
                "assets/characters/blocky/blocky-character.glb",
                "assets/characters/blocky/Textures/texture-a.png",
                "assets/environment/furniture-kit/KENNEY_LICENSE.txt",
                "assets/environment/furniture-kit/catalog.json",
                "assets/environment/furniture-kit/models/**"
            )
            exclude("android/**")
        }

    @get:OutputDirectory
    abstract val outputDirectory: DirectoryProperty

    @TaskAction
    fun syncAssets() {
        val outDir = outputDirectory.get().asFile
        fileSystemOperations.sync {
            from(webFiles)
            into(File(outDir, "www"))
            includeEmptyDirs = false
        }
    }
}

val syncMNAnimat3DWebAssets = tasks.register<SyncMNAnimat3DWebAssets>("syncMNAnimat3DWebAssets") {
    group = "mnanimat3d"
    description = "Copia o editor web, personagens e catálogo de cenário para o APK."
    webRoot.set(layout.dir(provider { mnAnimat3DRoot }))
    outputDirectory.set(layout.buildDirectory.dir("generated/mnanimat3dWebAssets"))
}

android {
    namespace = "studio.mnanimat3d.app"
    compileSdk = 36

    defaultConfig {
        applicationId = "studio.mnanimat3d.app"
        minSdk = 33
        targetSdk = 36
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    androidResources {
        noCompress += listOf("glb")
    }
}

androidComponents {
    onVariants(selector().all()) { variant ->
        variant.sources.assets?.addGeneratedSourceDirectory(syncMNAnimat3DWebAssets) { it.outputDirectory }
    }
}
