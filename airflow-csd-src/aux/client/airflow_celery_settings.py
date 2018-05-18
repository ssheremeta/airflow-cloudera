from airflow import configuration

class CELERY_CONFIG(object):
    CELERY_ACCEPT_CONTENT = ['json', 'pickle']
    CELERY_EVENT_SERIALIZER = 'json'
    CELERY_RESULT_SERIALIZER = 'pickle'
    CELERY_TASK_SERIALIZER = 'pickle'
    CELERYD_PREFETCH_MULTIPLIER = 1
    CELERY_ACKS_LATE = True
    BROKER_URL = configuration.get('celery', 'BROKER_URL')
    CELERY_RESULT_BACKEND = configuration.get('celery', 'CELERY_RESULT_BACKEND')
    CELERYD_CONCURRENCY = configuration.get('celery', 'CELERYD_CONCURRENCY')
    CELERY_DEFAULT_QUEUE = configuration.get('celery', 'DEFAULT_QUEUE')
    CELERY_DEFAULT_EXCHANGE = configuration.get('celery', 'DEFAULT_QUEUE')
