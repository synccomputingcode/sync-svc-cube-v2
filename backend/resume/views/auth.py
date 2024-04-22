from venv import logger

from allauth.socialaccount.helpers import complete_social_login
from allauth.socialaccount.models import SocialApp, SocialLogin
from allauth.socialaccount.providers.github.views import GitHubOAuth2Adapter
from allauth.socialaccount.providers.google.views import GoogleOAuth2Adapter
from allauth.socialaccount.providers.oauth2.views import OAuth2Adapter
from django.contrib.auth import get_user_model, logout
from django.http.request import HttpRequest
from django.views.decorators.csrf import csrf_exempt
from ninja import Router, Schema

from resume.views.schema.user import UserSchema

"""
Lots of hacking around allauth to get social login working with rest style endpoints.
The library is designed around the django template system, hence the hacking.

Mostly did this to avoid having to reimplement integration with the Django user system.
"""
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
        login: SocialLogin = adapter.complete_login(
            request, app, token, response=response
        )
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
    "/github-login",
    response={200: UserSchema, 404: Error, 400: Error},
    auth=None,
)
@csrf_exempt
def github_login(request, payload: SocialLoginSchema):
    try:
        app = SocialApp.objects.get(name="Github")
    except SocialApp.DoesNotExist:
        return 404, {"message": "Github app does not exist"}
    adapter = GitHubOAuth2Adapter(request)
    client = adapter.client_class(
        request=request,
        consumer_key=app.client_id,
        consumer_secret=app.secret,
        access_token_method=adapter.access_token_method,
        access_token_url=adapter.access_token_url,
        callback_url=None,
        scope=adapter.get_provider().get_scope(request),
        scope_delimiter=adapter.scope_delimiter,
        headers=adapter.headers,
        basic_auth=adapter.basic_auth,
    )
    access_token = client.get_access_token(payload.access_token)
    resp = social_login(request, app, adapter, access_token["access_token"])
    return resp


@router.post(
    "/log-out",
    response={200: None},
)
def log_out(request):
    logout(request)
    return 200, None
