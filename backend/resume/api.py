from ninja import NinjaAPI, Schema

api = NinjaAPI()


class HealthCheckSchema(Schema):
    message: str


@api.get("/healthcheck", response=HealthCheckSchema)
def hello(request):
    return {"message": "Hello World"}
