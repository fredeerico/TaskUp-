"""Rotas do TaskUp: API REST em /api/, documentação em /api/docs/ e /api/redoc/."""

from django.contrib import admin
from django.urls import include, path
from drf_spectacular.views import (
    SpectacularAPIView,
    SpectacularRedocView,
    SpectacularSwaggerView,
)
from rest_framework.routers import DefaultRouter

from tarefas.views import (
    CategoriaViewSet,
    HistoricoTarefaViewSet,
    LoginView,
    NotificacaoViewSet,
    SubtarefaViewSet,
    TarefaViewSet,
    UsuarioViewSet,
)

router = DefaultRouter()
router.register('usuarios', UsuarioViewSet)
router.register('categorias', CategoriaViewSet)
router.register('tarefas', TarefaViewSet)
router.register('subtarefas', SubtarefaViewSet)
router.register('notificacoes', NotificacaoViewSet)
router.register('historico-tarefas', HistoricoTarefaViewSet, basename='historico-tarefa')

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/login/', LoginView.as_view(), name='login'),
    path('api/', include(router.urls)),
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
    path('api/redoc/', SpectacularRedocView.as_view(url_name='schema'), name='redoc'),
]
