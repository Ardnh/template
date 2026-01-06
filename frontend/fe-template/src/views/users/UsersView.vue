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
import { onMounted } from "vue";
import { useUsersStore } from "@/stores/users";
import Card from "@/components/ui/Card.vue";
import Button from "@/components/ui/Button.vue";

const store = useUsersStore();

onMounted(() => {
    store.fetchAll();
});

const handleDelete = async (id: string) => {
    if (confirm("Are you sure?")) {
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

.loading,
.error {
    text-align: center;
    padding: 2rem;
}

.error {
    color: #ef4444;
}
</style>
