from pathlib import Path

settings = Path('android/settings.gradle.kts')
app_build = Path('android/app/build.gradle.kts')

settings_text = settings.read_text(encoding='utf-8')
plugin_line = '    id("com.google.gms.google-services") version "4.4.4" apply false\n'
if 'com.google.gms.google-services' not in settings_text:
    marker = 'plugins {\n'
    settings_text = settings_text.replace(marker, marker + plugin_line, 1)
    settings.write_text(settings_text, encoding='utf-8')

app_text = app_build.read_text(encoding='utf-8')
app_plugin_line = '    id("com.google.gms.google-services")\n'
if 'com.google.gms.google-services' not in app_text:
    marker = 'plugins {\n'
    app_text = app_text.replace(marker, marker + app_plugin_line, 1)
    app_build.write_text(app_text, encoding='utf-8')
