from pathlib import Path

path = Path("android/app/build.gradle.kts")
text = path.read_text(encoding="utf-8")

replacements = {
    "compileSdk = flutter.compileSdkVersion": "compileSdk = 36",
    "compileSdk = 34": "compileSdk = 36",
    "compileSdk = 35": "compileSdk = 36",
}

changed = False
for old, new in replacements.items():
    if old in text:
        text = text.replace(old, new)
        changed = True

if not changed and "compileSdk = 36" not in text:
    raise SystemExit("Could not locate compileSdk in android/app/build.gradle.kts")

path.write_text(text, encoding="utf-8")
print("Configured Android compileSdk 36.")
