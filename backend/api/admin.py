from django.contrib import admin
from django.contrib.auth.models import User

from api.models.user import ProfileModel


class ProfileAdmin(admin.ModelAdmin):
    list_display = ("user", "avatar_url", "created_at", "updated_at")
    search_fields = ("user__username",)


class ProfileInline(admin.StackedInline):
    model = ProfileModel
    can_delete = False
    verbose_name_plural = "Profile"


class UserAdmin(admin.ModelAdmin):
    inlines = (ProfileInline,)
    list_display = ("username", "email", "is_staff", "is_active")
    search_fields = ("username", "email")


admin.site.unregister(User)
admin.site.register(User, UserAdmin)

admin.site.register(ProfileModel, ProfileAdmin)
