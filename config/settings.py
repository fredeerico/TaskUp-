"""Configurações do projeto TaskUp.

Os valores que mudam entre o ambiente local e a produção (Render) vêm de
variáveis de ambiente. Localmente, elas são lidas do arquivo `.env`
(veja `.env.example`).
"""

import os
from pathlib import Path

import dj_database_url
from dotenv import load_dotenv

load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent


def env_list(name):
    """Lê uma variável de ambiente com valores separados por vírgula."""
    return [item.strip() for item in os.getenv(name, '').split(',') if item.strip()]


def env_bool(name, default):
    return os.getenv(name, str(default)).lower() in ('1', 'true', 'yes')


# --------------------------------------------------------------------------
# Segurança e hosts
# --------------------------------------------------------------------------

SECRET_KEY = os.getenv('SECRET_KEY')

# O Render define a variável RENDER: lá o DEBUG fica desligado.
DEBUG = env_bool('DEBUG', default='RENDER' not in os.environ)

ALLOWED_HOSTS = ['localhost', '127.0.0.1', *env_list('ALLOWED_HOSTS')]
if render_host := os.getenv('RENDER_EXTERNAL_HOSTNAME'):
    ALLOWED_HOSTS.append(render_host)

CSRF_TRUSTED_ORIGINS = [
    f'https://{host}' for host in ALLOWED_HOSTS if host not in ('localhost', '127.0.0.1')
]

if not DEBUG:
    # O Render entrega as requisições por um proxy HTTPS.
    SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True

# CORS: o front-end roda em outro endereço e precisa ser autorizado.
# - local: `flutter run -d chrome` usa localhost em uma porta aleatória;
# - produção: a URL do site estático, informada em CORS_ALLOWED_ORIGINS.
CORS_ALLOWED_ORIGIN_REGEXES = [r'^http://(localhost|127\.0\.0\.1)(:\d+)?$']
CORS_ALLOWED_ORIGINS = [origin.rstrip('/') for origin in env_list('CORS_ALLOWED_ORIGINS')]


# --------------------------------------------------------------------------
# Aplicação
# --------------------------------------------------------------------------

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'rest_framework.authtoken',
    'drf_spectacular',
    'corsheaders',
    'tarefas',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

if not DEBUG:
    # Em produção, o WhiteNoise serve os arquivos estáticos (localmente, o runserver).
    MIDDLEWARE.insert(MIDDLEWARE.index('django.middleware.security.SecurityMiddleware') + 1,
                      'whitenoise.middleware.WhiteNoiseMiddleware')

ROOT_URLCONF = 'config.urls'
WSGI_APPLICATION = 'config.wsgi.application'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]


# --------------------------------------------------------------------------
# Banco de dados: SQLite local, PostgreSQL no Render (DATABASE_URL)
# --------------------------------------------------------------------------

DATABASES = {
    'default': dj_database_url.config(
        default=f'sqlite:///{BASE_DIR / "db.sqlite3"}',
        conn_max_age=600,
    )
}


# --------------------------------------------------------------------------
# Autenticação
# --------------------------------------------------------------------------

AUTH_USER_MODEL = 'tarefas.Usuario'

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]


# --------------------------------------------------------------------------
# Internacionalização
# --------------------------------------------------------------------------

LANGUAGE_CODE = 'pt-br'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True


# --------------------------------------------------------------------------
# Arquivos estáticos (admin e páginas da API)
# --------------------------------------------------------------------------

STATIC_URL = 'static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
STORAGES = {
    'default': {'BACKEND': 'django.core.files.storage.FileSystemStorage'},
    'staticfiles': {'BACKEND': 'whitenoise.storage.CompressedManifestStaticFilesStorage'},
}


# --------------------------------------------------------------------------
# E-mail (somente console por enquanto)
# --------------------------------------------------------------------------

MAILERS = {
    'default': {'BACKEND': 'django.core.mail.backends.console.EmailBackend'},
}


# --------------------------------------------------------------------------
# Django REST Framework e documentação OpenAPI
# --------------------------------------------------------------------------

REST_FRAMEWORK = {
    'DEFAULT_SCHEMA_CLASS': 'drf_spectacular.openapi.AutoSchema',
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
}

SPECTACULAR_SETTINGS = {
    'TITLE': 'TaskUp API',
    'DESCRIPTION': 'API para criação e gerenciamento de tarefas.',
    'VERSION': '1.0.0',
    'SERVE_INCLUDE_SCHEMA': False,
}
