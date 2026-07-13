# MNAnimat3D para Android

Projeto Android Studio do MNAnimat3D. O APK funciona offline e inclui o editor, Three.js, Rain, Snow, a personagem blocada CC0 e os 140 objetos do Kenney Furniture Kit. Os arquivos `.blend`, FBX e ZIPs de origem ficam exclusivos do pacote Windows/código-fonte.

## Requisitos

- Android Studio com JDK 17 ou mais recente.
- Android SDK Platform 36 e Build Tools 36.0.0.
- Smartphone com Android 13 (API 33) ou mais recente e OpenGL ES 3.0.
- Recomenda-se 6 GB de RAM ou mais para abrir Rain ou Snow confortavelmente.

## Gerar o APK

1. Abra a pasta `android` no Android Studio.
2. Aguarde a sincronização do Gradle. A tarefa `syncMNAnimat3DWebAssets` copia automaticamente o editor, as personagens e o catálogo de cenário.
3. Use **Build > Build APK(s)**.
4. O APK de desenvolvimento será criado em `android/app/build/outputs/apk/debug/app-debug.apk`.

Também é possível gerar no terminal do Android Studio:

```powershell
.\gradlew.bat assembleDebug
```

O projeto usa `minSdk 33`, `targetSdk 36`, AGP 9.2.1 e Gradle 9.4.1. Um carregador nativo expõe os arquivos empacotados em uma origem HTTPS local segura, sem depender de `file://`. Arquivos exportados são gravados em `Downloads/MNAnimat3D` via MediaStore, sem acesso geral ao armazenamento.

## Distribuição

- O APK completo é grande porque as personagens e o Furniture Kit ficam disponíveis offline.
- O botão Blender fica desativado no Android; CloudRig, Python e os `.blend` completos permanecem na versão Windows.
- Para publicar, use **Build > Generate Signed App Bundle or APK** e mantenha a chave de assinatura fora do repositório.
