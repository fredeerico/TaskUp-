# Compila o app Flutter para a web e copia o resultado para web_dist/,
# a pasta publicada pelo Render no site estatico taskup-web.
#
# Uso (PowerShell, na pasta TaskUp-API-main):
#   powershell -ExecutionPolicy Bypass -File build_web.ps1
#   powershell -ExecutionPolicy Bypass -File build_web.ps1 -ApiUrl https://outra-url.onrender.com

param(
    [string]$ApiUrl = "https://taskup-api.onrender.com"
)

$ErrorActionPreference = "Stop"
$app = Join-Path $PSScriptRoot "taskup_app"
$destino = Join-Path $PSScriptRoot "web_dist"

function Invoke-Flutter {
    flutter @args
    if ($LASTEXITCODE -ne 0) { throw "flutter $args falhou" }
}

Write-Host "Compilando o app (API: $ApiUrl)..." -ForegroundColor Cyan
Push-Location $app
try {
    Invoke-Flutter pub get
    Invoke-Flutter build web --release "--dart-define=API_URL=$ApiUrl"
}
finally {
    Pop-Location
}

if (Test-Path $destino) { Remove-Item $destino -Recurse -Force }
Copy-Item (Join-Path $app "build\web") $destino -Recurse

Write-Host "Pronto! App gerado em web_dist." -ForegroundColor Green
Write-Host "Agora: git add .  ->  git commit  ->  git push"
