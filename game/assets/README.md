# Assets

Art and other Godot resources for the Townling client. Referenced from
scenes/scripts as `res://assets/...`.

**Visual direction: low-poly 3D on a fixed isometric camera (2.5D)** — see the
visual-direction update in design doc §18.

## Current packs

| Pack | Location | What it is | Status |
|------|----------|-----------|--------|
| Kenney Starter Kit: City Builder | `kenney/` | Low-poly 3D city on a 1×1 grid: 5 buildings, roads, grass, tree tiles, pavement, fountain — one shared `colormap.png` | **In use** — the town |
| KayKit Adventurers | `characters/` | 6 rigged low-poly characters + weapons + animation rigs | **Placeholder** — medieval-fantasy; replace before art-judged playtest |

Licenses (all commercial-safe): see [ATTRIBUTIONS.md](ATTRIBUTIONS.md).

## Kenney city kit

- **Grid:** 1×1 units, origin-centred, tiles sit on `y=0`.
- **Buildings:** `building-small-a/b/c/d` (heights 0.95–1.75), `building-garage` (0.55).
- **Ground:** `grass`, `pavement`, roads (`road-straight`, `-corner`, `-intersection`, `-split`, `-straight-lightposts`).
- **Detail:** `grass-trees`, `grass-trees-tall`, `pavement-fountain`.
- One shared texture: `kenney/Textures/colormap.png` (referenced by every `.glb`).
- We use the **models only** — not the kit's GridMap builder scripts. The town is
  composed procedurally in `scripts/diorama.gd`.

## Conventions

- Import through the **Godot editor** so it generates `.import` sidecars
  (import settings + stable UIDs). **Commit the `.import` files**; the `.godot/`
  import cache is git-ignored (expected).
- Keep `colormap.png` under `kenney/Textures/` so the `.glb` relative paths resolve.
