from ninja import NinjaAPI

api = NinjaAPI()


@api.get("/healthcheck")
def hello(request):
    return {"message": "Hello World"}
