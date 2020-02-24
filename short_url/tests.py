from django.test import TestCase
from rest_framework.test import APITestCase
from django.conf import settings
from short_url import utils
from model_mommy import mommy
from django.urls import reverse
from string import digits, ascii_letters
from short_url.models import ShortUrl
from django.contrib.auth.models import User


class UtilTest(TestCase):
    def test_is_base62_empty(self):
        self.assertFalse(utils.is_base62(''))

    def test_is_base62_invalid(self):
        self.assertFalse(utils.is_base62('abcd@'))

    def test_is_base62_valid(self):
        self.assertTrue(utils.is_base62(digits + ascii_letters))

    def test_base62_to_int_invalid(self):
        with self.assertRaises(Exception):
            self.assertFalse(utils.base62_to_int('12345@'))

    def test_base62_to_int(self):
        self.assertEquals(utils.base62_to_int(digits), 225557475374453)

    def test_base62_to_int_other(self):
        self.assertEquals(utils.base62_to_int('foo'), 59172)
        self.assertNotEquals(utils.base62_to_int('Foo'), 59172)


class ShortUrlViewTest(TestCase):
    def test_redirect(self):
        short_url = mommy.make(ShortUrl, _fill_optional=True)
        url = '/%s' % short_url.alias
        response = self.client.get(url)
        self.assertRedirects(response, short_url.url, target_status_code=404)

    def test_redirect_by_id(self):
        mommy.make(ShortUrl, _fill_optional=True, _quantity=100)
        pk = 100
        short_url = ShortUrl.objects.get(pk=pk)
        short_url = mommy.make(ShortUrl, _fill_optional=True)
        url = '/%d' % short_url.pk
        response = self.client.get(url)
        self.assertRedirects(response, short_url.url, target_status_code=404)

    def test_redirect_by_base62(self):
        mommy.make(ShortUrl, _fill_optional=True, _quantity=100)
        pk = 100
        base_62_pk = '1C'
        short_url = ShortUrl.objects.get(pk=pk)
        self.assertEquals(utils.base62_to_int(base_62_pk), pk)
        url = '/%s' % base_62_pk
        response = self.client.get(url)
        self.assertRedirects(response, short_url.url, target_status_code=404)

    def test_redirect_non_exist(self):
        ShortUrl.objects.all().delete()
        response = self.client.get('/')
        self.assertEquals(response.status_code, 404)


class ShortUrlViewSetTest(APITestCase):
    def setUp(self):
        username = 'admin'
        password = '4dm1n'
        user = User.objects.create_user(username=username, password=password, is_staff=True)
        self.client.force_authenticate(user=user)

    def test_get(self):
        page_size = settings.REST_FRAMEWORK.get('PAGE_SIZE')
        mommy.make(ShortUrl, _fill_optional=True, _quantity=page_size + 20)
        count = ShortUrl.objects.count()
        response = self.client.get(reverse('short_url:api:shorturl-list'))
        self.assertEquals(response.status_code, 200)
        data = response.json()
        self.assertEquals(data['count'], count)

    def test_list(self):
        page_size = settings.REST_FRAMEWORK.get('PAGE_SIZE')
        mommy.make(ShortUrl, _fill_optional=True, _quantity=page_size + 20)
        count = ShortUrl.objects.count()
        response = self.client.get(reverse('short_url:api:shorturl-list'))
        self.assertEquals(response.status_code, 200)
        data = response.json()
        self.assertEquals(data['count'], count)

    def test_create(self):
        post_data = {"alias": "foo", "url": "http://foobar.com"}
        response = self.client.post(reverse('short_url:api:shorturl-list'), post_data)
        self.assertEquals(response.status_code, 201)
        data = response.json()
        data.pop("id")
        self.assertEquals(data, post_data)

    def test_retrieve(self):
        short_url = mommy.make(ShortUrl, _fill_optional=True)
        response = self.client.get(reverse('short_url:api:shorturl-detail', args=(short_url.pk,)))
        self.assertEquals(response.status_code, 200)
        data = response.json()
        self.assertEquals(data['url'], short_url.url)

    def test_update(self):
        new_url = 'http://foo.com/foobar'
        short_url = mommy.make(ShortUrl, _fill_optional=True)
        response = self.client.get(reverse('short_url:api:shorturl-detail', args=(short_url.pk,)))
        self.assertEquals(response.status_code, 200)
        data = response.json()
        data["url"] = new_url
        response = self.client.put(reverse('short_url:api:shorturl-detail', args=(short_url.pk,)), data, format='json')
        self.assertEquals(response.status_code, 200)
        short_url = ShortUrl.objects.get(pk=short_url.pk)
        self.assertEquals(short_url.url, new_url)

    def test_partial_update(self):
        new_url = 'http://foo.com/foo-bar'
        data = dict(url=new_url)
        short_url = mommy.make(ShortUrl, _fill_optional=True)
        response = self.client.patch(reverse('short_url:api:shorturl-detail', args=(short_url.pk,)), data, format='json')
        self.assertEquals(response.status_code, 200)
        short_url = ShortUrl.objects.get(pk=short_url.pk)
        self.assertEquals(short_url.url, new_url)

    def test_delete(self):
        short_url = mommy.make(ShortUrl, _fill_optional=True)
        response = self.client.delete(reverse('short_url:api:shorturl-detail', args=(short_url.pk,)))
        self.assertEquals(response.status_code, 204)
        short_url = ShortUrl.objects.filter(pk=short_url.pk).first()
        self.assertIsNone(short_url)
