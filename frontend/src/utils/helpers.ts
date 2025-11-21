// Utility functions will be added here
// Examples: date formatting, validation, etc.

export const formatDate = (date: Date): string => {
  return new Date(date).toLocaleDateString();
};

export const formatTime = (date: Date): string => {
  return new Date(date).toLocaleTimeString();
};
