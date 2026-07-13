$ErrorActionPreference = 'Stop'
$sourceDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$payload = Join-Path $sourceDirectory 'payload.zip'
$target = [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'Programs\MNAnimat3D'))
$allowedRoot = [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'Programs'))
if (-not $target.StartsWith($allowedRoot, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Pasta de instalação fora do local permitido.'
}
if (-not (Test-Path -LiteralPath $payload -PathType Leaf)) { throw 'O pacote do MNAnimat3D está incompleto.' }

New-Item -ItemType Directory -Force -Path $target | Out-Null
Expand-Archive -LiteralPath $payload -DestinationPath $target -Force

$shell = New-Object -ComObject WScript.Shell
$launcher = Join-Path $target 'launch-mnanimat3d.ps1'
$icon = Join-Path $target 'MNAnimat3D.ico'
$powershell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'

$desktopShortcut = Join-Path ([Environment]::GetFolderPath('Desktop')) 'MNAnimat3D.lnk'
$startMenuDirectory = Join-Path ([Environment]::GetFolderPath('Programs')) 'MNAnimat3D'
New-Item -ItemType Directory -Force -Path $startMenuDirectory | Out-Null
foreach ($shortcutPath in @($desktopShortcut, (Join-Path $startMenuDirectory 'MNAnimat3D.lnk'))) {
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $powershell
    $shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$launcher`""
    $shortcut.WorkingDirectory = $target
    $shortcut.IconLocation = "$icon,0"
    $shortcut.Description = 'Modelagem e animação 3D com MNAnimat3D'
    $shortcut.Save()
}

$uninstallKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\MNAnimat3D'
New-Item -Path $uninstallKey -Force | Out-Null
Set-ItemProperty -Path $uninstallKey -Name DisplayName -Value 'MNAnimat3D'
Set-ItemProperty -Path $uninstallKey -Name DisplayVersion -Value '1.0.0'
Set-ItemProperty -Path $uninstallKey -Name Publisher -Value 'MNAnimat3D'
Set-ItemProperty -Path $uninstallKey -Name InstallLocation -Value $target
Set-ItemProperty -Path $uninstallKey -Name DisplayIcon -Value $icon
Set-ItemProperty -Path $uninstallKey -Name UninstallString -Value "`"$powershell`" -NoProfile -ExecutionPolicy Bypass -File `"$(Join-Path $target 'uninstall-mnanimat3d.ps1')`""
Set-ItemProperty -Path $uninstallKey -Name NoModify -Type DWord -Value 1
Set-ItemProperty -Path $uninstallKey -Name NoRepair -Type DWord -Value 1

Start-Process -FilePath $powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$launcher`"" -WorkingDirectory $target -WindowStyle Hidden
