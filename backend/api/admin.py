from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth.models import User

from api.models.user import ProfileModel


@admin.register(ProfileModel)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ("user", "avatar_url", "created_at", "updated_at")
    search_fields = ("user__username",)


class ProfileInline(admin.StackedInline):
    model = ProfileModel
    can_delete = False
    verbose_name_plural = "Profile"


admin.site.unregister(User)


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    inlines = (ProfileInline,)
