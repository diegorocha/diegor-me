import views
from api import api_router
from django.conf.urls import url, include
from django.contrib import admin


urlpatterns = [
    url(r'^api/', include(api_router.urls, namespace='api')),
    url(r'(?P<alias>.*)', views.ShortUrlView.as_view(), name='short_url'),
]

