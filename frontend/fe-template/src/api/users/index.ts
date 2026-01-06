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
