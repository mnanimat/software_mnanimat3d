# Instalador Windows do MNAnimat3D

Execute na raiz do projeto:

```powershell
powershell -ExecutionPolicy Bypass -File .\packaging\windows\Build-Installer.ps1
```

O build usa apenas PowerShell, `Compress-Archive` e o compilador C#/.NET Framework incluído no Windows. O resultado é `dist/windows/MNAnimat3D-Setup.exe`.

O instalador é por usuário, não pede acesso de administrador e instala em `%LOCALAPPDATA%\Programs\MNAnimat3D`. Ele cria atalhos no Menu Iniciar e na Área de Trabalho, registra a desinstalação em **Aplicativos instalados** e abre o editor em uma janela dedicada do Microsoft Edge (ou Chrome/navegador padrão como fallback).
