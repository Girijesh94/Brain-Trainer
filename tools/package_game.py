"""Validate native artifacts and package a clean source archive."""
import hashlib
import json
import os
import shutil
import struct
import subprocess
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT/'builds'
paths = json.loads((ROOT/'tools'/'android-paths.json').read_text())
environment = os.environ.copy()
environment['JAVA_HOME'] = paths['jdk']
environment['PATH'] = str(Path(paths['jdk'])/'bin') + os.pathsep + environment.get('PATH','')
apk = BUILD/'android'/'RecallQuest.apk'
exe = BUILD/'windows'/'RecallQuest.exe'
pck = BUILD/'windows'/'RecallQuest.pck'
build_tools = Path(paths['sdk'])/'build-tools'/'35.0.1'

def run(command, log):
    result = subprocess.run([str(x) for x in command],capture_output=True,text=True,env=environment)
    (BUILD/log).write_text(result.stdout + result.stderr,encoding='utf-8')
    if result.returncode: raise RuntimeError(f'Validation failed: {command[0]} (see {log})')
    return result.stdout

signature = run([build_tools/'apksigner.bat','verify','--verbose',apk],'android-signature.log')
alignment = run([build_tools/'zipalign.exe','-c','-v','4',apk],'android-alignment.log')
metadata = run([build_tools/'aapt.exe','dump','badging',apk],'android-manifest.log')
permissions = run([build_tools/'aapt.exe','dump','permissions',apk],'android-permissions.log')
with zipfile.ZipFile(apk) as z:
    assert z.testzip() is None, 'Corrupt APK archive'
    names = z.namelist()
    architectures = [a for a in ['arm64-v8a','x86_64'] if any(n.startswith(f'lib/{a}/') for n in names)]
    assert len(architectures) == 2, 'Expected both native Android architectures'
    assert any(n.endswith('GODOT_COPYRIGHT.txt') for n in names), 'Missing third-party attribution'
with exe.open('rb') as f:
    assert f.read(2) == b'MZ'
    f.seek(0x3c)
    offset = struct.unpack('<I',f.read(4))[0]
    f.seek(offset)
    assert f.read(4) == b'PE\x00\x00'
    assert struct.unpack('<H',f.read(2))[0] == 0x8664

# Ship documentation and notices alongside the portable Windows executable.
for name in ['README.md','VERIFICATION.md','VISUALS.md','THIRD_PARTY_NOTICES.md']:
    shutil.copyfile(ROOT/name,BUILD/'windows'/name)
for name in ['GODOT_LICENSE.txt','GODOT_COPYRIGHT.txt','OFL.txt']:
    shutil.copyfile(ROOT/'game'/'assets'/name,BUILD/'windows'/name)
with zipfile.ZipFile(BUILD/'RecallQuest-Windows.zip','w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    for file in (BUILD/'windows').iterdir():
        if file.is_file(): z.write(file,'RecallQuest/'+file.name)

with zipfile.ZipFile(BUILD/'RecallQuest-Source.zip','w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    for file in (ROOT/'game').rglob('*'):
        if file.is_file() and '.godot' not in file.parts:
            z.write(file,'RecallQuest/'+str(file.relative_to(ROOT)).replace('\\','/'))
    for name in ['README.md','PLAN.md','VERIFICATION.md','VISUALS.md','THIRD_PARTY_NOTICES.md','.gitignore']:
        z.write(ROOT/name,'RecallQuest/'+name)
    for name in ['build.ps1','fetch_templates.py','setup_android.py','configure_exports.py','make_assets.py','package_game.py']:
        z.write(ROOT/'tools'/name,'RecallQuest/tools/'+name)

def sha256(file):
    h = hashlib.sha256()
    with file.open('rb') as f:
        for chunk in iter(lambda:f.read(1024*1024),b''): h.update(chunk)
    return h.hexdigest()

assert pck.read_bytes()[:4] == b'GDPC', 'Missing or invalid companion game pack'
assert sha256(exe) == sha256(ROOT/'tools'/'godot'/'Godot_v4.6.3-stable_win64.exe'), 'The officially signed engine binary was modified'
report = json.loads((BUILD/'test-results.json').read_text())
report['windows'] = {'architecture':'x86_64','native_executable_valid':True,'official_signed_engine_unchanged':True,'companion_game_pack':True,'smoke_test_log':(BUILD/'windows-smoke.log').read_text() if (BUILD/'windows-smoke.log').exists() else '', 'sha256':sha256(exe),'game_data_sha256':sha256(pck)}
report['android'] = {'architectures':architectures,'signature_verified':True,'alignment_verified':True,'archive_verified':True,'metadata':[l for l in metadata.splitlines() if l.startswith(('package:','sdkVersion:','targetSdkVersion:','application-label:','native-code:'))], 'permissions':permissions.strip(),'physical_device_tested':False,'sha256':sha256(apk)}
report['ios'] = {'shared_source':True,'export_preset':True,'built':False,'reason':'Requires macOS with Xcode and an Apple signing team'}
(BUILD/'verification.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('Verified Windows x86_64 executable; Android signature, alignment, archive and native libraries.')
print('\n'.join(report['android']['metadata']))
for file in [BUILD/'RecallQuest-Windows.zip',apk,BUILD/'RecallQuest-Source.zip']:
    print(file.name, round(file.stat().st_size/1048576,1),'MB')
