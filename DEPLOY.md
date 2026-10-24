# Deploy do TaskUp no Render

O `render.yaml` cria três recursos:

| Recurso | Tipo | Endereço |
|---|---|---|
| `taskup-db` | PostgreSQL (free) | interno |
| `taskup-api` | Web Service (Django + Gunicorn) | `https://taskup-api.onrender.com` (Swagger em `/api/docs/`) |
| `taskup-web` | Static Site (Flutter Web em `web_dist/`) | `https://taskup-web.onrender.com` |

O app chama a API pela URL definida no build (`build_web.ps1`), e a API só aceita
chamadas de navegador vindas do site listado em `CORS_ALLOWED_ORIGINS`.

## 1. Testar localmente

Na pasta `TaskUp-API-main`:

```powershell
pip install -r requirements.txt
python manage.py test
```

Os 23 testes devem passar.

## 2. Compilar o app

```powershell
powershell -ExecutionPolicy Bypass -File build_web.ps1
```

O resultado vai para `web_dist/`, já apontando para `https://taskup-api.onrender.com`.

## 3. Enviar para o GitHub

Crie um repositório **vazio** no GitHub (sem README). Na primeira vez:

```powershell
git init
git add .
git commit -m "Deploy no Render"
git branch -M main
git remote add origin https://github.com/SEU-USUARIO/taskup.git
git push -u origin main
```

Nas próximas vezes, basta `git add .`, `git commit -m "..."` e `git push`.

Confira que **não** subiram `.env`, `db.sqlite3` e `venv/`.

## 4. Criar no Render (Blueprint)

1. No Render: **New → Blueprint** e escolha o repositório.
2. Confira os três recursos e clique em **Deploy Blueprint**.
3. Aguarde todos ficarem **Live**.

A `SECRET_KEY` é gerada automaticamente, e a `DATABASE_URL` é ligada ao banco sozinha.

**Já tinha um Blueprint criado?** Basta o `git push`: o Render aplica o `render.yaml` novo.
Se o `taskup-web` tiver sido apagado, ele é recriado.

## 5. Conferir as URLs

Se os nomes já estiverem em uso, o Render acrescenta um sufixo à URL (ex.: `taskup-api-ab12.onrender.com`). Nesse caso:

- **A URL da API mudou:** compile de novo com a URL real e envie.
  ```powershell
  powershell -ExecutionPolicy Bypass -File build_web.ps1 -ApiUrl https://URL-REAL-DA-API
  git add .
  git commit -m "URL da API"
  git push
  ```
- **A URL do site mudou:** em **taskup-api → Environment**, troque `CORS_ALLOWED_ORIGINS` pela URL real (sem `/` no final) e salve.

## 6. Testar em produção

1. API: `https://taskup-api.onrender.com/api/docs/`
2. App: `https://taskup-web.onrender.com`. Crie uma conta, depois categorias, tarefas e subtarefas.

## Plano gratuito

- **A API dorme após 15 minutos sem uso.** O primeiro acesso leva cerca de 1 minuto. **Abra os links alguns minutos antes de apresentar**; se o app mostrar erro de conexão, espere e tente de novo.
- **O PostgreSQL gratuito expira 30 dias após ser criado** (com mais 14 dias para upgrade antes de ser apagado).

## Problemas comuns

| Sintoma | Solução |
|---|---|
| "Não foi possível conectar à API" | A API está acordando: espere 1 minuto. Se continuar, confira o passo 5 |
| `400 Bad Request` na API | Domínio próprio? Adicione-o em `ALLOWED_HOSTS` |
| Site mostra a versão antiga | Ctrl+Shift+R |
| Erro no build | Abra **Logs** do serviço no Render e me envie o trecho do erro |
