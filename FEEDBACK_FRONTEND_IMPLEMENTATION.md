# 📊 Sistema de Feedback - Implementação Frontend

## ✅ O que foi implementado

### 1. **FeedbackPage - Envio de Feedback** ✅

**Arquivo**: `lib/features/feedback/presentation/feedback_page.dart`

**Mudanças**:
- ✅ Importado `FeedbackService`
- ✅ Adicionado estado `_isSubmitting` para controlar loading
- ✅ Implementado método `_submitFeedback()` completo:
  - Captura informações do dispositivo (Android/iOS/Web/Windows/etc)
  - Envia todos os 14 campos Likert + 3 campos abertos
  - Detecta automaticamente se usuário está logado (autenticado) ou não (anônimo)
  - Mostra loading durante envio
  - Exibe mensagem de sucesso/erro
  - Volta para tela anterior após sucesso

**Botão de envio**:
- Desabilitado durante envio
- Mostra `CircularProgressIndicator` enquanto processa
- Verde quando ativo, cinza quando desabilitado

### 2. **AdminFeedbackStatsPage - Dashboard de Estatísticas** ✅

**Arquivo**: `lib/features/admin/presentation/admin_feedback_stats_page.dart`

**Componentes criados**:

#### a) **Card Total de Feedbacks**
- Mostra número total de feedbacks recebidos
- Ícone grande e destaque visual

#### b) **Gráfico Pizza: Distribuição por Vínculo**
- Alunos (azul)
- Visitantes (laranja)
- Funcionários (verde)
- Mostra percentuais
- Legenda com contagem

#### c) **Gráfico Pizza: Tipo de Resposta**
- Anônimos (cinza)
- Identificados (azul)
- Mostra percentuais
- Legenda com contagem

#### d) **Card NPS (Net Promoter Score)**
- Score grande e colorido:
  - Verde: NPS ≥ 75 (Excelente)
  - Verde-claro: NPS ≥ 50 (Muito Bom)
  - Laranja: NPS ≥ 0 (Bom)
  - Vermelho: NPS < 0 (Ruim)
- Baseado na pergunta "Recomendaria o app?"

#### e) **Card: Médias das Avaliações**
- 12 barras de progresso coloridas (1-5):
  - Verde: ≥ 4.5
  - Verde-claro: ≥ 3.5
  - Laranja: ≥ 2.5
  - Vermelho: < 2.5
- Mostra média de cada pergunta com 2 casas decimais

#### f) **Botão: Exportar CSV**
- Preparado para implementar download (em desenvolvimento)

**Funcionalidades**:
- ✅ Pull-to-refresh (arraste para baixo atualiza)
- ✅ Loading state (CircularProgressIndicator)
- ✅ Error state (mensagem + botão "Tentar novamente")
- ✅ AppBar com título e botão voltar

### 3. **FeedbackService - Métodos Adicionados** ✅

**Arquivo**: `lib/data/services/feedback_service.dart`

**Novos métodos**:

```dart
// Obter estatísticas (admin)
Future<Map<String, dynamic>> getStatistics()

// Listar feedbacks com filtros (admin)
Future<List<Map<String, dynamic>>> listFeedbacks({
  String? vinculo,
  bool? isAnonymous,
  String? startDate,
  String? endDate,
})
```

### 4. **Integração com Menu Admin** ✅

**Arquivo**: `lib/features/admin/presentation/admin_upload_page.dart`

**Mudança**:
- Adicionado botão "Estatísticas de Feedback" com ícone de analytics (roxo)
- Navega para `/admin-feedback-stats`

### 5. **Rotas Configuradas** ✅

**Arquivo**: `lib/routes/app_routes.dart`

**Adicionado**:
```dart
static const ADMIN_FEEDBACK_STATS = '/admin-feedback-stats';

GetPage(
  name: ADMIN_FEEDBACK_STATS,
  page: () => const AdminFeedbackStatsPage(),
),
```

### 6. **Dependência fl_chart Adicionada** ✅

**Arquivo**: `pubspec.yaml`

```yaml
fl_chart: ^0.69.0
```

## 🚀 Como Usar

### Para Usuários (Enviar Feedback):

1. Abrir app como **visitante** (sem login) ou **aluno** (com login)
2. Clicar no botão de Feedback (lateral esquerda na HomePage)
3. Responder as 4 etapas do questionário:
   - Parte 1: Perfil (2 perguntas)
   - Parte 2: Navegação (2 Likert)
   - Parte 3: Usabilidade (5 Likert)
   - Parte 4: Satisfação (5 Likert)
   - Parte 5: Perguntas abertas (3 opcionais)
4. Clicar em **ENVIAR**
5. Aguardar confirmação de sucesso

**Como visitante**: Feedback será anônimo (sem associação com usuário)
**Como aluno logado**: Feedback será associado ao seu perfil

### Para Admin (Ver Estatísticas):

1. Fazer login como **admin**
2. Ir para Menu Admin (`/admin-upload`)
3. Clicar em **"Estatísticas de Feedback"** (botão roxo)
4. Visualizar:
   - Total de feedbacks
   - Distribuição por vínculo (pizza)
   - Anônimos vs Identificados (pizza)
   - NPS Score
   - Médias de todas as perguntas (barras)
5. **(Futuro)** Clicar em "Exportar CSV" para baixar dados

## 📦 Instalação

```bash
# 1. Instalar dependências
cd c:\Users\ferra\unigo-frontend
flutter pub get

# 2. Rodar o app
flutter run
```

## 🔌 Endpoints Utilizados

### Frontend → Backend

**1. Enviar Feedback** (Público)
```
POST /api/feedback
Headers: Authorization: Bearer <token> (opcional)
```

