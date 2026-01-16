# 📚 GUIA COMPLETO - Collection Users

## 📋 Campos Obrigatórios

Cada documento em `users/{userId}` deve ter:

```json
{
  "name": "João Silva",           // Nome do usuário
  "email": "joao@email.com",      // Email
  "photoURL": "https://...",       // Foto (pode ser null)
  "isAdmin": false,                // Se é admin
  "createdAt": Timestamp           // Data de criação (opcional)
}
```

---

## 🚀 OPÇÕES PARA GARANTIR OS CAMPOS

### Opção 1: Script Automático (RECOMENDADO)

#### Passo 1: Verificar
```dart
import 'scripts/verify_users_collection.dart';

// Em um botão ou initState:
await verifyUsersCollection();
// Mostra relatório no console
```

#### Passo 2: Corrigir
```dart
await fixUsersCollection();
// Adiciona campos faltantes automaticamente
```

#### Passo 3: Garantir Usuário Atual
```dart
await ensureCurrentUserExists();
// Garante que você está na collection users
```

---

### Opção 2: Manual no Firebase Console

1. **Abrir Firebase Console**
   - https://console.firebase.google.com/

2. **Firestore Database → users**

3. **Para cada usuário:**
   - Verificar se tem todos os campos
   - Adicionar campos faltantes:
     - `name`: string
     - `email`: string
     - `photoURL`: string (pode ser vazio)
     - `isAdmin`: boolean (false)

---

### Opção 3: Criar no Primeiro Login

Adicionar no código de login do app:

```dart
// Após login bem-sucedido
Future<void> createUserIfNotExists(User user) async {
  final firestore = FirebaseFirestore.instance;
  final userDoc = await firestore.collection('users').doc(user.uid).get();

  if (!userDoc.exists) {
    await firestore.collection('users').doc(user.uid).set({
      'name': user.displayName ?? user.email?.split('@')[0] ?? 'Usuário',
      'email': user.email ?? '',
      'photoURL': user.photoURL,
      'isAdmin': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
```

---

## 👑 Criar Usuário Admin

### Opção A: Script
```dart
await createAdminUser(
  userId: 'uid_do_alano',
  name: 'Alano',
  email: 'alano@alanocryptofx.com',
  photoURL: null,
);
```

### Opção B: Firebase Console
1. Firestore Database → users
2. Encontrar seu documento (uid)
3. Editar campo `isAdmin`: `false` → `true`

---

## 🧪 Como Testar

### 1. Executar Relatório
```dart
await fullReport();
```

**Saída esperada:**
```
🔍 VERIFICANDO COLLECTION USERS...

📊 Total de usuários: 3

✅ Usuários completos: 2
⚠️  Usuários incompletos: 1

📋 DETALHES DOS PROBLEMAS:

1. João (joao@email.com)
   ID: abc123
   Campos faltando: photoURL, isAdmin
```

### 2. Corrigir Problemas
```dart
await fixUsersCollection();
```

**Saída esperada:**
```
🔧 CORRIGINDO COLLECTION USERS...

✅ Corrigido: João

🎉 Correção concluída!
   Total corrigido: 1 usuários
```

### 3. Verificar Novamente
```dart
await verifyUsersCollection();
```

**Saída esperada:**
```
✅ Usuários completos: 3
⚠️  Usuários incompletos: 0
```

---

## ⚠️ PROBLEMAS COMUNS

### Problema 1: Usuário não aparece no chat
**Causa:** Falta campo `name` ou `photoURL`

**Solução:**
```dart
await ensureCurrentUserExists();
```

### Problema 2: Badge ADMIN não aparece
**Causa:** Campo `isAdmin` é `null` ou não existe

**Solução:**
```dart
// Firebase Console
users/{userId}:
  isAdmin: true  // Mudar para true
```

### Problema 3: Foto não carrega
**Causa:** Campo `photoURL` com URL inválida

**Solução:**
```dart
// Atualizar no perfil do app
await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .update({'photoURL': novaUrl});
```

---

## 📊 ESTRUTURA COMPLETA

### Collection: users
```
users/
  ├─ abc123/
  │   ├─ name: "João Silva"
  │   ├─ email: "joao@email.com"
  │   ├─ photoURL: "https://..."
  │   ├─ isAdmin: false
  │   └─ createdAt: Timestamp
  │
  ├─ def456/
  │   ├─ name: "Alano"
  │   ├─ email: "alano@..."
  │   ├─ photoURL: null
  │   ├─ isAdmin: true  ← ADMIN
  │   └─ createdAt: Timestamp
  │
  └─ ...
```

### Collection: cupula_chat
```
cupula_chat/
  ├─ msg001/
  │   ├─ userId: "abc123"
  │   ├─ userName: "João Silva"      ← Do users.name
  │   ├─ userPhotoUrl: "https://..." ← Do users.photoURL
  │   ├─ isAdmin: false               ← Do users.isAdmin
  │   ├─ message: "Olá!"
  │   ├─ imageUrl: null
  │   ├─ replyTo: null
  │   ├─ createdAt: Timestamp
  │   └─ editedAt: null
  │
  └─ ...
```

---

## ✅ CHECKLIST FINAL

- [ ] Todos os usuários têm campo `name`
- [ ] Todos os usuários têm campo `email`
- [ ] Todos os usuários têm campo `photoURL` (pode ser null)
- [ ] Todos os usuários têm campo `isAdmin`
- [ ] Admin tem `isAdmin: true`
- [ ] Mensagens novas salvam `userPhotoUrl`
- [ ] Avatar no AppBar mostra foto real
- [ ] Avatar nas mensagens mostra foto real
- [ ] Badge ADMIN aparece para admins

---

## 🎯 RESUMO RÁPIDO

```bash
# 1. Verificar
await verifyUsersCollection()

# 2. Corrigir
await fixUsersCollection()

# 3. Garantir seu usuário
await ensureCurrentUserExists()

# 4. Testar app
# - Abrir chat
# - Enviar mensagem
# - Ver foto no avatar
```

**Pronto!** 🎉
