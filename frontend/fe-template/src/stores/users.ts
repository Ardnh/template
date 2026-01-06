import { defineStore } from "pinia";
import { ref, computed } from "vue";
import { userApi, type User } from "@/api/users";

export const useUsersStore = defineStore("users", () => {
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

    async function create(userData: Omit<User, "id">) {
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
            users.value = users.value.filter((u) => u.id !== id);
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
