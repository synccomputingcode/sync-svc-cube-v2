import logging

from ninja import NinjaAPI, Schema
from ninja.security import django_auth

from resume.views.auth import router as auth_router
from resume.views.user import router as user_router

logger = logging.getLogger(__name__)
api = NinjaAPI(auth=django_auth, csrf=True)
api.add_router("/auth/", router=auth_router)
api.add_router("/user/", router=user_router)


class HealthCheckSchema(Schema):
    message: str


@api.get("/healthcheck", response=HealthCheckSchema, auth=None)
def hello(request):
    return {"message": "Hello World"}


@api.exception_handler(Exception)
def handle_exception(request, exc):
    logger.error("Unhandled exception during request", exc_info=exc)
    return 500, {"message": "Internal Server Error"}
