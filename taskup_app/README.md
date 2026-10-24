# TaskUp — App Flutter

Front-end em Flutter para a **TaskUp API** (Django REST). Tema escuro baseado no
**Material 3**, em português.

## Funcionalidades

- **Login e cadastro** (`POST /api/login/`, `POST /api/usuarios/`), com o token salvo no navegador
- **Tarefas**: lista com resumo de progresso, busca, filtros (status, prioridade,
  categoria, atrasadas), criar / editar / excluir, concluir com um clique
- **Detalhe da tarefa** com troca rápida de status e **subtarefas** (checklist)
- **Categorias** com paleta de cores
- **Perfil** com estatísticas, troca do endereço do servidor e logout
- Layout para navegador: barra lateral em telas largas, barra inferior em janelas estreitas, conteúdo com largura máxima
- Ações por menu (⋮) em cada tarefa, além do arrastar

## Como rodar

Requisitos: Flutter 3.27 ou mais recente (testado com 3.47), com suporte web.

**1. Back-end** (na pasta `TaskUp-API-main`):

```bash
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

**2. Front-end** (na pasta `taskup_app`):

```bash
flutter create . --platforms web --project-name taskup_app   # gera os ícones da pasta web/ (não sobrescreve nada)
flutter pub get
flutter run -d chrome
```

O app usa a API em `http://127.0.0.1:8000`. Dá para trocar pelo ícone no canto
da tela de login ou em **Perfil → Servidor da API**.

## Publicação

O app é publicado no Render como site estático, separado da API. Na pasta
`TaskUp-API-main`, o script `build_web.ps1` compila o app já apontando para a API
de produção e copia o resultado para `web_dist/`:

```powershell
powershell -ExecutionPolicy Bypass -File build_web.ps1
```

O passo a passo completo está em `DEPLOY.md`, na raiz do projeto.

## CORS

Como o app e a API ficam em endereços diferentes, a API precisa autorizar a
origem do app. Em `config/settings.py`, já estão liberados o `localhost` (em
qualquer porta) e os endereços listados na variável de ambiente
`CORS_ALLOWED_ORIGINS`, que no Render vale `https://taskup-web.onrender.com`.

## Observações sobre a API

- Cada usuário só vê e altera os próprios dados; o cadastro (`POST /api/usuarios/`) é público.
- O login devolve `id`, `token`, `nome` e `email`.
- `GET /api/subtarefas/?tarefa=<id>` traz o checklist de uma tarefa.
- `descricao` é obrigatória na API, então o formulário também a exige.
- Excluir uma categoria **exclui as tarefas dela** (`on_delete=CASCADE`); o app avisa antes.
- `status` é texto livre; o app usa `pendente`, `em_andamento` e `concluida`.

## Estrutura

```
lib/
├── main.dart                 # app, tema, localização pt-BR, roteamento por sessão
├── core/
│   ├── api_client.dart       # HTTP + token + mensagens de erro do DRF
│   └── theme.dart            # tema escuro Material 3
├── models/                   # Usuario, Tarefa, Categoria, Subtarefa
├── state/
│   ├── session.dart          # login, cadastro, logout, URL da API
│   └── task_store.dart       # tarefas, categorias, subtarefas, filtros
├── screens/                  # login, home, abas, detalhe, formulário
└── widgets/                  # card de tarefa, badges, diálogos
web/
├── index.html                # fundo escuro + indicador de carregamento
└── manifest.json
```
