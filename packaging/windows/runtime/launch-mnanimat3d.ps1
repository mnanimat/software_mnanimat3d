$ErrorActionPreference = 'Stop'
$appRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$serverScript = Join-Path $appRoot 'run-mnanimat3d.ps1'

function Open-MNAnimat3DWindow([string]$Url) {
    $edge = @(
        (Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application\msedge.exe'),
        (Join-Path $env:ProgramFiles 'Microsoft\Edge\Application\msedge.exe')
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) } | Select-Object -First 1
    if ($edge) {
        Start-Process -FilePath $edge -ArgumentList @("--app=$Url", '--start-maximized')
        return
    }
    $chrome = @(
        (Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'Google\Chrome\Application\chrome.exe')
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) } | Select-Object -First 1
    if ($chrome) {
        Start-Process -FilePath $chrome -ArgumentList @("--app=$Url", '--start-maximized')
        return
    }
    Start-Process $Url
}

foreach ($candidate in 4173..4190) {
    try {
        $info = Invoke-RestMethod -Uri "http://127.0.0.1:$candidate/api/app-info" -TimeoutSec 1
        if ($info.name -eq 'MNAnimat3D') {
            Open-MNAnimat3DWindow "http://127.0.0.1:$candidate/"
            exit 0
        }
    } catch { }
}

$port = $null
foreach ($candidate in 4173..4190) {
    $probe = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, $candidate)
    try {
        $probe.Start()
        $port = $candidate
        break
    } catch { }
    finally { $probe.Stop() }
}
if (-not $port) { throw 'Nenhuma porta local disponível para iniciar o MNAnimat3D.' }

$arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$serverScript`" -Port $port"
Start-Process -FilePath 'powershell.exe' -ArgumentList $arguments -WorkingDirectory $appRoot -WindowStyle Hidden

$url = "http://127.0.0.1:$port/"
for ($attempt = 0; $attempt -lt 50; $attempt += 1) {
    try {
        $info = Invoke-RestMethod -Uri "${url}api/app-info" -TimeoutSec 1
        if ($info.name -eq 'MNAnimat3D') {
            Open-MNAnimat3DWindow $url
            exit 0
        }
    } catch { }
    Start-Sleep -Milliseconds 200
}
throw 'O servidor local do MNAnimat3D não respondeu a tempo.'
