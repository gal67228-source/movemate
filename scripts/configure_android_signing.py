from pathlib import Path

app_build = Path("android/app/build.gradle.kts")
text = app_build.read_text(encoding="utf-8")

imports = "import java.io.FileInputStream\nimport java.util.Properties\n\n"
if "import java.util.Properties" not in text:
    text = imports + text

properties_block = '''val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

'''
if "val keystoreProperties = Properties()" not in text:
    text = text.replace("android {\n", properties_block + "android {\n", 1)

signing_block = '''    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

'''
if 'create("release")' not in text:
    text = text.replace("    buildTypes {\n", signing_block + "    buildTypes {\n", 1)

old = 'signingConfig = signingConfigs.getByName("debug")'
new = ('signingConfig = if (keystorePropertiesFile.exists()) '
       'signingConfigs.getByName("release") else signingConfigs.getByName("debug")')
if old in text:
    text = text.replace(old, new)

app_build.write_text(text, encoding="utf-8")
