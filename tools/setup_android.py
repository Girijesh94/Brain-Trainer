"""Provision build dependencies inside RecallQuest/tools, without global installs."""
import hashlib
import json
import os
import shutil
import subprocess
import urllib.request
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SDK = ROOT / 'android-sdk'
SDK.mkdir(exist_ok=True)

def download(url, destination, checksum=None):
    if not destination.exists():
        print('Downloading', destination.name, flush=True)
        urllib.request.urlretrieve(url, destination)
    if checksum:
        actual = hashlib.sha256(destination.read_bytes()).hexdigest()
        if actual != checksum: raise RuntimeError('Checksum mismatch: '+destination.name)

jdks = list((ROOT / 'jdk').glob('*/bin/java.exe')) if (ROOT/'jdk').exists() else []
if not jdks:
    with urllib.request.urlopen('https://api.github.com/repos/adoptium/temurin17-binaries/releases/latest', timeout=60) as response:
        release = json.load(response)
    asset = next(a for a in release['assets'] if a['name'].startswith('OpenJDK17U-jdk_x64_windows_hotspot_') and a['name'].endswith('.zip'))
    checksum_asset = next(a for a in release['assets'] if a['name'] == asset['name'] + '.sha256.txt')
    with urllib.request.urlopen(checksum_asset['browser_download_url'],timeout=60) as response:
        checksum = response.read().decode().split()[0]
    package = {'link':asset['browser_download_url'],'checksum':checksum}
    archive = ROOT/'jdk17.zip'
    download(package['link'], archive, package['checksum'])
    with zipfile.ZipFile(archive) as z: z.extractall(ROOT/'jdk')
    jdks = list((ROOT/'jdk').glob('*/bin/java.exe'))
JDK = jdks[0].parent.parent
sdkmanager = SDK/'cmdline-tools'/'latest'/'bin'/'sdkmanager.bat'
if not sdkmanager.exists():
    archive = ROOT/'android-command-tools.zip'
    # Official package checksum from developer.android.com/studio.
    download('https://dl.google.com/android/repository/commandlinetools-win-15859902_latest.zip',archive,'90ae805d20434428bffcb699c290860f19bb5f66a67e6b330067e3de801fb04a')
    with zipfile.ZipFile(archive) as z: z.extractall(ROOT/'android-command-unpack')
    (SDK/'cmdline-tools').mkdir(exist_ok=True)
    shutil.move(str(ROOT/'android-command-unpack'/'cmdline-tools'), str(SDK/'cmdline-tools'/'latest'))
environment = os.environ.copy()
environment['JAVA_HOME'] = str(JDK)
environment['ANDROID_HOME'] = str(SDK)
environment['PATH'] = str(JDK/'bin') + os.pathsep + environment.get('PATH','')
print('Installing Android APK build packages', flush=True)
command = [str(sdkmanager),f'--sdk_root={SDK}', 'platform-tools','build-tools;35.0.1','platforms;android-35']
result = subprocess.run(command, input='y\n'*100, text=True, env=environment)
if result.returncode: raise RuntimeError('Android SDK setup failed')
keystore = ROOT/'debug.keystore'
if not keystore.exists():
    subprocess.run([str(JDK/'bin'/'keytool.exe'),'-genkeypair','-keystore',str(keystore),'-storepass','android','-keypass','android','-alias','androiddebugkey','-dname','CN=Android Debug,O=Android,C=US','-keyalg','RSA','-keysize','2048','-validity','10000'],check=True,env=environment)
(ROOT/'android-paths.json').write_text(json.dumps({'jdk':str(JDK),'sdk':str(SDK),'keystore':str(keystore)},indent=2))
print('Android build dependencies ready.', flush=True)
