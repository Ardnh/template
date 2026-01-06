import client from "../client";

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
        client.post<AuthResponse>("/auth/login", credentials),

    logout: () => client.post("/auth/logout"),

    me: () => client.get("/auth/me"),
};
