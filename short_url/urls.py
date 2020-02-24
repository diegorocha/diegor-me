from short_url import views
from short_url.api import api_router
from django.conf.urls import url, include


app_name = 'short_url'

urlpatterns = [
    url(r'^api/', include((api_router.urls, 'api'), namespace='api')),
    url(r'(?P<alias>.*)', views.ShortUrlView.as_view(), name='short_url'),
]

