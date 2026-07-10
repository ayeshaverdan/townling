# Townling game client

Godot 4 (GDScript) client — a 2D hub-and-card UI game (design doc §18). Currently
a hello-world scene; the real game is a single-screen city diorama of tappable
buildings (design doc §5).

- **Engine:** Godot 4.4 · **Renderer:** GL Compatibility (so the HTML5 export runs everywhere)
- **Orientation:** portrait, mobile-first (720×1280 base)

## Layout

```
game/
├── project.godot        Project config
├── scenes/main.tscn     Entry scene (bootstrap hello-world)
├── scripts/main.gd      Entry script
├── export_presets.cfg   Web (HTML5) export preset
├── icon.svg
├── Dockerfile           Headless export -> nginx serve
└── nginx.conf
```

## Develop

Open `project.godot` in the **Godot 4 editor** on your machine. This is where
runtime game development happens — Docker is not involved in the edit loop.

## Web build (fun-test / CI)

The HTML5 build is produced inside Docker (no host Godot needed):

```bash
# from the repo root
make game-build        # build only the game image
make up                # build + serve at http://localhost:8080/
```

Under the hood: a headless Godot container runs
`godot --headless --export-release "Web" build/index.html`, and nginx serves the
result with the cross-origin-isolation headers Godot web builds want. Pin the
version via `GODOT_VERSION` in the repo-root `.env`.

> Note: the `barichello/godot-ci` image is amd64; on Apple Silicon it runs under
> emulation (a harmless build-time platform warning). The served nginx image is
> native.
