from __future__ import unicode_literals
from django.db import models


class ShortUrl(models.Model):
    class Meta:
        ordering = ['alias']
    alias = models.CharField(max_length=30, blank=True, unique=True)
    url = models.URLField()

    def __unicode__(self):
        return '%s -> %s' % (self.alias, self.url)