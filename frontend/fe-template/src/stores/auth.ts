import { defineStore } from "pinia";
import { ref, computed } from "vue";
import { authApi, type LoginCredentials } from "@/api/auth";

export const useAuthStore = defineStore("auth", () => {
    const token = ref<string | null>(localStorage.getItem("token"));
    const user = ref<any>(null);
    const loading = ref(false);

    const isAuthenticated = computed(() => !!token.value);

    async function login(credentials: LoginCredentials) {
        loading.value = true;
        try {
            const response = await authApi.login(credentials);
            token.value = response.token;
            user.value = response.user;
            localStorage.setItem("token", response.token);
        } finally {
            loading.value = false;
        }
    }

    function logout() {
        token.value = null;
        user.value = null;
        localStorage.removeItem("token");
    }

    return { token, user, loading, isAuthenticated, login, logout };
});
