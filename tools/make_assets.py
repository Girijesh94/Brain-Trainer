from pathlib import Path
import urllib.request

ROOT = Path(__file__).resolve().parents[1] / 'game' / 'assets'
ROOT.mkdir(parents=True, exist_ok=True)
SHAPES = {
'Key': '<circle cx="35" cy="36" r="17" fill="ACCENT"/><path d="M48 48L81 81M68 68l11-11M77 77l10-10"/>',
'Apple': '<path d="M55 35C21 13 17 59 36 81Q50 94 57 85Q72 96 86 76C105 42 78 19 55 35Z" fill="ACCENT"/><path d="M55 35Q52 17 66 13M61 23Q81 9 87 23Q75 34 61 23Z"/>',
'Candle': '<rect x="35" y="43" width="40" height="44" rx="7" fill="ACCENT"/><path d="M29 88h54M55 42v-9"/><path d="M55 10Q33 35 55 34Q74 32 55 10Z" fill="#f8d986"/>',
'Bicycle': '<circle cx="29" cy="74" r="20"/><circle cx="84" cy="74" r="20"/><path d="M29 74l23-35 20 35H29l-5-35h15M72 74L62 27h14M45 36h16"/>',
'Book': '<path d="M18 22Q37 17 55 31Q74 17 93 22V83Q73 80 55 92Q36 80 18 83Z" fill="ACCENT"/><path d="M55 31v61M27 35l17 6M27 48l17 6M66 41l17-6M66 54l17-6"/>',
'Umbrella': '<path d="M13 51Q55 0 97 51Q83 42 69 51Q55 42 41 51Q27 42 13 51Z" fill="ACCENT"/><path d="M55 14v67Q55 100 74 91M41 51Q41 24 55 14Q69 24 69 51"/>',
'Turtle': '<ellipse cx="54" cy="55" rx="29" ry="26" fill="ACCENT"/><circle cx="91" cy="55" r="12"/><path d="M33 34L24 23M34 76L24 86M74 34l9-11M75 76l8 10M24 55H13M53 32l-14 24 15 23 15-23Z"/>',
'Scissors': '<circle cx="30" cy="79" r="14" fill="ACCENT"/><circle cx="77" cy="79" r="14" fill="ACCENT"/><path d="M37 67L84 17M69 68L24 17"/><circle cx="53" cy="51" r="4" fill="#eef8ff"/>',
'Camera': '<rect x="15" y="32" width="81" height="56" rx="9" fill="ACCENT"/><path d="M32 32l8-15h27l8 15"/><circle cx="56" cy="60" r="18"/><path d="M82 42h4"/>',
'Mug': '<path d="M21 36h51v40Q48 100 21 76Z" fill="ACCENT"/><path d="M72 43h13Q106 60 72 72M33 22v-9M49 22v-9M65 22v-9"/>',
'Leaf': '<path d="M22 88Q5 16 94 15Q96 97 22 88Z" fill="ACCENT"/><path d="M20 92L78 32M43 70l-7-24M59 53l24 8"/>',
'Rocket': '<path d="M38 72Q20 35 57 9Q92 36 76 72Z" fill="ACCENT"/><circle cx="57" cy="40" r="10"/><path d="M38 50L19 72l19-3M75 50l17 22-16-3M45 84l-5 16M57 81v23M68 84l5 16"/>',
'Clock': '<circle cx="55" cy="55" r="37" fill="ACCENT"/><path d="M55 30v26l19 12M55 18v6M55 87v6M18 55h6M87 55h6"/>',
'Balloon': '<ellipse cx="55" cy="40" rx="28" ry="32" fill="ACCENT"/><path d="M55 72l-5 10h10ZM55 83Q37 91 59 104M43 23Q35 27 36 37"/>',
'Headphones': '<path d="M19 60V48Q20 3 55 14Q91 4 92 48v12"/><rect x="17" y="48" width="19" height="36" rx="7" fill="ACCENT"/><rect x="73" y="48" width="19" height="36" rx="7" fill="ACCENT"/>',
'Compass': '<circle cx="55" cy="58" r="35"/><path d="M47 23v-9h16v9M55 30l14 29-14 28-14-28Z" fill="ACCENT"/><path d="M41 59h28"/>',
'Fish': '<path d="M77 53Q39 14 14 55Q42 94 77 56L96 31v48Z" fill="ACCENT"/><circle cx="32" cy="51" r="3" fill="#eef8ff"/><path d="M45 35Q60 55 45 77"/>',
'Diamond': '<path d="M31 18h48l23 27-47 55L8 45Z" fill="ACCENT"/><path d="M8 45h94M31 18L41 45l14 55 15-55 9-27M41 45l14-27 15 27"/>',
'Flower': '<path d="M55 68v35M55 89Q30 65 25 84Q35 99 55 89M55 83Q84 62 89 77Q80 95 55 83"/><circle cx="55" cy="24" r="16" fill="ACCENT"/><circle cx="77" cy="42" r="16" fill="ACCENT"/><circle cx="68" cy="66" r="16" fill="ACCENT"/><circle cx="41" cy="66" r="16" fill="ACCENT"/><circle cx="32" cy="42" r="16" fill="ACCENT"/><circle cx="55" cy="45" r="15" fill="#f8d986"/>',
'Tent': '<path d="M55 18L9 91h92Z" fill="ACCENT"/><path d="M55 18v73M55 49L34 91h42ZM48 14l7 4 7-4"/>',
'Star': '<path d="M55 10l14 28 31 5-22 22 5 32-28-15-28 15 5-32L10 43l31-5Z" fill="ACCENT"/>',
'Glasses': '<circle cx="29" cy="61" r="21"/><circle cx="81" cy="61" r="21"/><path d="M50 61q5-10 10 0M8 58V32h11M102 58V32H91"/>',
'Pencil': '<path d="M25 70L75 20l17 17-50 50-23 6Z" fill="ACCENT"/><path d="M25 70l17 17M68 27l17 17M19 93l10-3-7-7"/>',
'Sailboat': '<path d="M16 78h81L80 96H34Z" fill="ACCENT"/><path d="M55 12v66M49 22L17 68h32ZM62 34l31 34H62Z" fill="ACCENT"/>'
}
COLORS = ['#83e6c1','#f8ce80','#afa6ff','#87c8fb','#f39cae','#96d6ae']
for index, (name, shape) in enumerate(SHAPES.items()):
    (ROOT / (name.lower() + '.svg')).write_text('<svg xmlns="http://www.w3.org/2000/svg" width="112" height="112" viewBox="0 0 112 112"><g stroke="#edf7ff" stroke-width="3.7" stroke-linecap="round" stroke-linejoin="round" fill="none">'+shape.replace('ACCENT',COLORS[index % len(COLORS)])+'</g></svg>')
