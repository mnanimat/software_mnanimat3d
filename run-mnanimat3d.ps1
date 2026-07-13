param([int]$Port = 4173)

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$server = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, $Port)
$mime = @{'.html'='text/html; charset=utf-8';'.js'='text/javascript; charset=utf-8';'.css'='text/css; charset=utf-8';'.json'='application/json; charset=utf-8';'.webmanifest'='application/manifest+json';'.svg'='image/svg+xml';'.png'='image/png';'.glb'='model/gltf-binary';'.gltf'='model/gltf+json';'.wasm'='application/wasm'}
$blenderExe = Get-ChildItem -LiteralPath 'C:\Program Files\Blender Foundation' -Filter 'blender.exe' -Recurse -ErrorAction SilentlyContinue |
  Sort-Object -Property FullName -Descending |
  Select-Object -First 1 -ExpandProperty FullName
$rigFiles = @{
  rain = Join-Path $root 'assets\characters\rain\original\Rain v3.3\rain_v3.2.blend'
  snow = Join-Path $root 'assets\characters\snow\original\Snow\snow_v4.2.blend'
  blocky = Join-Path $root 'assets\characters\blocky\original\blocky-character.blend'
}
$server.Start()
Write-Host "MNAnimat3D disponível em http://localhost:$Port/"
Write-Host 'Pressione Ctrl+C para encerrar.'

try {
  while ($true) {
    $client = $server.AcceptTcpClient()
    try {
      $client.SendTimeout = 15000
      $client.ReceiveTimeout = 15000
      $stream = $client.GetStream()
      $reader = [IO.StreamReader]::new($stream, [Text.Encoding]::ASCII, $false, 1024, $true)
      $requestLine = $reader.ReadLine()
      while (($line = $reader.ReadLine()) -ne '') { if ($null -eq $line) { break } }
      $parts = $requestLine -split ' '
      $method = if ($parts.Length -gt 0) { $parts[0] } else { 'GET' }
      $requestTarget = if ($parts.Length -gt 1) { $parts[1] } else { '/' }

      if ($requestTarget -match '^/api/open-rig\?name=(rain|snow|blocky)$') {
        $rigName = $Matches[1]
        try {
          if (-not $blenderExe -or -not (Test-Path -LiteralPath $blenderExe -PathType Leaf)) { throw 'Blender não foi encontrado neste Windows.' }
          $blendFile = $rigFiles[$rigName]
          if (-not (Test-Path -LiteralPath $blendFile -PathType Leaf)) { throw 'O arquivo Blender da personagem não foi encontrado.' }
          $quotedBlend = '"{0}"' -f $blendFile
          Start-Process -FilePath $blenderExe -ArgumentList @('--enable-autoexec', $quotedBlend)
          $description = if ($rigName -eq 'blocky') { 'com os sete nós articulados e as animações Kenney' } else { 'com os controladores CloudRig oficiais' }
          $status = '200 OK'
          $contentType = 'application/json; charset=utf-8'
          $body = [Text.Encoding]::UTF8.GetBytes((@{ message = "Personagem $rigName aberta no Blender $description." } | ConvertTo-Json -Compress))
        } catch {
          $status = '500 Internal Server Error'
          $contentType = 'application/json; charset=utf-8'
          $body = [Text.Encoding]::UTF8.GetBytes((@{ message = $_.Exception.Message } | ConvertTo-Json -Compress))
        }
      } elseif ($requestTarget -eq '/api/app-info') {
        $status = '200 OK'
        $contentType = 'application/json; charset=utf-8'
        $body = [Text.Encoding]::UTF8.GetBytes((@{ name = 'MNAnimat3D'; version = '1.0.0'; port = $Port } | ConvertTo-Json -Compress))
      } elseif ($requestTarget -eq '/api/rig-status') {
        $status = '200 OK'
        $contentType = 'application/json; charset=utf-8'
        $body = [Text.Encoding]::UTF8.GetBytes((@{
          blender = [bool]($blenderExe -and (Test-Path -LiteralPath $blenderExe -PathType Leaf))
          rain = [bool](Test-Path -LiteralPath $rigFiles.rain -PathType Leaf)
          snow = [bool](Test-Path -LiteralPath $rigFiles.snow -PathType Leaf)
          blocky = [bool](Test-Path -LiteralPath $rigFiles.blocky -PathType Leaf)
        } | ConvertTo-Json -Compress))
      } else {
        $urlPath = ($requestTarget -split '\?')[0]
        $relative = [Uri]::UnescapeDataString($urlPath.TrimStart('/'))
        if ([string]::IsNullOrWhiteSpace($relative)) { $relative = 'index.html' }
        $candidate = [IO.Path]::GetFullPath((Join-Path $root $relative))

        if (-not $candidate.StartsWith($root, [StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
          $status = '404 Not Found'
          $contentType = 'text/plain; charset=utf-8'
          $body = [Text.Encoding]::UTF8.GetBytes('Arquivo não encontrado')
        } else {
          $status = '200 OK'
          $extension = [IO.Path]::GetExtension($candidate).ToLowerInvariant()
          $contentType = if ($mime.ContainsKey($extension)) { $mime[$extension] } else { 'application/octet-stream' }
          $body = [IO.File]::ReadAllBytes($candidate)
        }
      }

      $header = "HTTP/1.1 $status`r`nContent-Type: $contentType`r`nContent-Length: $($body.Length)`r`nCache-Control: no-cache`r`nConnection: close`r`n`r`n"
      $headerBytes = [Text.Encoding]::ASCII.GetBytes($header)
      $stream.Write($headerBytes, 0, $headerBytes.Length)
      if ($method -ne 'HEAD') { $stream.Write($body, 0, $body.Length) }
      $stream.Flush()
    } catch [IO.IOException] {
      # O navegador pode cancelar uma transferência grande ao recarregar a página.
    } catch [ObjectDisposedException] {
      # A conexão já foi encerrada pelo cliente; o servidor continua disponível.
    } finally {
      $client.Close()
    }
  }
} finally {
  $server.Stop()
}
