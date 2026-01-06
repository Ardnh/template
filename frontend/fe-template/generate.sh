#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Generating Vue.js + TypeScript Project Structure...${NC}\n"

# Create main directories
mkdir -p src/{api,composables,models,repositories,services,stores,types,utils,views,components,router,assets}

# API Layer (similar to remote data source)
mkdir -p src/api/{client,endpoints,interceptors}

# Models Layer
mkdir -p src/models/{dto,domain}

# Mappers
mkdir -p src/mappers

# Repositories
mkdir -p src/repositories/{impl,interface}

# Services/Use Cases
mkdir -p src/services

# Stores (Pinia for state management)
mkdir -p src/stores

# Views (Pages)
mkdir -p src/views/{home,user,product,auth}

# Components
mkdir -p src/components/{common,layout,features}

# Types
mkdir -p src/types

# Utils
mkdir -p src/utils

# Router
mkdir -p src/router

# Create base files

# API Client
cat > src/api/client/axios.client.ts << 'EOF'
import axios, { AxiosInstance, AxiosRequestConfig } from 'axios';

class ApiClient {
  private client: AxiosInstance;

  constructor() {
    this.client = axios.create({
      baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000/api',
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    this.setupInterceptors();
  }

  private setupInterceptors() {
    // Request interceptor
    this.client.interceptors.request.use(
      (config) => {
        const token = localStorage.getItem('token');
        if (token) {
          config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
      },
      (error) => Promise.reject(error)
    );

    // Response interceptor
    this.client.interceptors.response.use(
      (response) => response,
      (error) => {
        // Handle errors globally
        if (error.response?.status === 401) {
          // Handle unauthorized
          localStorage.removeItem('token');
          window.location.href = '/login';
        }
        return Promise.reject(error);
      }
    );
  }

  async get<T>(url: string, config?: AxiosRequestConfig): Promise<T> {
    const response = await this.client.get<T>(url, config);
    return response.data;
  }

  async post<T>(url: string, data?: any, config?: AxiosRequestConfig): Promise<T> {
    const response = await this.client.post<T>(url, data, config);
    return response.data;
  }

  async put<T>(url: string, data?: any, config?: AxiosRequestConfig): Promise<T> {
    const response = await this.client.put<T>(url, data, config);
    return response.data;
  }

  async delete<T>(url: string, config?: AxiosRequestConfig): Promise<T> {
    const response = await this.client.delete<T>(url, config);
    return response.data;
  }
}

export const apiClient = new ApiClient();
EOF

# API Endpoints
cat > src/api/endpoints/user.api.ts << 'EOF'
import { apiClient } from '../client/axios.client';
import { UserDto } from '@/models/dto/user.dto';

export class UserApi {
  private readonly baseUrl = '/users';

  async getUsers(): Promise<UserDto[]> {
    return apiClient.get<UserDto[]>(this.baseUrl);
  }

  async getUserById(id: string): Promise<UserDto> {
    return apiClient.get<UserDto>(`${this.baseUrl}/${id}`);
  }

  async createUser(data: Partial<UserDto>): Promise<UserDto> {
    return apiClient.post<UserDto>(this.baseUrl, data);
  }

  async updateUser(id: string, data: Partial<UserDto>): Promise<UserDto> {
    return apiClient.put<UserDto>(`${this.baseUrl}/${id}`, data);
  }

  async deleteUser(id: string): Promise<void> {
    return apiClient.delete<void>(`${this.baseUrl}/${id}`);
  }
}

export const userApi = new UserApi();
EOF

# DTO Model
cat > src/models/dto/user.dto.ts << 'EOF'
export interface UserDto {
  id: string;
  first_name: string;
  last_name: string;
  email: string;
  phone: string;
  created_at: string;
  updated_at: string;
}
EOF

# Domain Model
cat > src/models/domain/user.model.ts << 'EOF'
export interface User {
  id: string;
  fullName: string;
  email: string;
  phone: string;
  createdAt: Date;
}
EOF

# Mapper
cat > src/mappers/user.mapper.ts << 'EOF'
import { UserDto } from '@/models/dto/user.dto';
import { User } from '@/models/domain/user.model';

export class UserMapper {
  static toDomain(dto: UserDto): User {
    return {
      id: dto.id,
      fullName: `${dto.first_name} ${dto.last_name}`,
      email: dto.email,
      phone: dto.phone,
      createdAt: new Date(dto.created_at),
    };
  }

  static toDomainList(dtos: UserDto[]): User[] {
    return dtos.map(this.toDomain);
  }

  static toDto(domain: User): Partial<UserDto> {
    const [firstName, ...lastNameParts] = domain.fullName.split(' ');
    return {
      first_name: firstName,
      last_name: lastNameParts.join(' '),
      email: domain.email,
      phone: domain.phone,
    };
  }
}
EOF

# Repository Interface
cat > src/repositories/interface/user.repository.ts << 'EOF'
import { User } from '@/models/domain/user.model';

export interface IUserRepository {
  getUsers(): Promise<User[]>;
  getUserById(id: string): Promise<User>;
  createUser(user: User): Promise<User>;
  updateUser(id: string, user: User): Promise<User>;
  deleteUser(id: string): Promise<void>;
}
EOF

# Repository Implementation
cat > src/repositories/impl/user.repository.impl.ts << 'EOF'
import { userApi } from '@/api/endpoints/user.api';
import { User } from '@/models/domain/user.model';
import { UserMapper } from '@/mappers/user.mapper';
import { IUserRepository } from '../interface/user.repository';

export class UserRepositoryImpl implements IUserRepository {
  async getUsers(): Promise<User[]> {
    const dtos = await userApi.getUsers();
    return UserMapper.toDomainList(dtos);
  }

  async getUserById(id: string): Promise<User> {
    const dto = await userApi.getUserById(id);
    return UserMapper.toDomain(dto);
  }

  async createUser(user: User): Promise<User> {
    const dto = UserMapper.toDto(user);
    const createdDto = await userApi.createUser(dto);
    return UserMapper.toDomain(createdDto);
  }

  async updateUser(id: string, user: User): Promise<User> {
    const dto = UserMapper.toDto(user);
    const updatedDto = await userApi.updateUser(id, dto);
    return UserMapper.toDomain(updatedDto);
  }

  async deleteUser(id: string): Promise<void> {
    await userApi.deleteUser(id);
  }
}

export const userRepository = new UserRepositoryImpl();
EOF

# Service/Use Case (Optional - untuk business logic kompleks)
cat > src/services/user.service.ts << 'EOF'
import { userRepository } from '@/repositories/impl/user.repository.impl';
import { User } from '@/models/domain/user.model';

export class UserService {
  async getUsersWithValidation(): Promise<User[]> {
    const users = await userRepository.getUsers();

    // Business logic example: filter only active users
    return users.filter(user => user.email.includes('@'));
  }

  async createUserWithValidation(user: User): Promise<User> {
    // Business logic: validate email format
    if (!this.isValidEmail(user.email)) {
      throw new Error('Invalid email format');
    }

    // Business logic: validate phone
    if (!this.isValidPhone(user.phone)) {
      throw new Error('Invalid phone format');
    }

    return userRepository.createUser(user);
  }

  private isValidEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  private isValidPhone(phone: string): boolean {
    const phoneRegex = /^\+?[\d\s-()]+$/;
    return phoneRegex.test(phone);
  }
}

export const userService = new UserService();
EOF

# Pinia Store
cat > src/stores/user.store.ts << 'EOF'
import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { userRepository } from '@/repositories/impl/user.repository.impl';
import { User } from '@/models/domain/user.model';

export const useUserStore = defineStore('user', () => {
  // State
  const users = ref<User[]>([]);
  const currentUser = ref<User | null>(null);
  const loading = ref(false);
  const error = ref<string | null>(null);

  // Getters
  const userCount = computed(() => users.value.length);
  const hasUsers = computed(() => users.value.length > 0);

  // Actions
  async function fetchUsers() {
    loading.value = true;
    error.value = null;
    try {
      users.value = await userRepository.getUsers();
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to fetch users';
      throw e;
    } finally {
      loading.value = false;
    }
  }

  async function fetchUserById(id: string) {
    loading.value = true;
    error.value = null;
    try {
      currentUser.value = await userRepository.getUserById(id);
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to fetch user';
      throw e;
    } finally {
      loading.value = false;
    }
  }

  async function createUser(user: User) {
    loading.value = true;
    error.value = null;
    try {
      const newUser = await userRepository.createUser(user);
      users.value.push(newUser);
      return newUser;
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to create user';
      throw e;
    } finally {
      loading.value = false;
    }
  }

  async function updateUser(id: string, user: User) {
    loading.value = true;
    error.value = null;
    try {
      const updatedUser = await userRepository.updateUser(id, user);
      const index = users.value.findIndex(u => u.id === id);
      if (index !== -1) {
        users.value[index] = updatedUser;
      }
      return updatedUser;
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to update user';
      throw e;
    } finally {
      loading.value = false;
    }
  }

  async function deleteUser(id: string) {
    loading.value = true;
    error.value = null;
    try {
      await userRepository.deleteUser(id);
      users.value = users.value.filter(u => u.id !== id);
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to delete user';
      throw e;
    } finally {
      loading.value = false;
    }
  }

  function clearError() {
    error.value = null;
  }

  return {
    // State
    users,
    currentUser,
    loading,
    error,
    // Getters
    userCount,
    hasUsers,
    // Actions
    fetchUsers,
    fetchUserById,
    createUser,
    updateUser,
    deleteUser,
    clearError,
  };
});
EOF

# Composable (alternative to store for simple cases)
cat > src/composables/useUser.ts << 'EOF'
import { ref } from 'vue';
import { userRepository } from '@/repositories/impl/user.repository.impl';
import { User } from '@/models/domain/user.model';

export function useUser() {
  const users = ref<User[]>([]);
  const loading = ref(false);
  const error = ref<string | null>(null);

  const fetchUsers = async () => {
    loading.value = true;
    error.value = null;
    try {
      users.value = await userRepository.getUsers();
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to fetch users';
    } finally {
      loading.value = false;
    }
  };

  return {
    users,
    loading,
    error,
    fetchUsers,
  };
}
EOF

# View Component
cat > src/views/user/UserList.vue << 'EOF'
<template>
  <div class="user-list">
    <h1>Users</h1>

    <div v-if="loading" class="loading">Loading...</div>

    <div v-if="error" class="error">{{ error }}</div>

    <div v-if="!loading && hasUsers" class="users">
      <div v-for="user in users" :key="user.id" class="user-card">
        <h3>{{ user.fullName }}</h3>
        <p>{{ user.email }}</p>
        <p>{{ user.phone }}</p>
        <button @click="handleDelete(user.id)">Delete</button>
      </div>
    </div>

    <div v-if="!loading && !hasUsers" class="empty">
      No users found
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted } from 'vue';
import { useUserStore } from '@/stores/user.store';
import { storeToRefs } from 'pinia';

const userStore = useUserStore();
const { users, loading, error, hasUsers } = storeToRefs(userStore);

onMounted(() => {
  userStore.fetchUsers();
});

const handleDelete = async (id: string) => {
  if (confirm('Are you sure?')) {
    await userStore.deleteUser(id);
  }
};
</script>

<style scoped>
.user-list {
  padding: 20px;
}

.loading, .error, .empty {
  text-align: center;
  padding: 20px;
}

.error {
  color: red;
}

.users {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 20px;
}

.user-card {
  border: 1px solid #ddd;
  padding: 15px;
  border-radius: 8px;
}
</style>
EOF

# Types
cat > src/types/index.ts << 'EOF'
export type Result<T> = {
  success: true;
  data: T;
} | {
  success: false;
  error: string;
};

export interface PaginationParams {
  page: number;
  limit: number;
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
}
EOF

# Utils
cat > src/utils/validators.ts << 'EOF'
export const validateEmail = (email: string): boolean => {
  const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return regex.test(email);
};

export const validatePhone = (phone: string): boolean => {
  const regex = /^\+?[\d\s-()]+$/;
  return regex.test(phone);
};
EOF

# Router
cat > src/router/index.ts << 'EOF'
import { createRouter, createWebHistory } from 'vue-router';
import UserList from '@/views/user/UserList.vue';

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      redirect: '/users',
    },
    {
      path: '/users',
      name: 'users',
      component: UserList,
    },
  ],
});

