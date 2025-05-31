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
API_URL=http://localhost:3000

```

4. Execute o aplicativo:

Para desenvolvimento web com porta fixa (recomendado):
```powershell
./start-dev.bat
```
Isso iniciará o servidor web na porta 3001.

Ou para outros ambientes:
```bash
flutter run
```

## 🛠️ Scripts Disponíveis

- `flutter pub get` - Instala as dependências
- `./start-dev.bat` - Executa o aplicativo web na porta 3001 (Windows)
- `flutter run` - Executa o aplicativo em qualquer plataforma
- `flutter build` - Gera o build do aplicativo

## 📝 Notas

- Para desenvolvimento web, recomenda-se usar o script `start-dev.bat` que garante uma porta fixa (3001)
- O backend está configurado para aceitar conexões de qualquer porta do localhost
- `flutter test` - Executa os testes
- `flutter analyze` - Analisa o código


# unigo-frontend