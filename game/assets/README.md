# Assets

Art and other Godot resources for the Townling client. Referenced from
scenes/scripts as `res://assets/...`.

**Visual direction: low-poly 3D on a fixed isometric camera (2.5D)** — see the
visual-direction update in design doc §18. Built from CC0 KayKit packs.

## Current packs

| Pack | Location | What it is | Status |
|------|----------|-----------|--------|
| KayKit City Builder Bits | `city/` | Modern low-poly 3D: 8 buildings (A–H), 5 cars, roads, traffic lights, props | **Keeper** — fits the modern town |
| KayKit Adventurers | `characters/` | 6 rigged low-poly characters + weapons + animation rigs | **Placeholder** — medieval-fantasy/weapons; replace before art-judged playtest |

Licenses: both CC0. See [ATTRIBUTIONS.md](ATTRIBUTIONS.md).

## Structure & formats

Each pack ships every model in four formats — `fbx/`, `fbx(unity)/`, `gltf/`,
`obj/` — plus a shared texture atlas. **Godot imports glTF (`.gltf`/`.glb`)
natively, so glTF is the format we use.** The `fbx/`, `fbx(unity)/`, and `obj/`
duplicates are **git-ignored** (see repo `.gitignore`) to keep the repo lean —
they remain on disk locally but are not versioned. If you re-clone, only glTF
comes back; re-download the pack if you need the other formats.

Key glTF locations:
- City models: `city/Assets/gltf/*.gltf` (+ `.bin`, `citybits_texture.png`)
- Playable characters: `characters/Characters/gltf/*.glb`
- Character animations: `characters/Animations/gltf/Rig_Medium/*.glb`
- Weapons/props: `characters/Assets/gltf/*.gltf`

## Conventions

- Import through the **Godot editor** so it generates `.import` sidecars
  (import settings + stable UIDs). **Commit the `.import` files**; the `.godot/`
  import cache is git-ignored (expected).
- Keep the shared texture atlas next to the models that reference it.
