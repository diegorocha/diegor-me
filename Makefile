test:
	@coverage run --source=short_url manage.py test
	@coverage html --omit=*/migrations/*,*/wsgi.py,*/tests.py,*/apps.py,*/settings.py -d coverage
