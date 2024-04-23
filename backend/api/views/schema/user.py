from ninja import Schema


class UserSchema(Schema):
    id: int
    first_name: str
    last_name: str
    email: str
    avatar_url: str | None = None

    @staticmethod
    def resolve_avatar_url(obj):
        return obj.profile.avatar_url
