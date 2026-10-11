# Recall Quest 1.2 — native visuals

All four requested skills were read and applied as visual and lifecycle guidance. Their JavaScript/React runtimes do not run in a Godot scene. Recall Quest remains a native offline game. All shipped shaders, the Quest SVG mask, meshes and effect scripts are original implementations; no upstream shader code or browser library is copied, ported or vendored.

## Sources inspected on 11 October 2026

| Skill / source | Resolved upstream HEAD | Native effect |
| --- | --- | --- |
| [ShaderGradient](https://github.com/ruucm/shadergradient) | `68bdd740037a11c639f8b91fd775949c71d718d0` | Original aurora shader with slow teal, violet and rose fields. Frozen under reduced motion and suspended when unfocused. |
| [Paper liquid-logo](https://github.com/paper-design/liquid-logo) | `689bb38a1e0d5a6a8baf2d34847635eefde19994` | Original metal shader on an authored Quest SVG. The game name stays readable outside the shader. Reduced motion uses the static SVG. |
| [Liquid Glass JS](https://github.com/dashersw/liquid-glass-js) | `78cb6ccb0b9987bb60a88b14ccbd13a9e6e8ab2a` | Original rounded refraction sampling native screen decoration. Text and controls stay opaque and separate. No document capture or WebGL context. |
| [React Three Fiber](https://github.com/pmndrs/react-three-fiber) | `9e53355ce499ea518ac3729de7fd4dcc06d8cdb9` | Native Node3D sculpture: three rings, a nucleus and eight satellites. SubViewport capped at 480x320; freed on navigation, frozen under reduced motion, suspended offscreen/unfocused. |

No versions of these four browser packages are installed or bundled. Runtime: Godot 4.6.3, GL Compatibility renderer. This is a native adaptation of the skills' direction, not direct package integration.

**Paper source licence notice:** the referenced liquid-logo repository uses the [PolyForm Shield License 1.0.0](https://polyformproject.org/licenses/shield/1.0.0/), not MIT. No Paper source is distributed with this game. Godot and Outfit notices remain included in the game and downloads.

## Interaction and motion

- Home: one Play/Continue button, a rotating memory core and three illustrated stages. At most 45 words.
- Intros: three illustrated verbs and one action. At most 35 words.
- Objects: sequential entry fades, a countdown, visible selection ticks and untimed recall. Extra picks remain penalised.
- Cards: a glass question card, hidden answer, honest comparison and a five-stage review ladder. Review dates retain their existing rules.
- Story: readable original story, hidden during recall; five explicit self-check ideas. The decorative atmosphere dims during play.
- Result: a brief spark burst and score count-up. Missed objects are available under Details.
- No rapid flashes, camera shake, automatic answer reveals or forced tutorials. Motion never conveys required gameplay information.
- Reduce all motion freezes gradient/metal/3D, removes fades/count-up and leaves static result decoration.
- Simple visuals replaces 3D with the SVG and removes decorative shaders. This is a manual performance fallback, not automatic GPU detection.

## Validation limits

Actual native Windows images at portrait and compact sizes were inspected. Shared gameplay and effect lifecycle tests pass. Android signatures and alignment are verified, but phone GPU performance, thermal behaviour and touch keyboards have not been tested here. No installable iOS build is available without macOS/Xcode/signing.
