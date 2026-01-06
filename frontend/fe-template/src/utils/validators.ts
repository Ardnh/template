export const isValidEmail = (email: string): boolean => {
  const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return regex.test(email);
};

export const isRequired = (value: any): boolean => {
  return value !== null && value !== undefined && value !== '';
};

export const minLength = (value: string, min: number): boolean => {
  return value.length >= min;
};
