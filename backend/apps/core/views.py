"""Core hello-world endpoints for the bootstrap.

These prove the stack is alive end to end. Real endpoints (consent, content
manifest, digests, challenge aggregation — design doc §18) land on top of this.
"""

import django
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.decorators import api_view


@api_view(["GET"])
def api_root(request: Request) -> Response:
    """Entry point listing available API endpoints."""
    return Response(
        {
            "service": "townling-backend",
            "message": "Hello from Townling. Learning is earning.",
            "endpoints": {
                "health": request.build_absolute_uri("health/"),
            },
        }
    )


@api_view(["GET"])
def health(request: Request) -> Response:
    """Liveness/readiness check."""
    return Response(
        {
            "status": "ok",
            "service": "townling-backend",
            "version": "0.1.0",
            "django": django.get_version(),
        }
    )
