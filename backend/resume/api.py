from ninja import NinjaAPI

api = NinjaAPI()


@api.get("/test")
def hello(request):
    return {"message": "Hello World"}
