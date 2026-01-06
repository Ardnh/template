import client from '../client';

export interface Product {
  id: string;
  name: string;
  price: number;
  image?: string;
  description?: string;
}

export const productApi = {
  getAll: () => client.get<Product[]>('/products'),
  getById: (id: string) => client.get<Product>(`/products/${id}`),
  create: (data: Omit<Product, 'id'>) => client.post<Product>('/products', data),
  update: (id: string, data: Partial<Product>) =>
    client.put<Product>(`/products/${id}`, data),
  delete: (id: string) => client.delete(`/products/${id}`),
};
