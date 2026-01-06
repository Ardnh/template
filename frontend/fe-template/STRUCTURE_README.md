# Simple Vue.js + TypeScript Structure

## 📁 Folder Structure

```
src/
├── api/              # API calls grouped by domain
│   ├── users/
│   ├── products/
│   ├── auth/
│   └── client.ts     # Axios instance & interceptors
│
├── stores/           # Pinia stores (state management)
│   ├── users.ts
│   └── auth.ts
│
├── composables/      # Reusable composition functions
│   ├── useAsync.ts
│   └── useDebounce.ts
│
├── components/       # UI Components
│   ├── ui/          # Generic UI components
│   └── layout/      # Layout components
│
├── views/           # Page components
│   ├── home/
│   ├── users/
│   └── products/
│
├── router/          # Vue Router
│
├── types/           # TypeScript types
│
├── utils/           # Helper functions
│   ├── formatters.ts
│   └── validators.ts
│
└── assets/          # Static files
    ├── images/
    └── styles/
```

## 🎯 Key Principles

1. **Simple & Flat** - No over-engineering
2. **Group by Feature** - Easy to find related code
3. **Composition API** - Modern Vue.js approach
4. **Type-Safe** - Full TypeScript support

## 📊 Data Flow

```
View Component
    ↓
Pinia Store (state management)
    ↓
API Layer (axios calls)
    ↓
Backend API
```

## 🔧 When to Use What?

### Store vs Composable
- **Store**: Shared state across app (users, auth, cart)
- **Composable**: Reusable logic (useAsync, useDebounce)

### API Organization
- Group by **domain/feature** (users, products, auth)
- Each domain has its own types and functions

## 🚀 Usage Examples

### Using Store
```typescript
import { useUsersStore } from '@/stores/users';

const store = useUsersStore();
await store.fetchAll();
```

### Using Composable
```typescript
import { useAsync } from '@/composables/useAsync';

const { data, loading, execute } = useAsync(() => api.getUsers());
await execute();
```

### API Call
```typescript
import { userApi } from '@/api/users';

const users = await userApi.getAll();
```

## 📦 Required Dependencies

```bash
npm install vue-router pinia axios
npm install -D @types/node
```

## 🎨 Component Example

```vue
<script setup lang="ts">
import { onMounted } from 'vue';
import { useUsersStore } from '@/stores/users';

const store = useUsersStore();

onMounted(() => store.fetchAll());
</script>

<template>
  <div v-if="store.loading">Loading...</div>
  <div v-else>
    <div v-for="user in store.users" :key="user.id">
      {{ user.name }}
    </div>
  </div>
</template>
```

## ✅ Best Practices

1. Keep components small and focused
2. Use TypeScript interfaces for all data
3. Handle loading and error states
4. Use async/await for API calls
5. Keep business logic in stores/composables
6. Make components reusable
7. Use composition API consistently

## 🔒 Auth Flow

1. Login → Store token in localStorage
2. Axios interceptor adds token to requests
3. Router guard checks auth before navigation
4. 401 response → Auto logout & redirect

