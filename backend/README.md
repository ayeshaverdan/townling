# Townling backend

Thin Django + DRF server (design doc §18). The game's economic simulation runs
client-side; this server owns only accounts, parental consent, content-manifest
delivery, digest emails, and challenge aggregation. Data minimization is a
product principle (design doc §16).

- **Python:** 3.13 · **Django:** 5.2 · **DRF:** 3.16 · **DB:** SQLite (dev)
- **Deps:** managed by [uv](https://docs.astral.sh/uv/) — see `pyproject.toml` / `uv.lock`.

## Layout

```
backend/
├── config/          Django project (settings, urls, wsgi, asgi)
├── apps/
│   └── core/         Hello-world health + API-root endpoints (+ smoke tests)
├── manage.py
└── pyproject.toml
```

## Run

Preferred (from the repo root, via Docker): `make up`, then the API is at
http://localhost:8000/api/.

Host-native (for tests / quick iteration):

```bash
uv sync --dev
uv run python manage.py migrate
uv run python manage.py runserver
uv run pytest -q          # smoke tests
uv run ruff check .       # lint
```

## Endpoints (bootstrap)

| Method | Path | Purpose |
|---|---|---|
| GET | `/api/` | API root — lists endpoints |
| GET | `/api/health/` | Liveness/readiness check |
| GET | `/admin/` | Django admin |
