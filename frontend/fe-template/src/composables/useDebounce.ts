import { ref, customRef } from "vue";

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
