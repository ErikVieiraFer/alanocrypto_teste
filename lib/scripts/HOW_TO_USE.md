# 📝 Como Usar o Script de Atualização

## Atualizar Mensagens Antigas do Chat

### Opção 1: Usar em um botão temporário (RECOMENDADO)

1. **Adicionar botão temporário na tela:**

```dart
// Em qualquer tela (ex: dashboard_screen.dart)
import '../scripts/update_chat_messages.dart';

// Adicionar FloatingActionButton temporário
floatingActionButton: FloatingActionButton(
  onPressed: () async {
    await updateChatMessages(); // ou updateChatMessagesSimple()
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mensagens atualizadas!')),
    );
  },
  child: Icon(Icons.update),
),
```

2. **Executar o app:**
```bash
flutter run
```

3. **Clicar no botão flutuante** (apenas uma vez!)

4. **Remover o botão e o import** após usar

---

### Opção 2: Usar no initState (Cuidado!)

```dart
@override
void initState() {
  super.initState();

  // EXECUTAR APENAS UMA VEZ!
  // Comentar depois de rodar
  // updateChatMessages();
}
```

---

### Opção 3: Console Firebase (Manual)

1. Firebase Console → Firestore Database
2. Collection `cupula_chat`
3. Para cada documento:
   - Clicar em "Add field"
   - Field: `userPhotoUrl`
   - Type: `string`
   - Value: `null` (deixar vazio)

---

## 🔍 Diferença entre os métodos

### `updateChatMessages()` (Completo)
- Busca o usuário no Firestore
- Adiciona a foto real se encontrar
- Mais lento, mas completo

### `updateChatMessagesSimple()` (Rápido)
- Apenas adiciona `userPhotoUrl: null`
- Mais rápido
- As fotos vão aparecer nas próximas mensagens

---

## ⚠️ IMPORTANTE

- ✅ Executar **APENAS UMA VEZ**
- ✅ Deletar o script após usar
- ✅ Fazer backup do Firestore antes (opcional)
- ❌ NÃO executar múltiplas vezes

---

## 🧪 Como Testar

Após executar:

1. Abrir Firebase Console
2. Ver collection `cupula_chat`
3. Verificar se mensagens têm campo `userPhotoUrl`
4. Testar app → Chat deve mostrar fotos
