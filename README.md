# Townling

A privacy-first, ad-free financial life-simulation game for children.
See [`.ai/context/`](.ai/context/) for the design document and systems spec, and
[`CLAUDE.md`](CLAUDE.md) for a fast orientation.

## Repository layout

```
townling/
├── backend/    Django + DRF API (SQLite). Thin server: accounts, consent,
│               content manifest, digests, challenge aggregation. Deps via uv.
├── game/       Godot 4 client. Exports to HTML5 for the web fun-test.
├── .ai/        Authoritative design document + systems spec.
├── docker-compose.yml
└── Makefile    One-command developer workflow.
```

The economic simulation runs **client-side** (offline-first, data-minimal). The
backend is deliberately thin — see design doc §18.

## Prerequisites

- **Docker Desktop** (Compose v2) — runs the whole stack.
- **uv** — only needed for running backend tests/lint on the host.
- **Godot 4** (host install) — only needed to *develop* the game in the editor.
  The web build is produced inside Docker, so you don't need Godot just to run it.

## Quickstart

```bash
make up      # build + start everything
make open    # open both URLs (macOS)
```

Then:

- **Game (web build):** http://localhost:8080/
- **Backend API:** http://localhost:8000/api/ · health: http://localhost:8000/api/health/

Stop with `make down`. Run `make` (or `make help`) to list every command.

## Common commands

| Command | Does |
|---|---|
| `make up` | Build (if needed) and start the stack |
| `make down` | Stop and remove containers |
| `make logs` | Tail all logs |
| `make test` | Run backend tests |
| `make lint` / `make fmt` | Ruff lint / format the backend |
| `make migrate` | Apply Django migrations |
| `make superuser` | Create a Django admin user |
| `make game-build` | Rebuild only the Godot web export |
| `make clean` | Tear down and remove images + build artifacts |

## Developing the game

Runtime development happens in the **Godot editor** (open `game/project.godot`).
Docker is only used to produce the shareable HTML5 build for the fun-test / CI.
Pin the export version with `GODOT_VERSION` in `.env`.

## Versions

Python 3.13 · Django 5.2 · DRF 3.16 · Godot 4.4.1 · nginx 1.27.
Backend Python deps are pinned in `backend/uv.lock`.
