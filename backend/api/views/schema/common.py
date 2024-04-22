from ninja import Schema


class BaseSchema(Schema):
    id: int
    created_at: str
    updated_at: str
