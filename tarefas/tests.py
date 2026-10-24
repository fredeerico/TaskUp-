from datetime import timedelta

from django.urls import reverse
from django.test import TestCase
from django.utils import timezone
from rest_framework.authtoken.models import Token
from rest_framework.test import APIClient

from .models import Categoria, HistoricoTarefa, Notificacao, Subtarefa, Tarefa, Usuario
from .serializers import UsuarioSerializer


class TaskupModelTests(TestCase):
    def setUp(self):
        self.usuario = Usuario.objects.create_user(
            username="thiago",
            email="thiago@example.com",
            password="senha-segura",
            nome="Thiago",
        )
        self.client = APIClient()
        self.client.force_authenticate(user=self.usuario)
        self.categoria = Categoria.objects.create(
            nome="Trabalho",
            cor="#123456",
            usuario=self.usuario,
        )
        self.tarefa = Tarefa.objects.create(
            titulo="Revisar entrega",
            descricao="Revisar a entrega do projeto.",
            status="pendente",
            usuario=self.usuario,
            categoria=self.categoria,
        )
        self.tarefa.prioridade = Tarefa.Prioridade.ALTA
        self.tarefa.prazo = timezone.now() + timedelta(days=3)
        self.tarefa.save()

    def test_usuario_uses_hashed_password(self):
        self.assertTrue(self.usuario.check_password("senha-segura"))
        self.assertEqual(self.usuario.nome, "Thiago")

    def test_usuario_serializer_hashes_password_and_does_not_return_it(self):
        serializer = UsuarioSerializer(
            data={
                "username": "novo-usuario",
                "password": "outra-senha-segura",
                "nome": "Novo usuário",
            }
        )
        self.assertTrue(serializer.is_valid(), serializer.errors)
        usuario = serializer.save()

        self.assertTrue(usuario.check_password("outra-senha-segura"))
        self.assertNotIn("password", serializer.data)

    def test_tarefa_relations_and_subtask_defaults(self):
        subtarefa = Subtarefa.objects.create(
            tarefa=self.tarefa,
            descricao="Conferir os testes",
        )

        self.assertEqual(self.tarefa.usuario, self.usuario)
        self.assertEqual(self.tarefa.categoria, self.categoria)
        self.assertEqual(self.tarefa.prioridade, Tarefa.Prioridade.ALTA)
        self.assertIsNotNone(self.tarefa.prazo)
        self.assertFalse(subtarefa.concluida)
        self.assertEqual(subtarefa.ordem, 0)

    def test_tarefa_filters_by_priority_and_category(self):
        Tarefa.objects.create(
            titulo="Comprar café",
            descricao="",
            status="pendente",
            usuario=self.usuario,
            categoria=self.categoria,
            prioridade=Tarefa.Prioridade.BAIXA,
        )

        response = self.client.get(
            reverse("tarefa-list"),
            {"prioridade": "alta", "categoria": self.categoria.pk},
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual([item["id"] for item in response.data], [self.tarefa.pk])

    def test_tarefa_can_search_and_order_by_deadline(self):
        mais_tarde = Tarefa.objects.create(
            titulo="Revisar apresentação",
            descricao="",
            status="pendente",
            usuario=self.usuario,
            categoria=self.categoria,
            prazo=timezone.now() + timedelta(days=5),
        )

        response = self.client.get(
            reverse("tarefa-list"),
            {"search": "Revisar", "ordering": "prazo"},
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            [item["id"] for item in response.data],
            [self.tarefa.pk, mais_tarde.pk],
        )

    def test_tarefa_filters_by_deadline_range_and_overdue(self):
        atrasada = Tarefa.objects.create(
            titulo="Enviar relatório",
            descricao="",
            status="pendente",
            usuario=self.usuario,
            categoria=self.categoria,
            prazo=timezone.now() - timedelta(days=1),
        )

        response = self.client.get(
            reverse("tarefa-list"),
            {
                "prazo_de": (timezone.now() - timedelta(days=2)).date().isoformat(),
                "prazo_ate": timezone.now().date().isoformat(),
                "atrasada": "true",
            },
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual([item["id"] for item in response.data], [atrasada.pk])

    def test_tarefa_rejects_invalid_filter_values(self):
        response = self.client.get(
            reverse("tarefa-list"),
            {"prazo_de": "data-invalida"},
        )

        self.assertEqual(response.status_code, 400)

    def test_tarefa_rejects_invalid_priority(self):
        response = self.client.get(
            reverse("tarefa-list"),
            {"prioridade": "urgente"},
        )

        self.assertEqual(response.status_code, 400)

    def test_notification_and_task_history(self):
        notificacao = Notificacao.objects.create(
            tarefa=self.tarefa,
            data_execucao=timezone.now(),
        )
        historico = HistoricoTarefa.objects.create(
            tarefa=self.tarefa,
            usuario=self.usuario,
            campo_alterado="status",
            valor_antigo="pendente",
            valor_novo="concluida",
        )

        self.assertFalse(notificacao.enviada)
        self.assertEqual(self.tarefa.notificacoes.get(), notificacao)
        self.assertEqual(self.tarefa.historico.get(), historico)


class ApiDocumentationTests(TestCase):
    def test_openapi_schema_documents_task_filters(self):
        response = self.client.get(reverse("schema"))

        self.assertEqual(response.status_code, 200)
        task_parameters = response.data["paths"]["/api/tarefas/"]["get"]["parameters"]
        documented_parameters = {parameter["name"] for parameter in task_parameters}
        self.assertTrue(
            {
                "status",
                "prioridade",
                "categoria",
                "prazo_de",
                "prazo_ate",
                "atrasada",
                "search",
                "ordering",
            }.issubset(documented_parameters)
        )

    def test_swagger_and_redoc_pages_are_available(self):
        swagger_response = self.client.get(reverse("swagger-ui"))
        redoc_response = self.client.get(reverse("redoc"))

        self.assertEqual(swagger_response.status_code, 200)
        self.assertEqual(redoc_response.status_code, 200)


class AuthenticationTests(TestCase):
    def setUp(self):
        self.usuario = Usuario.objects.create_user(
            username="thiago",
            email="thiago@example.com",
            password="senha-segura",
            nome="Thiago",
        )
        self.login_url = reverse("login")

    def test_login_returns_token_and_user_details(self):
        response = self.client.post(
            self.login_url,
            {"username": "thiago", "password": "senha-segura"},
            format="json",
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["nome"], "Thiago")
        self.assertEqual(response.data["email"], "thiago@example.com")
        self.assertEqual(
            response.data["token"],
            Token.objects.get(user=self.usuario).key,
        )

    def test_login_rejects_invalid_credentials(self):
        response = self.client.post(
            self.login_url,
            {"username": "thiago", "password": "senha-incorreta"},
            format="json",
        )

        self.assertEqual(response.status_code, 401)
        self.assertNotIn("token", response.data)

    def test_api_routes_require_authentication(self):
        response = self.client.get(reverse("tarefa-list"))

        self.assertEqual(response.status_code, 401)

    def test_token_authentication_grants_access_to_api(self):
        token = Token.objects.create(user=self.usuario)
        client = APIClient()
        client.credentials(HTTP_AUTHORIZATION=f"Token {token.key}")

        response = client.get(reverse("tarefa-list"))

        self.assertEqual(response.status_code, 200)


class IsolamentoPorUsuarioTests(TestCase):
    """Cada usuário só enxerga e altera os próprios dados."""

    def setUp(self):
        self.ana = Usuario.objects.create_user(
            username="ana", email="ana@example.com", password="senha-segura", nome="Ana"
        )
        self.bia = Usuario.objects.create_user(
            username="bia", email="bia@example.com", password="senha-segura", nome="Bia"
        )
        self.categoria_bia = Categoria.objects.create(nome="Casa", cor="#000000", usuario=self.bia)
        self.tarefa_bia = Tarefa.objects.create(
            titulo="Tarefa da Bia", descricao="Privada", status="pendente", usuario=self.bia
        )
        Subtarefa.objects.create(tarefa=self.tarefa_bia, descricao="Item da Bia")
        self.client = APIClient()
        self.client.force_authenticate(user=self.ana)

    def test_listagens_trazem_apenas_dados_do_usuario(self):
        for rota in ("tarefa-list", "categoria-list", "subtarefa-list", "notificacao-list"):
            response = self.client.get(reverse(rota))
            self.assertEqual(response.status_code, 200, rota)
            self.assertEqual(response.data, [], rota)

        usuarios = self.client.get(reverse("usuario-list")).data
        self.assertEqual([u["username"] for u in usuarios], ["ana"])

    def test_nao_acessa_nem_altera_tarefa_de_outro_usuario(self):
        url = reverse("tarefa-detail", args=[self.tarefa_bia.pk])
        self.assertEqual(self.client.get(url).status_code, 404)
        self.assertEqual(self.client.patch(url, {"status": "concluida"}, format="json").status_code, 404)
        self.assertEqual(self.client.delete(url).status_code, 404)

    def test_nao_usa_categoria_nem_tarefa_de_outro_usuario(self):
        resposta = self.client.post(
            reverse("tarefa-list"),
            {"titulo": "X", "descricao": "Y", "status": "pendente", "categoria": self.categoria_bia.pk},
            format="json",
        )
        self.assertEqual(resposta.status_code, 400)

        resposta = self.client.post(
            reverse("subtarefa-list"),
            {"tarefa": self.tarefa_bia.pk, "descricao": "Intrusa"},
            format="json",
        )
        self.assertEqual(resposta.status_code, 400)

    def test_categoria_criada_pertence_ao_usuario_autenticado(self):
        resposta = self.client.post(
            reverse("categoria-list"),
            {"nome": "Estudos", "cor": "#8B7CF6", "usuario": self.bia.pk},
            format="json",
        )
        self.assertEqual(resposta.status_code, 201)
        self.assertEqual(resposta.data["usuario"], self.ana.pk)

    def test_cadastro_de_usuario_continua_publico(self):
        resposta = APIClient().post(
            reverse("usuario-list"),
            {"username": "nova", "password": "senha-segura-123", "nome": "Nova"},
            format="json",
        )
        self.assertEqual(resposta.status_code, 201)
        self.assertEqual(APIClient().get(reverse("usuario-list")).status_code, 401)

    def test_cadastro_nao_permite_virar_administrador(self):
        resposta = APIClient().post(
            reverse("usuario-list"),
            {
                "username": "espertinho",
                "password": "senha-segura-123",
                "nome": "Espertinho",
                "is_superuser": True,
                "is_staff": True,
            },
            format="json",
        )
        self.assertEqual(resposta.status_code, 201)
        usuario = Usuario.objects.get(username="espertinho")
        self.assertFalse(usuario.is_superuser)
        self.assertFalse(usuario.is_staff)
        self.assertTrue(usuario.check_password("senha-segura-123"))
        self.assertNotIn("password", resposta.data)

    def test_subtarefas_filtradas_por_tarefa(self):
        tarefa_a = Tarefa.objects.create(titulo="A", descricao="a", status="pendente", usuario=self.ana)
        tarefa_b = Tarefa.objects.create(titulo="B", descricao="b", status="pendente", usuario=self.ana)
        Subtarefa.objects.create(tarefa=tarefa_a, descricao="a1", ordem=1)
        Subtarefa.objects.create(tarefa=tarefa_a, descricao="a0", ordem=0)
        Subtarefa.objects.create(tarefa=tarefa_b, descricao="b0")

        resposta = self.client.get(reverse("subtarefa-list"), {"tarefa": tarefa_a.pk})
        self.assertEqual(resposta.status_code, 200)
        self.assertEqual([s["descricao"] for s in resposta.data], ["a0", "a1"])

    def test_login_devolve_id_do_usuario(self):
        resposta = APIClient().post(
            reverse("login"), {"username": "ana", "password": "senha-segura"}, format="json"
        )
        self.assertEqual(resposta.status_code, 200)
        self.assertEqual(resposta.data["id"], self.ana.pk)
