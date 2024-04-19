from venv import logger

from allauth.socialaccount.helpers import complete_social_login
from allauth.socialaccount.models import SocialApp, SocialLogin
from allauth.socialaccount.providers.google.views import GoogleOAuth2Adapter
from allauth.socialaccount.providers.oauth2.views import OAuth2Adapter
from django.contrib.auth import get_user_model, logout
from django.http.request import HttpRequest
from django.views.decorators.csrf import csrf_exempt
from ninja import Router, Schema

from resume.views.schema.user import UserSchema

router = Router()


class Error(Schema):
    message: str


class SocialLoginSchema(Schema):
    access_token: str


def social_login(
    request,
    app: SocialApp,
    adapter: OAuth2Adapter,
    access_token: str,
    response=None,
    connect=True,
):
    if not isinstance(request, HttpRequest):
        request = request._request
    token = adapter.parse_token({"access_token": access_token})
    token.app = app
    try:
        response = response or {}
        login: SocialLogin = adapter.complete_login(request, app, token, response)
        login.token = token
        complete_social_login(request, login)
    except Exception as e:
        logger.exception("Could not complete social login")
        return 400, {"message": f"Could not complete social login: {e}"}
    if not login.is_existing:
        User = get_user_model()
        user = User.objects.filter(email=login.user.email).first()
        if user:
            if connect:
                login.connect(request, user)
            else:
                return 400, {"errors": ["Email already exists"]}
        else:
            login.lookup()
            login.save(request)
    return 200, login.user


@router.post(
    "/google-login",
    response={200: UserSchema, 404: Error, 400: Error},
    auth=None,
)
@csrf_exempt
def google_login(request, payload: SocialLoginSchema):
    try:
        app = SocialApp.objects.get(name="Google")
    except SocialApp.DoesNotExist:
        return 404, {"message": "Google app does not exist"}
    adapter = GoogleOAuth2Adapter(request)
    resp = social_login(request, app, adapter, payload.access_token)
    return resp


@router.post(
    "/log-out",
    response={200: None},
)
def log_out(request):
    logout(request)
    return 200, None
