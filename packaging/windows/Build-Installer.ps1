param(
    [string]$ProjectRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
)

$ErrorActionPreference = 'Stop'
$projectRootPath = [IO.Path]::GetFullPath($ProjectRoot)
$distDirectory = Join-Path $projectRootPath 'dist\windows'
$stageDirectory = Join-Path $distDirectory 'staging'
$payloadDirectory = Join-Path $stageDirectory 'payload'
$installerDirectory = Join-Path $stageDirectory 'installer'
$targetInstaller = Join-Path $distDirectory 'MNAnimat3D-Setup.exe'
$iexpressDirectory = Join-Path $env:TEMP 'MNAnimat3D-IExpress'
$iexpressTarget = Join-Path $iexpressDirectory 'MNAnimat3D-Setup.exe'

function Reset-BuildDirectory([string]$Path, [string]$AllowedParent) {
    $fullPath = [IO.Path]::GetFullPath($Path)
    $fullParent = [IO.Path]::GetFullPath($AllowedParent).TrimEnd('\') + '\'
    if (-not $fullPath.StartsWith($fullParent, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Pasta de build fora do destino esperado: $fullPath"
    }
    if (Test-Path -LiteralPath $fullPath) { Remove-Item -LiteralPath $fullPath -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $fullPath | Out-Null
}

Reset-BuildDirectory $stageDirectory $distDirectory
Reset-BuildDirectory $iexpressDirectory $env:TEMP
New-Item -ItemType Directory -Force -Path $payloadDirectory, $installerDirectory | Out-Null

foreach ($file in @('index.html','styles.css','manifest.webmanifest','service-worker.js','THIRD_PARTY_NOTICES.md','README.md','run-mnanimat3d.ps1')) {
    Copy-Item -LiteralPath (Join-Path $projectRootPath $file) -Destination $payloadDirectory
}
Copy-Item -LiteralPath (Join-Path $projectRootPath 'src') -Destination $payloadDirectory -Recurse
Copy-Item -LiteralPath (Join-Path $projectRootPath 'lib') -Destination $payloadDirectory -Recurse

$assetRoot = Join-Path $payloadDirectory 'assets'
New-Item -ItemType Directory -Force -Path $assetRoot | Out-Null
Copy-Item -LiteralPath (Join-Path $projectRootPath 'assets\icon.svg') -Destination $assetRoot

$characterTarget = Join-Path $assetRoot 'characters'
New-Item -ItemType Directory -Force -Path $characterTarget | Out-Null
Copy-Item -LiteralPath (Join-Path $projectRootPath 'assets\characters\LICENSES.md') -Destination $characterTarget
foreach ($slug in @('rain','snow')) {
    $source = Join-Path $projectRootPath "assets\characters\$slug"
    $destination = Join-Path $characterTarget $slug
    New-Item -ItemType Directory -Force -Path $destination | Out-Null
    Copy-Item -LiteralPath (Join-Path $source 'ATTRIBUTION.txt'),(Join-Path $source 'controller-manifest.json'),(Join-Path $source "$slug-lumina.glb") -Destination $destination
    Copy-Item -LiteralPath (Join-Path $source 'original') -Destination $destination -Recurse
}
$blockySource = Join-Path $projectRootPath 'assets\characters\blocky'
$blockyTarget = Join-Path $characterTarget 'blocky'
New-Item -ItemType Directory -Force -Path $blockyTarget | Out-Null
Copy-Item -LiteralPath (Join-Path $blockySource 'ATTRIBUTION.txt'),(Join-Path $blockySource 'KENNEY_LICENSE.txt'),(Join-Path $blockySource 'controller-manifest.json'),(Join-Path $blockySource 'blocky-character.glb') -Destination $blockyTarget
Copy-Item -LiteralPath (Join-Path $blockySource 'Textures'),(Join-Path $blockySource 'original') -Destination $blockyTarget -Recurse

$furnitureSource = Join-Path $projectRootPath 'assets\environment\furniture-kit'
$furnitureTarget = Join-Path $assetRoot 'environment\furniture-kit'
New-Item -ItemType Directory -Force -Path $furnitureTarget | Out-Null
Copy-Item -LiteralPath (Join-Path $furnitureSource 'KENNEY_LICENSE.txt'),(Join-Path $furnitureSource 'catalog.json') -Destination $furnitureTarget
Copy-Item -LiteralPath (Join-Path $furnitureSource 'models') -Destination $furnitureTarget -Recurse

Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'runtime\launch-mnanimat3d.ps1'),(Join-Path $PSScriptRoot 'runtime\uninstall-mnanimat3d.ps1') -Destination $payloadDirectory

Add-Type -AssemblyName System.Drawing
$bitmap = New-Object Drawing.Bitmap 256,256
$graphics = [Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.Clear([Drawing.Color]::FromArgb(11,14,26))
$brush = New-Object Drawing.Drawing2D.LinearGradientBrush([Drawing.Rectangle]::new(24,24,208,208),[Drawing.Color]::FromArgb(155,123,255),[Drawing.Color]::FromArgb(39,213,255),45)
$graphics.FillEllipse($brush,24,24,208,208)
$inner = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(20,23,42))
$graphics.FillEllipse($inner,38,38,180,180)
$font = New-Object Drawing.Font 'Segoe UI',58,([Drawing.FontStyle]::Bold),([Drawing.GraphicsUnit]::Pixel)
$textBrush = New-Object Drawing.SolidBrush ([Drawing.Color]::White)
$format = New-Object Drawing.StringFormat
$format.Alignment = [Drawing.StringAlignment]::Center
$format.LineAlignment = [Drawing.StringAlignment]::Center
$graphics.DrawString('MN',$font,$textBrush,[Drawing.RectangleF]::new(38,38,180,180),$format)
$iconHandle = $bitmap.GetHicon()
$icon = [Drawing.Icon]::FromHandle($iconHandle)
$iconStream = [IO.File]::Create((Join-Path $payloadDirectory 'MNAnimat3D.ico'))
try { $icon.Save($iconStream) } finally { $iconStream.Dispose(); $icon.Dispose(); $graphics.Dispose(); $bitmap.Dispose() }

$payloadZip = Join-Path $iexpressDirectory 'payload.zip'
Compress-Archive -Path (Join-Path $payloadDirectory '*') -DestinationPath $payloadZip -CompressionLevel Optimal
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'installer\Install-MNAnimat3D.ps1'),(Join-Path $PSScriptRoot 'installer\install.cmd') -Destination $iexpressDirectory
Copy-Item -LiteralPath (Join-Path $payloadDirectory 'MNAnimat3D.ico') -Destination $iexpressDirectory

$bootstrapSource = Join-Path $iexpressDirectory 'MNAnimat3D.Setup.cs'
$bootstrapCode = @'
using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Windows.Forms;

internal static class MNAnimat3DSetup
{
    [STAThread]
    private static int Main()
    {
        string temporaryDirectory = Path.Combine(Path.GetTempPath(), "MNAnimat3D-Setup-" + Guid.NewGuid().ToString("N"));
        try
        {
            Directory.CreateDirectory(temporaryDirectory);
            string payloadPath = Path.Combine(temporaryDirectory, "payload.zip");
            string scriptPath = Path.Combine(temporaryDirectory, "Install-MNAnimat3D.ps1");
            ExtractResource("MNAnimat3D.Payload", payloadPath);
            ExtractResource("MNAnimat3D.InstallScript", scriptPath);

            string powershell = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Windows), "System32", "WindowsPowerShell", "v1.0", "powershell.exe");
            ProcessStartInfo startInfo = new ProcessStartInfo
            {
                FileName = powershell,
                Arguments = "-NoProfile -ExecutionPolicy Bypass -File \"" + scriptPath + "\"",
                WorkingDirectory = temporaryDirectory,
                UseShellExecute = false
            };
            using (Process process = Process.Start(startInfo))
            {
                process.WaitForExit();
                if (process.ExitCode != 0) throw new InvalidOperationException("A instalacao retornou o codigo " + process.ExitCode + ".");
            }
            return 0;
        }
        catch (Exception error)
        {
            MessageBox.Show(error.Message, "MNAnimat3D", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 1;
        }
        finally
        {
            try { if (Directory.Exists(temporaryDirectory)) Directory.Delete(temporaryDirectory, true); } catch { }
        }
    }

    private static void ExtractResource(string name, string destination)
    {
        using (Stream input = Assembly.GetExecutingAssembly().GetManifestResourceStream(name))
        {
            if (input == null) throw new InvalidOperationException("Recurso ausente: " + name);
            using (FileStream output = File.Create(destination)) input.CopyTo(output);
        }
    }
}
'@
Set-Content -LiteralPath $bootstrapSource -Value $bootstrapCode -Encoding ASCII

