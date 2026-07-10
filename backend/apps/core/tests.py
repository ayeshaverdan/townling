"""Smoke tests proving the bootstrap endpoints respond."""

import pytest
from django.test import Client


@pytest.mark.django_db
def test_health_ok() -> None:
    response = Client().get("/api/health/")
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"
    assert body["service"] == "townling-backend"


@pytest.mark.django_db
def test_api_root_ok() -> None:
    response = Client().get("/api/")
    assert response.status_code == 200
    assert response.json()["service"] == "townling-backend"
