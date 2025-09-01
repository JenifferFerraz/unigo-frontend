# Configuração de Ambiente - UniGo Mobile

## Visão Geral

O UniGo Mobile agora detecta automaticamente o ambiente de execução e usa a URL da API apropriada para cada plataforma.

## Configuração do .env

Crie um arquivo `.env` na raiz do projeto com as seguintes variáveis:

```env
# ========================================
# URLs da API para diferentes ambientes
# ========================================

# Flutter Web e iOS (localhost)
API_URL=http://localhost:3000
SOCKET_URL=http://localhost:3000

# Android Emulador (IP especial do emulador)
API_URL_ANDROID_EMULATOR=http://10.0.2.2:3000
SOCKET_URL_ANDROID_EMULATOR=http://10.0.2.2:3000

# Android Dispositivo Físico (IP da sua máquina na rede local)
API_URL_ANDROID_DEVICE=http://192.168.1.100:3000
SOCKET_URL_ANDROID_DEVICE=http://192.168.1.100:3000

# ========================================
# Outras configurações
# ========================================
CLOUDINARY_CLOUD_NAME=Teste_UniGo
CLOUDINARY_API_KEY=764713151888515
CLOUDINARY_API_SECRET=_FgZAXHgLv4gWvW3aSDnv_KTBCM
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
APP_NAME=UniGo
APP_ENV=development
```

## Como Funciona a Detecção Automática

### 1. **Flutter Web**
- Usa: `API_URL` e `SOCKET_URL`
- Fallback: `http://localhost:3000`

### 2. **Android Emulador**
- Usa: `API_URL_ANDROID_EMULATOR` e `SOCKET_URL_ANDROID_EMULATOR`
- Fallback: `http://10.0.2.2:3000`
- **Nota**: `10.0.2.2` é o IP especial do emulador que aponta para o localhost da máquina host

### 3. **Android Dispositivo Físico**
- Usa: `API_URL_ANDROID_DEVICE` e `SOCKET_URL_ANDROID_DEVICE`
- Fallback: `http://192.168.1.100:3000`
- **IMPORTANTE**: Substitua `192.168.1.100` pelo IP real da sua máquina

### 4. **iOS**
- Usa: `API_URL` e `SOCKET_URL`
- Fallback: `http://localhost:3000`

## Como Descobrir o IP da Sua Máquina

### Windows
```bash
ipconfig
```
Procure por "IPv4 Address" na sua rede local (geralmente começa com 192.168.x.x)

### Linux/Mac
```bash
ifconfig
# ou
ip addr show
```

## Debug e Verificação

O app imprime automaticamente as informações do ambiente no console durante a inicialização. Você verá algo como:

```
🌍 === INFORMAÇÕES DO AMBIENTE ===
📱 Plataforma: android
🌐 É Web: false
🤖 É Android: true
🍎 É iOS: false
🎮 É Emulador: true
🔗 API Base URL: http://10.0.2.2:3000
📡 Socket URL: http://10.0.2.2:3000
=====================================
```

## Exemplo de Uso no Código

```dart
import 'package:your_app/core/config/env_service.dart';

// A URL é detectada automaticamente
final apiUrl = EnvService.apiBaseUrl;
final socketUrl = EnvService.socketUrl;

// Para debug
EnvService.printEnvironmentInfo();
```

## Troubleshooting

### Problema: App não consegue conectar com o backend
1. Verifique se o backend está rodando
2. Confirme se o IP no `.env` está correto
3. Verifique se não há firewall bloqueando a conexão
4. Use `EnvService.printEnvironmentInfo()` para ver qual URL está sendo usada

### Problema: Emulador não consegue acessar localhost
- Use `10.0.2.2` em vez de `localhost` para emuladores Android
- O app detecta automaticamente e usa o IP correto

### Problema: Dispositivo físico não consegue acessar
- Use o IP da sua máquina na rede local (não localhost)
- Verifique se ambos estão na mesma rede Wi-Fi
- Confirme se o IP está correto no `.env`

## Arquivos Modificados

- `lib/core/config/env_service.dart` - Lógica de detecção automática
- `lib/main.dart` - Debug automático durante inicialização
- `.env` - Configurações de ambiente (você deve criar)

## Benefícios

✅ **Detecção automática** do ambiente
✅ **Configuração centralizada** no `.env`
✅ **Fallbacks inteligentes** para cada plataforma
✅ **Debug automático** durante inicialização
✅ **Suporte completo** para Web, Android e iOS
✅ **Fácil manutenção** e configuração 