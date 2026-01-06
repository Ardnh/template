#!/bin/bash

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 Creating Simple Vue.js + TypeScript Structure...${NC}\n"

# Main structure - SIMPLE & PRAGMATIC
mkdir -p src/{api,components,composables,router,stores,types,utils,views,assets}

# API - grouped by feature/domain
mkdir -p src/api/{users,products,auth}

# Components - by type
mkdir -p src/components/{ui,layout}

# Views - by feature
mkdir -p src/views/{home,users,products,auth}

# Assets
mkdir -p src/assets/{images,styles}

echo -e "${YELLOW}📁 Creating base files...${NC}\n"

# ==========================================
# API Layer - Simple & Clean
# ==========================================

# API Client
cat > src/api/client.ts << 'EOF'
import axios from 'axios';

const client = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:3000/api',
  timeout: 10000,
});

// Request interceptor
client.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Response interceptor
client.interceptors.response.use(
  (response) => response.data,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export default client;
EOF

# User API
cat > src/api/users/index.ts << 'EOF'
import client from '../client';

export interface User {
  id: string;
  name: string;
  email: string;
  avatar?: string;
}

export const userApi = {
  getAll: () => client.get<User[]>('/users'),

  getById: (id: string) => client.get<User>(`/users/${id}`),

  create: (data: Omit<User, 'id'>) => client.post<User>('/users', data),

  update: (id: string, data: Partial<User>) =>
    client.put<User>(`/users/${id}`, data),

  delete: (id: string) => client.delete(`/users/${id}`),
};
EOF

# Product API
cat > src/api/products/index.ts << 'EOF'
import client from '../client';

export interface Product {
  id: string;
  name: string;
  price: number;
  image?: string;
  description?: string;
}

export const productApi = {
  getAll: () => client.get<Product[]>('/products'),
  getById: (id: string) => client.get<Product>(`/products/${id}`),
  create: (data: Omit<Product, 'id'>) => client.post<Product>('/products', data),
  update: (id: string, data: Partial<Product>) =>
    client.put<Product>(`/products/${id}`, data),
  delete: (id: string) => client.delete(`/products/${id}`),
};
EOF

# Auth API
cat > src/api/auth/index.ts << 'EOF'
import client from '../client';

export interface LoginCredentials {
  email: string;
  password: string;
}

export interface AuthResponse {
  token: string;
  user: {
    id: string;
    name: string;
    email: string;
  };
}

export const authApi = {
  login: (credentials: LoginCredentials) =>
    client.post<AuthResponse>('/auth/login', credentials),

  logout: () => client.post('/auth/logout'),

  me: () => client.get('/auth/me'),
};
EOF

# ==========================================
# Stores - Pinia with Composition API
# ==========================================

cat > src/stores/users.ts << 'EOF'
import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { userApi, type User } from '@/api/users';

export const useUsersStore = defineStore('users', () => {
  // State
  const users = ref<User[]>([]);
  const loading = ref(false);
  const error = ref<string | null>(null);

  // Getters
  const total = computed(() => users.value.length);

  // Actions
  async function fetchAll() {
    loading.value = true;
    error.value = null;
    try {
      users.value = await userApi.getAll();
    } catch (e: any) {
      error.value = e.message;
      throw e;
    } finally {
      loading.value = false;
    }
  }

  async function create(userData: Omit<User, 'id'>) {
    loading.value = true;
    try {
      const newUser = await userApi.create(userData);
      users.value.push(newUser);
      return newUser;
    } catch (e: any) {
      error.value = e.message;
      throw e;
    } finally {
      loading.value = false;
    }
  }

  async function remove(id: string) {
    loading.value = true;
    try {
      await userApi.delete(id);
      users.value = users.value.filter(u => u.id !== id);
    } catch (e: any) {
      error.value = e.message;
      throw e;
    } finally {
      loading.value = false;
    }
  }

  return {
    users,
    loading,
    error,
    total,
    fetchAll,
    create,
    remove,
  };
});
EOF

cat > src/stores/auth.ts << 'EOF'
import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { authApi, type LoginCredentials } from '@/api/auth';

export const useAuthStore = defineStore('auth', () => {
  const token = ref<string | null>(localStorage.getItem('token'));
  const user = ref<any>(null);
  const loading = ref(false);

  const isAuthenticated = computed(() => !!token.value);

  async function login(credentials: LoginCredentials) {
    loading.value = true;
    try {
      const response = await authApi.login(credentials);
      token.value = response.token;
      user.value = response.user;
      localStorage.setItem('token', response.token);
    } finally {
      loading.value = false;
    }
  }

  function logout() {
    token.value = null;
    user.value = null;
    localStorage.removeItem('token');
  }

  return { token, user, loading, isAuthenticated, login, logout };
});
EOF

# ==========================================
# Composables - Reusable Logic
# ==========================================

cat > src/composables/useAsync.ts << 'EOF'
import { ref } from 'vue';

export function useAsync<T>(asyncFn: () => Promise<T>) {
  const data = ref<T | null>(null);
  const loading = ref(false);
  const error = ref<Error | null>(null);

  const execute = async () => {
    loading.value = true;
    error.value = null;
    try {
      data.value = await asyncFn();
    } catch (e: any) {
      error.value = e;
      throw e;
    } finally {
      loading.value = false;
    }
  };

  return { data, loading, error, execute };
}
EOF

cat > src/composables/useDebounce.ts << 'EOF'
import { ref, customRef } from 'vue';

export function useDebounce<T>(value: T, delay = 300) {
  let timeout: ReturnType<typeof setTimeout>;

  return customRef((track, trigger) => ({
    get() {
      track();
      return value;
    },
    set(newValue: T) {
      clearTimeout(timeout);
      timeout = setTimeout(() => {
        value = newValue;
        trigger();
      }, delay);
    },
  }));
}

export function useDebouncedRef<T>(initialValue: T, delay = 300) {
  const state = ref(initialValue);
  const debouncedState = ref(initialValue);
  let timeout: ReturnType<typeof setTimeout>;

  const setValue = (newValue: T) => {
    state.value = newValue as any;
    clearTimeout(timeout);
    timeout = setTimeout(() => {
      debouncedState.value = newValue as any;
    }, delay);
  };

  return { value: state, debouncedValue: debouncedState, setValue };
}
EOF

# ==========================================
# Components
# ==========================================

cat > src/components/ui/Button.vue << 'EOF'
<template>
  <button
    :class="['btn', `btn-${variant}`, { 'btn-loading': loading }]"
    :disabled="disabled || loading"
    @click="$emit('click', $event)"
  >
    <span v-if="loading" class="spinner"></span>
    <slot v-else />
  </button>
</template>

<script setup lang="ts">
defineProps<{
  variant?: 'primary' | 'secondary' | 'danger';
  loading?: boolean;
  disabled?: boolean;
}>();

defineEmits<{
  click: [event: MouseEvent];
}>();
</script>

<style scoped>
.btn {
  padding: 0.5rem 1rem;
  border: none;
  border-radius: 0.375rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-primary {
  background: #3b82f6;
  color: white;
}

.btn-primary:hover {
  background: #2563eb;
}

.btn-secondary {
  background: #6b7280;
  color: white;
}

.btn-danger {
  background: #ef4444;
  color: white;
}

.btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.spinner {
  display: inline-block;
  width: 1rem;
  height: 1rem;
  border: 2px solid currentColor;
  border-right-color: transparent;
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}
</style>
EOF

cat > src/components/ui/Card.vue << 'EOF'
<template>
  <div class="card">
    <div v-if="$slots.header" class="card-header">
      <slot name="header" />
    </div>
    <div class="card-body">
      <slot />
    </div>
    <div v-if="$slots.footer" class="card-footer">
      <slot name="footer" />
    </div>
  </div>
</template>

<style scoped>
.card {
  background: white;
  border-radius: 0.5rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.card-header {
  padding: 1rem;
  border-bottom: 1px solid #e5e7eb;
  font-weight: 600;
}

.card-body {
  padding: 1rem;
}

.card-footer {
  padding: 1rem;
  border-top: 1px solid #e5e7eb;
  background: #f9fafb;
}
</style>
EOF

cat > src/components/layout/AppHeader.vue << 'EOF'
<template>
  <header class="header">
    <div class="container">
      <RouterLink to="/" class="logo">My App</RouterLink>

      <nav class="nav">
        <RouterLink to="/">Home</RouterLink>
        <RouterLink to="/users">Users</RouterLink>
        <RouterLink to="/products">Products</RouterLink>
      </nav>

      <div v-if="authStore.isAuthenticated">
        <span>{{ authStore.user?.name }}</span>
        <button @click="handleLogout">Logout</button>
      </div>
      <RouterLink v-else to="/login">Login</RouterLink>
    </div>
  </header>
</template>

<script setup lang="ts">
import { useAuthStore } from '@/stores/auth';
import { useRouter } from 'vue-router';

const authStore = useAuthStore();
const router = useRouter();

const handleLogout = () => {
  authStore.logout();
  router.push('/login');
};
</script>

<style scoped>
.header {
  background: white;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  padding: 1rem 0;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 1rem;
  display: flex;
  align-items: center;
  gap: 2rem;
}

.logo {
  font-size: 1.25rem;
  font-weight: bold;
  text-decoration: none;
  color: #111;
}

.nav {
  display: flex;
  gap: 1rem;
  flex: 1;
}

.nav a {
  text-decoration: none;
  color: #6b7280;
  padding: 0.5rem;
}

.nav a.router-link-active {
  color: #3b82f6;
  font-weight: 500;
}
</style>
EOF

# ==========================================
# Views
# ==========================================

cat > src/views/users/UsersView.vue << 'EOF'
<template>
  <div class="page">
    <h1>Users</h1>

    <div v-if="store.loading" class="loading">Loading...</div>

    <div v-else-if="store.error" class="error">{{ store.error }}</div>

    <div v-else class="users-grid">
      <Card v-for="user in store.users" :key="user.id">
        <template #header>
          <h3>{{ user.name }}</h3>
        </template>
        <p>{{ user.email }}</p>
        <template #footer>
          <Button variant="danger" @click="handleDelete(user.id)">
            Delete
          </Button>
        </template>
      </Card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted } from 'vue';
import { useUsersStore } from '@/stores/users';
import Card from '@/components/ui/Card.vue';
import Button from '@/components/ui/Button.vue';

const store = useUsersStore();

onMounted(() => {
  store.fetchAll();
});

const handleDelete = async (id: string) => {
  if (confirm('Are you sure?')) {
    await store.remove(id);
  }
};
</script>

<style scoped>
.page {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem 1rem;
}

.users-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1rem;
  margin-top: 2rem;
}

.loading, .error {
  text-align: center;
  padding: 2rem;
}

.error {
  color: #ef4444;
}
</style>
EOF

# ==========================================
# Router
# ==========================================

cat > src/router/index.ts << 'EOF'
import { createRouter, createWebHistory } from 'vue-router';
import { useAuthStore } from '@/stores/auth';

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      name: 'home',
      component: () => import('@/views/home/HomeView.vue'),
    },
    {
      path: '/users',
      name: 'users',
      component: () => import('@/views/users/UsersView.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/products',
      name: 'products',
      component: () => import('@/views/products/ProductsView.vue'),
    },
    {
      path: '/login',
      name: 'login',
      component: () => import('@/views/auth/LoginView.vue'),
    },
  ],
});

