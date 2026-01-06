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
