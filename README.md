# Unigo Frontend

Frontend da aplicação Unigo, uma plataforma educacional desenvolvida com Flutter.

## 🚀 Tecnologias

- Flutter
- Dart
- Provider para gerenciamento de estado
- Cloudinary para upload de imagens
- HTTP para requisições à API

## 📋 Pré-requisitos

- Flutter SDK (versão 3.0 ou superior)
- Dart SDK
- Android Studio ou VS Code com extensões do Flutter
- Emulador Android/iOS ou dispositivo físico

## 🔧 Instalação

1. Clone o repositório:
```bash
git clone https://github.com/JenifferFerraz/unigo-frontend.git
cd unigo-frontend
```

2. Instale as dependências:
```bash
flutter pub get
```

3. Configure as variáveis de ambiente:
Crie um arquivo `.env` na raiz do projeto com as seguintes variáveis:
```env
API_URL=http://localhost:3002
CLOUDINARY_CLOUD_NAME=seu_cloud_name
CLOUDINARY_API_KEY=sua_api_key
```

4. Execute o aplicativo:
```bash
flutter run
```


## 🛠️ Scripts Disponíveis

- `flutter pub get` - Instala as dependências
- `flutter run` - Executa o aplicativo
- `flutter build` - Gera o build do aplicativo
- `flutter test` - Executa os testes
- `flutter analyze` - Analisa o código


# unigo-frontend