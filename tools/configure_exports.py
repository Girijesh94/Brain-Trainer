from pathlib import Path
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
paths = json.loads((ROOT/'tools'/'android-paths.json').read_text())
engine = ROOT/'tools'/'godot'
(engine/'_sc_').touch()
config = engine/'editor_data'
config.mkdir(exist_ok=True)
settings = '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
for setting,key in [('export/android/java_sdk_path','jdk'),('export/android/android_sdk_path','sdk'),('export/android/debug_keystore','keystore')]:
    settings += setting+'='+json.dumps(paths[key].replace('\\','/'))+'\n'
settings += 'export/android/debug_keystore_user="androiddebugkey"\nexport/android/debug_keystore_pass="android"\n'
(config/'editor_settings-4.6.tres').write_text(settings)
templates = config/'export_templates'/'4.6.3.stable'
templates.mkdir(parents=True,exist_ok=True)
for source in (ROOT/'tools'/'templates').iterdir():
    if not (templates/source.name).exists():
        shutil.copyfile(source,templates/source.name)
print('Configured native Android exports in the isolated portable editor.')