export default router;
EOF

# README
cat > README_STRUCTURE.md << 'EOF'
# Vue.js + TypeScript Project Structure

## Architecture Overview
```
src/
├── api/                    # API Layer (Data Source)
│   ├── client/            # Axios client configuration
│   ├── endpoints/         # API endpoints
│   └── interceptors/      # Request/Response interceptors
│
├── models/                # Data Models
│   ├── dto/              # Data Transfer Objects (API response)
│   └── domain/           # Domain models (for business logic & UI)
│
├── mappers/              # Transform DTO ↔ Domain
│
├── repositories/         # Data access abstraction
│   ├── interface/       # Repository contracts
│   └── impl/            # Repository implementations
│
├── services/            # Business Logic / Use Cases (optional)
│
├── stores/              # Pinia stores (State Management)
│
├── composables/         # Reusable composition functions
│
├── views/               # Page components
│
├── components/          # Reusable UI components
│   ├── common/         # Shared components (Button, Input, etc)
│   ├── layout/         # Layout components (Header, Sidebar, etc)
│   └── features/       # Feature-specific components
│
├── router/              # Vue Router configuration
│
├── types/               # TypeScript type definitions
│
└── utils/               # Helper functions
```

## Data Flow
```
View → Store/Composable → Repository → API → Backend
                              ↓
                          Mapper (DTO ↔ Domain)
```

