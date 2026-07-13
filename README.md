# MNAnimat3D

Editor de modelagem, montagem de cenário, rig e animação 3D para Windows e Android. A interface oferece viewport acelerado por WebGL, transformação com gizmos, formas básicas editáveis, hierarquia, materiais, atalhos, timeline com keyframes, reprodução e exportação GLB, OBJ, PNG e WebM.

## Executar no Windows

Na raiz do projeto, execute:

```powershell
powershell -ExecutionPolicy Bypass -File .\run-mnanimat3d.ps1
```

Depois abra `http://localhost:4173/`. O servidor local também permite que os botões **Blender** abram as fontes `.blend` instaladas com o projeto.

## Controles principais

- `Q`: selecionar; `W`: mover; `E`: girar; `R`: escala.
- `Alt + arrastar`: orbitar; botão do meio: mover a câmera; scroll: zoom; `F`: focar.
- `1` a `6`: formas básicas; `K`: registrar pose; `Espaço`: reproduzir/pausar.
- `Ctrl+Z` / `Ctrl+Y`: desfazer/refazer; `Ctrl+D`: duplicar; `Delete`: excluir.

## Personagens incluídas

- **Rain 3.3** e **Snow 4.2**, Blender Studio, CC BY 4.0: 23 controles deformadores diretos no editor. Os `.blend` originais preservam CloudRig, IK/FK, constraints, snapping e a interface oficial do Blender.
- **Personagem blocada**, Kenney Blocky Characters 2.0, CC0: sete nós controláveis, 27 animações incluídas e arquivo Blender editável. É uma criação genérica e não usa personagens, texturas, nomes ou marcas de Minecraft/Mojang/Microsoft.

## Pacote de cenário

O navegador de recursos inclui os 140 objetos GLB do **Kenney Furniture Kit** sob CC0: arquitetura modular, banheiro, cozinha, quarto, sala, escritório, iluminação, plantas e decoração. A busca e o filtro por categoria funcionam offline.

Consulte [licenças das personagens](./assets/characters/LICENSES.md) e [avisos de terceiros](./THIRD_PARTY_NOTICES.md) antes de redistribuir assets ou adaptações.

## Gerar o instalador Windows

```powershell
powershell -ExecutionPolicy Bypass -File .\packaging\windows\Build-Installer.ps1
```

O resultado fica em `dist/windows/MNAnimat3D-Setup.exe`. A instalação é por usuário em `%LOCALAPPDATA%\Programs\MNAnimat3D`, sem exigir administrador.

## Gerar o APK Android 13+

Abra a pasta `android` no Android Studio e use **Build > Build APK(s)**, ou execute:

```powershell
cd android
.\gradlew.bat assembleDebug
```

O projeto usa `minSdk 33` (Android 13), `targetSdk 36`, AGP 9.2.1, Gradle 9.4.1, Java 17 e OpenGL ES 3.0. O APK inclui o editor e os assets offline; arquivos exportados são gravados em `Downloads/MNAnimat3D` via MediaStore.
