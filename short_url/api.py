import models
from rest_framework import routers
from rest_framework import viewsets
from rest_framework import serializers
from rest_framework import permissions


class ShortUrlSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.ShortUrl
        fields = '__all__'


class ShortUrlViewSet(viewsets.ModelViewSet):
    queryset = models.ShortUrl.objects.all()
    serializer_class = ShortUrlSerializer
    permission_classes = [permissions.IsAdminUser]

api_router = routers.DefaultRouter()
api_router.register(r'short_url', ShortUrlViewSet)