## When to Use What?

### Store (Pinia) vs Composable
- **Use Store**: Global state, shared across multiple components
- **Use Composable**: Local state, reusable logic

### Service vs Direct Repository
- **Use Service**: Complex business logic, multiple repository calls
- **Skip Service**: Simple CRUD operations

## Getting Started

1. Install dependencies:
```bash
npm install axios pinia
```

2. Configure environment:
Create `.env` file:
```
VITE_API_BASE_URL=http://localhost:3000/api
```

3. Update `main.ts`:
```typescript
import { createApp } from 'vue';
import { createPinia } from 'pinia';
import App from './App.vue';
import router from './router';

const app = createApp(App);

app.use(createPinia());
app.use(router);
app.mount('#app');
```

## Example Usage
```typescript
// In a component
import { useUserStore } from '@/stores/user.store';

const userStore = useUserStore();

// Fetch users
await userStore.fetchUsers();

// Access state
console.log(userStore.users);
```
EOF

echo -e "${GREEN}✅ Structure created successfully!${NC}"
echo -e "${BLUE}📁 Created directories:${NC}"
tree -L 3 src/ -I 'node_modules'

echo -e "\n${GREEN}📝 Files created:${NC}"
find src/ -type f -name "*.ts" -o -name "*.vue" -o -name "*.md"

echo -e "\n${BLUE}🎉 Done! Read README_STRUCTURE.md for details${NC}"
