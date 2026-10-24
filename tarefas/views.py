from django.contrib.auth import authenticate
from django.db.models import Q
from django.utils import timezone
from drf_spectacular.types import OpenApiTypes
from drf_spectacular.utils import OpenApiParameter, extend_schema, extend_schema_view
from rest_framework import filters, serializers, status, viewsets
from rest_framework.authtoken.models import Token
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Categoria, HistoricoTarefa, Notificacao, Subtarefa, Tarefa, Usuario
from .serializers import (
    CategoriaSerializer,
    HistoricoTarefaSerializer,
    LoginResponseSerializer,
    LoginSerializer,
    NotificacaoSerializer,
    SubtarefaSerializer,
    TarefaSerializer,
    UsuarioSerializer,
)


def query_param(name, tipo, descricao, **extra):
    return OpenApiParameter(
        name=name, type=tipo, location=OpenApiParameter.QUERY, description=descricao, **extra
    )


def validar(campo, valor):
    """Valida um parâmetro da URL com um campo do DRF (erro vira resposta 400)."""
    return campo.run_validation(valor)


# --------------------------------------------------------------------------
# Autenticação e usuários
# --------------------------------------------------------------------------

class LoginView(APIView):
    authentication_classes = []
    permission_classes = [AllowAny]

    @extend_schema(
        request=LoginSerializer,
        responses={200: LoginResponseSerializer},
        description="Autentica o usuário e retorna um token de acesso.",
    )
    def post(self, request):
        dados = LoginSerializer(data=request.data)
        dados.is_valid(raise_exception=True)

        usuario = authenticate(request, **dados.validated_data)
        if usuario is None:
            return Response(
                {"detail": "Usuário ou senha inválidos."},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        token, _ = Token.objects.get_or_create(user=usuario)
        return Response(
            {"id": usuario.id, "token": token.key, "nome": usuario.nome, "email": usuario.email}
        )


class UsuarioViewSet(viewsets.ModelViewSet):
    """O cadastro é público; as demais operações só enxergam o próprio usuário."""

    queryset = Usuario.objects.all()
    serializer_class = UsuarioSerializer

    def get_permissions(self):
        if self.action == "create":
            return [AllowAny()]
        return [IsAuthenticated()]

    def get_queryset(self):
        return super().get_queryset().filter(pk=self.request.user.pk)


# --------------------------------------------------------------------------
# Recursos do usuário autenticado
# --------------------------------------------------------------------------

class DoUsuarioViewSet(viewsets.ModelViewSet):
    """ViewSet que só lista e altera registros do usuário autenticado.

    `campo_usuario` é o caminho até o dono do registro no ORM
    (ex.: "usuario" ou "tarefa__usuario"). Se o modelo tem o campo
    `usuario`, ele é preenchido automaticamente na criação.
    """

    campo_usuario = "usuario"

    def get_queryset(self):
        return super().get_queryset().filter(**{self.campo_usuario: self.request.user})

    def perform_create(self, serializer):
        tem_dono = hasattr(serializer.Meta.model, "usuario")
        serializer.save(**({"usuario": self.request.user} if tem_dono else {}))


class CategoriaViewSet(DoUsuarioViewSet):
    queryset = Categoria.objects.all()
    serializer_class = CategoriaSerializer


@extend_schema_view(
    list=extend_schema(
        description="Lista tarefas com busca, ordenação e filtros opcionais.",
        parameters=[
            query_param("status", OpenApiTypes.STR, "Filtra pelo status da tarefa."),
            query_param(
                "prioridade",
                OpenApiTypes.STR,
                "Filtra pela prioridade da tarefa.",
                enum=Tarefa.Prioridade.values,
            ),
            query_param("categoria", OpenApiTypes.INT, "Filtra pelo ID da categoria."),
            query_param("prazo_de", OpenApiTypes.DATE, "Prazo nesta data ou depois (AAAA-MM-DD)."),
            query_param("prazo_ate", OpenApiTypes.DATE, "Prazo nesta data ou antes (AAAA-MM-DD)."),
            query_param("atrasada", OpenApiTypes.BOOL, "Somente atrasadas (true) ou não (false)."),
        ],
    )
)
class TarefaViewSet(DoUsuarioViewSet):
    queryset = Tarefa.objects.all()
    serializer_class = TarefaSerializer
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ["titulo", "descricao"]
    ordering_fields = ["titulo", "status", "prioridade", "prazo", "data_criacao"]

    def get_queryset(self):
        return self.aplicar_filtros(super().get_queryset(), self.request.query_params)

    @staticmethod
    def aplicar_filtros(queryset, params):
        if (valor := params.get("status")) is not None:
            queryset = queryset.filter(status=valor)

        if (valor := params.get("prioridade")) is not None:
            prioridade = validar(serializers.ChoiceField(Tarefa.Prioridade.choices), valor)
            queryset = queryset.filter(prioridade=prioridade)

        if (valor := params.get("categoria")) is not None:
            queryset = queryset.filter(categoria_id=validar(serializers.IntegerField(), valor))

        if (valor := params.get("prazo_de")) is not None:
            queryset = queryset.filter(prazo__date__gte=validar(serializers.DateField(), valor))

        if (valor := params.get("prazo_ate")) is not None:
            queryset = queryset.filter(prazo__date__lte=validar(serializers.DateField(), valor))

        if (valor := params.get("atrasada")) is not None:
            agora = timezone.now()
            if validar(serializers.BooleanField(), valor):
                queryset = queryset.filter(prazo__lt=agora)
            else:
                queryset = queryset.filter(Q(prazo__isnull=True) | Q(prazo__gte=agora))

        return queryset


@extend_schema_view(
    list=extend_schema(
        parameters=[query_param("tarefa", OpenApiTypes.INT, "Filtra pelo ID da tarefa.")]
    )
)
class SubtarefaViewSet(DoUsuarioViewSet):
    queryset = Subtarefa.objects.order_by("ordem", "id")
    serializer_class = SubtarefaSerializer
    campo_usuario = "tarefa__usuario"

    def get_queryset(self):
        queryset = super().get_queryset()
        if (valor := self.request.query_params.get("tarefa")) is not None:
            queryset = queryset.filter(tarefa_id=validar(serializers.IntegerField(), valor))
        return queryset


class NotificacaoViewSet(DoUsuarioViewSet):
    queryset = Notificacao.objects.all()
    serializer_class = NotificacaoSerializer
    campo_usuario = "tarefa__usuario"


class HistoricoTarefaViewSet(DoUsuarioViewSet):
    queryset = HistoricoTarefa.objects.all()
    serializer_class = HistoricoTarefaSerializer
    campo_usuario = "tarefa__usuario"
