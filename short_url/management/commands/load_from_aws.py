import boto3
from decouple import config
from short_url import models
from django.core.management.base import BaseCommand, CommandError


class Command(BaseCommand):
    help = 'Load data from DynamoDB'

    def handle(self, *args, **options):
        dynamodb = boto3.resource('dynamodb',
                              aws_access_key_id=config('AWS_ACCESS_KEY_ID'),
                              aws_secret_access_key=config('AWS_SECRET_ACCESS_KEY'),
                              region_name=config('REGION'))
        table = dynamodb.Table('diegor_me')
        response = table.scan()
        count = 0
        for item in response.get('Items'):
            short_url = models.ShortUrl(**item)
            short_url.save()
            self.stdout.write(self.style.SUCCESS(short_url))    
            count += 1
        self.stdout.write(self.style.SUCCESS('%d itens importados com sucesso.' % count))