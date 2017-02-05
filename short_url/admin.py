from short_url import models
from django.contrib import admin


@admin.register(models.ShortUrl)
class ShortUrlAdmin(admin.ModelAdmin):
    list_display = ['alias', 'url']