**2. Obter Estatísticas** (Admin)
```
GET /api/feedback/stats
Headers: Authorization: Bearer <admin-token>
```

**3. Listar Feedbacks** (Admin - não usado ainda na UI)
```
GET /api/feedback?vinculo=aluno&isAnonymous=true
Headers: Authorization: Bearer <admin-token>
```

## 📊 Estrutura de Dados

### Request (Enviar Feedback):
```json
{
  "vinculo": "visitante",
  "jaUsouAppInterno": false,
  "identificarLocalizacao": 4,
  "instrucoesClaras": 5,
  "representacaoFiel": 4,
  "trajetoFacilSeguir": 5,
  "facilUsar": 5,
  "designClaro": 4,
  "interacaoSemDificuldade": 5,
  "tempoRazoavel": 4,
  "confiancaDestino": 5,
  "recomendaria": 5,
  "voltariaUsar": 5,
  "satisfacaoGeral": 5,
  "oQueAgradou": "Interface intuitiva",
  "dificuldadesEncontradas": null,
  "sugestoesMelhoria": "Modo escuro",
  "deviceInfo": "Android",
  "appVersion": "1.0.0"
}
```

### Response (Estatísticas):
```json
{
  "totalFeedbacks": 150,
  "byVinculo": {
    "aluno": 80,
    "visitante": 60,
    "funcionario": 10
  },
  "byAnonymous": {
    "anonymous": 65,
    "identified": 85
  },
  "averageScores": {
    "identificarLocalizacao": 4.2,
    "instrucoesClaras": 4.5,
    "representacaoFiel": 4.3,
    "trajetoFacilSeguir": 4.6,
    "facilUsar": 4.7,
    "designClaro": 4.4,
    "interacaoSemDificuldade": 4.5,
    "tempoRazoavel": 4.1,
    "confiancaDestino": 4.6,
    "recomendaria": 4.8,
    "voltariaUsar": 4.7,
    "satisfacaoGeral": 4.6
  },
  "nps": 75.5
}
```

## 🎨 Cores Utilizadas

- **Azul Principal**: `Color(0xFF3C3CC0)` - UniGo brand
- **Laranja**: Visitantes no gráfico
- **Verde**: Funcionários no gráfico, scores altos
- **Roxo**: Botão de estatísticas no menu admin
- **Cinza**: Anônimos no gráfico
- **Vermelho**: Scores baixos, erros

## 📈 Métricas Exibidas

### NPS (Net Promoter Score)
- **Cálculo**: (% Promotores - % Detratores)
- **Promotores**: Nota 4-5 na pergunta "Recomendaria"
- **Neutros**: Nota 3
- **Detratores**: Nota 1-2

### Médias (1-5)
- **Navegação**: Q3, Q4
- **Usabilidade**: Q5, Q6, Q7, Q8, Q9
- **Satisfação**: Q10, Q11, Q12, Q13, Q14

## 🔒 Autenticação

### Público (Feedback anônimo):
- Sem header `Authorization`
- Campo `isAnonymous = true` no backend
- `userId = null`

### Autenticado (Feedback identificado):
- Com header `Authorization: Bearer <token>`
- Campo `isAnonymous = false` no backend
- `userId = <id do usuário>`

## 🐛 Tratamento de Erros

### FeedbackPage:
- ✅ Try-catch no `_submitFeedback()`
- ✅ Mostra SnackBar vermelho em caso de erro
- ✅ Permite tentar novamente
- ✅ Não volta para tela anterior se falhar

### AdminFeedbackStatsPage:
- ✅ Loading state inicial
- ✅ Error state com ícone e mensagem
- ✅ Botão "Tentar novamente"
- ✅ Pull-to-refresh para recarregar

## 📱 Responsividade

- ✅ Telas adaptadas para mobile
- ✅ Gráficos responsivos (fl_chart)
- ✅ Cards com padding adequado
- ✅ ScrollView para conteúdo longo

## 🚧 Próximos Passos

1. **Implementar download CSV** na página admin
2. **Adicionar filtros** (por data, por vínculo) na página admin
3. **Criar página de lista detalhada** de feedbacks individuais
4. **Adicionar gráfico de linha** mostrando evolução do NPS ao longo do tempo
5. **Implementar paginação** se houver muitos feedbacks
6. **Adicionar busca** por texto nas respostas abertas

## 📚 Arquivos Criados/Modificados

### ✅ Criados:
1. `lib/features/admin/presentation/admin_feedback_stats_page.dart` - Dashboard com gráficos
2. `lib/data/services/feedback_service.dart` - Serviço com 3 métodos

### ✅ Modificados:
1. `lib/features/feedback/presentation/feedback_page.dart` - Implementado envio
2. `lib/features/admin/presentation/admin_upload_page.dart` - Adicionado botão
3. `lib/routes/app_routes.dart` - Adicionada rota
4. `pubspec.yaml` - Adicionada dependência fl_chart

## 🎯 Resultado Final

**Usuário pode**:
- ✅ Enviar feedback anônimo (visitante)
- ✅ Enviar feedback autenticado (aluno logado)
- ✅ Ver progresso do questionário
- ✅ Receber confirmação de envio

**Admin pode**:
- ✅ Ver total de feedbacks
- ✅ Ver distribuição por vínculo (gráfico pizza)
- ✅ Ver anônimos vs identificados (gráfico pizza)
- ✅ Ver NPS Score com classificação
- ✅ Ver médias de todas as perguntas (barras coloridas)
- ✅ Atualizar dados com pull-to-refresh
- ⏳ Exportar CSV (preparado, não implementado)
