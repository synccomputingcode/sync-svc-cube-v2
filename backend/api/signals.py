# django signals
# https://docs.djangoproject.com/en/3.2/topics/signals/
from allauth.socialaccount.models import SocialLogin
from allauth.socialaccount.signals import social_account_added
from django.dispatch import receiver


@receiver(social_account_added)
def social_account_added_callback(request, sociallogin: SocialLogin, **kwargs):
    if sociallogin.account.provider == "github":
        user_profile = sociallogin.user.profile
        user_profile.avatar_url = sociallogin.account.extra_data.get("avatar_url")
        user_profile.save()
    elif sociallogin.account.provider == "google":
        user_profile = sociallogin.user.profile
        user_profile.avatar_url = sociallogin.account.extra_data.get("picture")
        user_profile.save()
