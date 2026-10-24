from rest_framework import serializers

from .models import Categoria, HistoricoTarefa, Notificacao, Subtarefa, Tarefa, Usuario


# --------------------------------------------------------------------------
# Usuários e autenticação
# --------------------------------------------------------------------------

class UsuarioSerializer(serializers.ModelSerializer):
    class Meta:
        model = Usuario
        # Campos explícitos: impede que o cadastro defina is_staff, is_superuser etc.
        fields = ["id", "username", "nome", "email", "password", "criado_em"]
        read_only_fields = ["criado_em"]
        extra_kwargs = {"password": {"write_only": True}}

    def create(self, validated_data):
        return Usuario.objects.create_user(**validated_data)

    def update(self, instance, validated_data):
        password = validated_data.pop("password", None)
        instance = super().update(instance, validated_data)
        if password is not None:
            instance.set_password(password)
            instance.save(update_fields=["password"])
        return instance


class LoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField(write_only=True, trim_whitespace=False)


class LoginResponseSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    token = serializers.CharField()
    nome = serializers.CharField()
    email = serializers.EmailField()


# --------------------------------------------------------------------------
# Recursos do usuário
# --------------------------------------------------------------------------

class DoUsuarioMixin:
    """Validações que impedem referenciar dados de outro usuário."""

    @property
    def usuario(self):
        return self.context["request"].user

    def validate_categoria(self, categoria):
        if categoria is not None and categoria.usuario_id != self.usuario.id:
            raise serializers.ValidationError("Categoria não encontrada.")
        return categoria

    def validate_tarefa(self, tarefa):
        if tarefa.usuario_id != self.usuario.id:
            raise serializers.ValidationError("Tarefa não encontrada.")
        return tarefa


class CategoriaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Categoria
        fields = "__all__"
        read_only_fields = ["usuario"]


class TarefaSerializer(DoUsuarioMixin, serializers.ModelSerializer):
    class Meta:
        model = Tarefa
        fields = "__all__"
        read_only_fields = ["usuario"]


class SubtarefaSerializer(DoUsuarioMixin, serializers.ModelSerializer):
    class Meta:
        model = Subtarefa
        fields = "__all__"


class NotificacaoSerializer(DoUsuarioMixin, serializers.ModelSerializer):
    class Meta:
        model = Notificacao
        fields = "__all__"


class HistoricoTarefaSerializer(DoUsuarioMixin, serializers.ModelSerializer):
    class Meta:
        model = HistoricoTarefa
        fields = "__all__"
        read_only_fields = ["usuario"]
