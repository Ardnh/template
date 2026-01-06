import { ref } from "vue";

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