// Auth guard
router.beforeEach((to, from, next) => {
  const authStore = useAuthStore();

  if (to.meta.requiresAuth && !authStore.isAuthenticated) {
    next('/login');
  } else {
    next();
  }
});

export default router;
EOF

# ==========================================
# Utils
# ==========================================

cat > src/utils/formatters.ts << 'EOF'
export const formatCurrency = (value: number): string => {
  return new Intl.NumberFormat('id-ID', {
    style: 'currency',
    currency: 'IDR',
  }).format(value);
};

export const formatDate = (date: string | Date): string => {
  return new Intl.DateTimeFormat('id-ID', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  }).format(new Date(date));
};
EOF

cat > src/utils/validators.ts << 'EOF'
export const isValidEmail = (email: string): boolean => {
  const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return regex.test(email);
};

export const isRequired = (value: any): boolean => {
  return value !== null && value !== undefined && value !== '';
};

export const minLength = (value: string, min: number): boolean => {
  return value.length >= min;
};
EOF

# ==========================================
# Types
# ==========================================

cat > src/types/common.ts << 'EOF'
export interface ApiResponse<T> {
  data: T;
  message?: string;
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
}

export interface ApiError {
  message: string;
  code?: string;
  errors?: Record<string, string[]>;
}
EOF

# ==========================================
# Env & Config
# ==========================================

cat > .env.example << 'EOF'
VITE_API_URL=http://localhost:3000/api
EOF

# ==========================================
# README
# ==========================================

cat > STRUCTURE_README.md << 'EOF'
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

EOF

echo -e "${GREEN}✅ Structure created successfully!${NC}\n"

echo -e "${BLUE}📊 Structure Summary:${NC}"
echo "├── api/          → API calls by domain"
echo "├── stores/       → State management"
echo "├── composables/  → Reusable logic"
echo "├── components/   → UI components"
echo "├── views/        → Pages"
echo "├── router/       → Navigation"
echo "├── types/        → TypeScript types"
echo "└── utils/        → Helpers"

echo -e "\n${GREEN}📖 Read STRUCTURE_README.md for details${NC}"
echo -e "${YELLOW}💡 This is a SIMPLE, PRAGMATIC structure - no over-engineering!${NC}"
