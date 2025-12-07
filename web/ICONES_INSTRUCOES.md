# 📱 Instruções para Criar Ícones do UniGo

## Opção 1: Usar um site online (MAIS FÁCIL)

### 1. Acesse um destes sites:
- **https://www.favicon-generator.org/** (Recomendado)
- **https://realfavicongenerator.net/**
- **https://www.websiteplanet.com/webtools/favicon-generator/**

### 2. Faça o upload da logo:
- Arquivo: `assets/images/Logo.png`
- O site gerará automaticamente todos os tamanhos necessários

### 3. Baixe os arquivos gerados e substitua em `web/icons/`:
- `Icon-192.png` (192x192 pixels)
- `Icon-512.png` (512x512 pixels)
- `Icon-maskable-192.png` (192x192 pixels com padding)
- `Icon-maskable-512.png` (512x512 pixels com padding)

### 4. Substitua também o `favicon.png` na pasta `web/`

---

## Opção 2: Usar Photoshop/GIMP/Figma

### Tamanhos necessários:
1. **Icon-192.png**: 192x192 pixels
2. **Icon-512.png**: 512x512 pixels
3. **Icon-maskable-192.png**: 192x192 pixels (com 20% de padding em volta)
4. **Icon-maskable-512.png**: 512x512 pixels (com 20% de padding em volta)
5. **favicon.png**: 32x32 pixels

### Dicas:
- Use fundo transparente ou a cor roxa do UniGo (#3C3CC0)
- Para os ícones "maskable", deixe a logo centralizada com espaço em volta
- Mantenha o formato PNG com boa qualidade

---

## Opção 3: Usar ImageMagick (linha de comando)

Se tiver o ImageMagick instalado, rode estes comandos na pasta do projeto:

```bash
# Copiar logo para web/icons/
copy assets\images\Logo.png web\icons\Icon-512.png

# Redimensionar para 192px
magick web\icons\Icon-512.png -resize 192x192 web\icons\Icon-192.png

# Criar versões maskable (com padding)
magick assets\images\Logo.png -resize 410x410 -background "#3C3CC0" -gravity center -extent 512x512 web\icons\Icon-maskable-512.png
magick assets\images\Logo.png -resize 154x154 -background "#3C3CC0" -gravity center -extent 192x192 web\icons\Icon-maskable-192.png

# Criar favicon
magick assets\images\Logo.png -resize 32x32 web\favicon.png
```

---

## ✅ Após substituir os ícones:

1. Limpe o cache da build:
   ```bash
   flutter clean
   ```

2. Gere a build novamente:
   ```bash
   flutter build web
   ```

3. Os novos ícones aparecerão:
   - Na aba do navegador (favicon)
   - Ao adicionar à tela inicial (PWA)
   - Em splash screens

---

## 🎨 Cores do UniGo já configuradas:

- **Cor principal**: `#3C3CC0` (Roxo UniGo)
- **Nome**: UniGo - Sistema Universitário
- **Descrição**: Sistema de Navegação e Gerenciamento Universitário

Tudo já está configurado no `manifest.json` e `index.html`! 🚀
