# Townling backend — Django + DRF on Python 3.13, deps managed by uv.
FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim

# uv/runtime hygiene. The project env lives OUTSIDE the app dir so that a
# docker-compose bind-mount of ./backend:/app does not shadow the installed venv.
ENV UV_PROJECT_ENVIRONMENT=/opt/venv \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/opt/venv/bin:$PATH"

WORKDIR /app

# Install dependencies first (cached layer) using only the lock + manifest.
COPY pyproject.toml uv.lock* ./
RUN uv sync --no-install-project --dev

# Copy the application source.
COPY . .

EXPOSE 8000

# migrate then serve. runserver is fine for the bootstrap / fun-test phase.
CMD ["sh", "-c", "python manage.py migrate --noinput && python manage.py runserver 0.0.0.0:8000"]