icon = '''<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512"><rect width="512" height="512" rx="112" fill="#0d172b"/><ellipse cx="256" cy="257" rx="180" ry="80" transform="rotate(-30 256 257)" stroke="#84e6c1" stroke-width="16" fill="none"/><circle cx="256" cy="256" r="105" fill="#84e6c1"/><path d="M207 253v-22M298 253v-22" stroke="#0d172b" stroke-width="16" stroke-linecap="round"/><path d="M228 280q28 24 56 0" stroke="#0d172b" stroke-width="12" stroke-linecap="round" fill="none"/><circle cx="99" cy="172" r="25" fill="#afa6ff"/><path d="M391 87l8 22 23 8-23 8-8 22-8-22-23-8 23-8Z" fill="#f8ce80"/></svg>'''
(ROOT/'icon.svg').write_text(icon)
(ROOT/'mascot.svg').write_text(icon.replace('<rect width="512" height="512" rx="112" fill="#0d172b"/>',''))
for filename, url in {
'Outfit.ttf':'https://raw.githubusercontent.com/google/fonts/main/ofl/outfit/Outfit%5Bwght%5D.ttf',
'OFL.txt':'https://raw.githubusercontent.com/google/fonts/main/ofl/outfit/OFL.txt',
}.items():
    try:
        urllib.request.urlretrieve(url, ROOT/filename)
        print('Saved', filename)
    except Exception as error:
        print('Font download failed, game will use its bundled fallback:',error)
print('Created 24 original object illustrations and the Recall Quest mascot.')
