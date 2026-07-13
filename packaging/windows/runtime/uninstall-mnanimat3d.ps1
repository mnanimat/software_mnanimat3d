$ErrorActionPreference = 'SilentlyContinue'
$expected = [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'Programs\MNAnimat3D')).TrimEnd('\')
$current = [IO.Path]::GetFullPath((Split-Path -Parent $MyInvocation.MyCommand.Path)).TrimEnd('\')
if (-not $current.Equals($expected, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'A desinstalação foi interrompida porque a pasta de destino não corresponde ao MNAnimat3D.'
}

Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" |
    Where-Object { $_.ProcessId -ne $PID -and $_.CommandLine -like '*MNAnimat3D*run-mnanimat3d.ps1*' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force }

$desktopShortcut = Join-Path ([Environment]::GetFolderPath('Desktop')) 'MNAnimat3D.lnk'
$startMenuDirectory = Join-Path ([Environment]::GetFolderPath('Programs')) 'MNAnimat3D'
Remove-Item -LiteralPath $desktopShortcut -Force -ErrorAction SilentlyContinue
if (([IO.Path]::GetFullPath($startMenuDirectory)).StartsWith([IO.Path]::GetFullPath([Environment]::GetFolderPath('Programs')), [StringComparison]::OrdinalIgnoreCase)) {
    Remove-Item -LiteralPath $startMenuDirectory -Recurse -Force -ErrorAction SilentlyContinue
}
Remove-Item -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\MNAnimat3D' -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $expected -Recurse -Force -ErrorAction SilentlyContinue