$compiler = Join-Path $env:SystemRoot 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $compiler -PathType Leaf)) {
    $compiler = Join-Path $env:SystemRoot 'Microsoft.NET\Framework\v4.0.30319\csc.exe'
}
if (-not (Test-Path -LiteralPath $compiler -PathType Leaf)) { throw 'O compilador C# do Windows não está disponível.' }

& $compiler /nologo /target:winexe /optimize+ "/out:$iexpressTarget" "/win32icon:$(Join-Path $iexpressDirectory 'MNAnimat3D.ico')" "/resource:$payloadZip,MNAnimat3D.Payload" "/resource:$(Join-Path $iexpressDirectory 'Install-MNAnimat3D.ps1'),MNAnimat3D.InstallScript" /reference:System.Windows.Forms.dll $bootstrapSource
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $iexpressTarget -PathType Leaf)) {
    throw "O compilador C# não criou o instalador (código $LASTEXITCODE)."
}
Copy-Item -LiteralPath $iexpressTarget -Destination $targetInstaller -Force
$result = Get-Item -LiteralPath $targetInstaller | Select-Object FullName,Length,LastWriteTime
foreach ($cleanup in @(
    @{ Path = $stageDirectory; Parent = $distDirectory },
    @{ Path = $iexpressDirectory; Parent = $env:TEMP }
)) {
    $cleanupPath = [IO.Path]::GetFullPath($cleanup.Path)
    $cleanupParent = [IO.Path]::GetFullPath($cleanup.Parent).TrimEnd('\') + '\'
    if (-not $cleanupPath.StartsWith($cleanupParent, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Limpeza fora do destino esperado: $cleanupPath"
    }
    Remove-Item -LiteralPath $cleanupPath -Recurse -Force -ErrorAction SilentlyContinue
}
$result
