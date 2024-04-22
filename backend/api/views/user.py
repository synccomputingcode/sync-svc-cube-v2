from django.http import HttpRequest
from ninja import Router

from api.views.schema.user import UserSchema

router = Router()


@router.get(
    "/me",
    response={200: UserSchema},
)
def identify(request: HttpRequest):
    return request.user
