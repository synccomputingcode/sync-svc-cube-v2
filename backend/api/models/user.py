from django.contrib.auth.models import User
from django.db import models

from api.models.common import BaseModel


class ProfileModel(BaseModel):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="profile")
    avatar_url = models.CharField(max_length=2048, blank=True)

    def __str__(self):
        return f"{self.user.username} Profile"
