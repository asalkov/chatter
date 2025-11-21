import { configureStore } from '@reduxjs/toolkit';

// Redux store will be configured here
// Slices will be added as the app develops

export const store = configureStore({
  reducer: {
    // Add reducers here
  },
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
