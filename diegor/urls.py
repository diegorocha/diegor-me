from django.conf.urls import url, include, handler404
from django.contrib import admin
from short_url.views import NotFoundView

urlpatterns = [
    url(r'^admin/', admin.site.urls),
    url(r'', include('short_url.urls', namespace='short_url')),
]

handler404 = NotFoundView.as_view()
