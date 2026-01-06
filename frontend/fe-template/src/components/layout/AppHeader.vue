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
