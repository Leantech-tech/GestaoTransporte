Instruções para usar a imagem como favicon / PWA icon e como ícone nativo

1) PWA (web) — favicon e ícones "instalar na tela inicial"

- Coloque a imagem que você enviou no repositório nos seguintes caminhos (substitua os arquivos existentes):
  - `frontend/web/favicon.png` (favicon padrão)
  - `frontend/web/icons/Icon-192.png` (PWA 192x192)
  - `frontend/web/icons/Icon-512.png` (PWA 512x512)
  - opcionalmente `frontend/web/icons/Icon-maskable-192.png` e `Icon-maskable-512.png` (para ícones maskable)

- Gere as versões nas dimensões corretas (192x192 e 512x512). Você pode usar ImageMagick localmente:

```bash
# a partir da pasta 'frontend'
magick convert source.png -resize 192x192 web/icons/Icon-192.png
magick convert source.png -resize 512x512 web/icons/Icon-512.png
# maskable (opcional)
magick convert source.png -resize 192x192 web/icons/Icon-maskable-192.png
magick convert source.png -resize 512x512 web/icons/Icon-maskable-512.png
# favicon (32x32) opcional
magick convert source.png -resize 32x32 web/favicon.png
```

- O projeto já referencia `web/manifest.json` e `web/index.html`. Depois de substituir os arquivos, faça um `flutter build web` e faça o deploy.

2) Android / iOS (ícones nativos)

- Copie a imagem original para: `frontend/assets/images/app_icon.png` (formato PNG, idealmente quadrado 1024x1024).
- Execute os comandos abaixo na pasta `frontend` para instalar a dependência e gerar os ícones nativos:

```bash
cd frontend
flutter pub get
flutter pub run flutter_launcher_icons:main
```

- Isso irá gerar automaticamente os ícones para Android e iOS com base no `flutter_icons` configurado no `pubspec.yaml`.

3) Notas e recomendações

- Se você quiser que eu gere e copie as imagens para `web/icons/` e `web/favicon.png`, carregue o arquivo de imagem no workspace (arraste para a conversa) ou me diga onde ele está no seu computador; eu colocarei automaticamente nos caminhos corretos.
- Se não tiver ImageMagick, pode usar sites como https://realfavicongenerator.net/ para criar os ícones e o `manifest.json` apropriado.

Se quiser, eu:
- copio a imagem enviada para os locais `web/favicon.png` e `web/icons/*` (preciso que você faça upload aqui),
- ou gero automaticamente um conjunto de ícones se você me autorizar a usar a imagem que você anexou agora.