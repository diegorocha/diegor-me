# coding: utf-8
from __future__ import unicode_literals
import utils
import models
from django.views import generic
from django.http import Http404


class ShortUrlView(generic.RedirectView):

    def get_redirect_url(self, *args, **kwargs):
        alias = kwargs.get('alias')
        # Procura pelo alias
        short_url = models.ShortUrl.objects.filter(alias=alias).first()
        if short_url:
            return short_url.url
        if utils.is_base62(alias):
            # Procura pela chave (base 62)
            short_url = models.ShortUrl.objects.filter(pk=utils.base62_to_int(alias)).first()
            if short_url:
                return short_url.url
        if alias.isdigit():
            # Procura pela chave (base 10)
            try:
                value = int(alias)
                short_url = models.ShortUrl.objects.filter(pk=value).first()
                if short_url:
                    return short_url.url
            except:  # pragma: no cover
                pass
        raise Http404("%s não encontrado" % alias)


class NotFoundView(generic.TemplateView):
    template_name = 'not-found.html'

    def get(self, request, *args, **kwargs):
        context = self.get_context_data(**kwargs)
        return self.render_to_response(context, status=404)
