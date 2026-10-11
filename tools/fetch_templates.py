"""Fetch only the native templates needed, with HTTP range requests."""
import io
import urllib.request
import zipfile
from pathlib import Path

URL = 'https://github.com/godotengine/godot/releases/download/4.6.3-stable/Godot_v4.6.3-stable_export_templates.tpz'
DEST = Path(__file__).parent / 'templates'

class RemoteZip(io.RawIOBase):
    def __init__(self, url):
        request = urllib.request.Request(url, method='HEAD')
        with urllib.request.urlopen(request, timeout=40) as response:
            self.url = response.url
            self.length = int(response.headers['Content-Length'])
        self.position = 0
    def seekable(self): return True
    def readable(self): return True
    def tell(self): return self.position
    def seek(self, offset, whence=0):
        self.position = offset if whence == 0 else self.position + offset if whence == 1 else self.length + offset
        return self.position
    def read(self, size=-1):
        if size < 0: size = self.length - self.position
        size = min(size, self.length - self.position)
        if size <= 0: return b''
        end = self.position + size - 1
        request = urllib.request.Request(self.url, headers={'Range': f'bytes={self.position}-{end}'})
        with urllib.request.urlopen(request, timeout=120) as response:
            if response.status != 206:
                raise RuntimeError('Server did not honor range request; full template download intentionally stopped.')
            result = response.read()
        if len(result) != size: raise RuntimeError('Incomplete ranged download')
        self.position += len(result)
        return result

DEST.mkdir(exist_ok=True)
with zipfile.ZipFile(RemoteZip(URL)) as archive:
    print('\n'.join(archive.namelist()), flush=True)
    for member in archive.infolist():
        name = Path(member.filename).name
        if name in {'windows_release_x86_64.exe', 'windows_debug_x86_64.exe', 'android_release.apk', 'android_debug.apk', 'version.txt', 'android_source.zip'}:
            target = DEST / name
            if target.exists() and target.stat().st_size == member.file_size:
                continue
            print(f'Downloading {name}: {member.compress_size / 1048576:.1f} MB', flush=True)
            target.write_bytes(archive.read(member))
            print(f'OK {name}', flush=True)
