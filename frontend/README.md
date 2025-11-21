# Chatter Frontend

Real-time chat application frontend built with React, TypeScript, and Material UI.

## 🚀 Quick Start

```bash
# Install dependencies
npm install

# Start development server
npm run dev
```

Visit http://localhost:5173 to see the app.

## 📦 Tech Stack

- **React 19** - UI library with latest features
- **TypeScript** - Type-safe JavaScript
- **Vite** - Lightning-fast build tool
- **Material UI** - Modern component library
- **Redux Toolkit** - State management
- **React Router** - Client-side routing
- **Axios** - HTTP client
- **Socket.IO Client** - Real-time WebSocket communication

## 📁 Project Structure

```
src/
├── components/     # Reusable React components
│   ├── auth/      # Authentication components
│   ├── chat/      # Chat-related components
│   ├── layout/    # Layout components
│   └── common/    # Common/shared components
├── pages/          # Page-level components
├── store/          # Redux store and slices
├── services/       # API services
├── hooks/          # Custom React hooks
├── types/          # TypeScript type definitions
├── utils/          # Utility functions
├── theme/          # Material UI theme
├── App.tsx         # Main App component
└── main.tsx        # Entry point
```

## 🛠️ Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run lint` - Run ESLint

## 📝 Setup Instructions

See [SETUP.md](./SETUP.md) for detailed setup instructions.

## 🔧 Environment Variables

Create a `.env` file based on `.env.example`:

```env
VITE_API_URL=http://localhost:3000
VITE_WS_URL=http://localhost:3000
VITE_GOOGLE_CLIENT_ID=your_google_client_id
```

## 🎨 Features

- Modern, responsive UI with Material UI
- Real-time messaging with Socket.IO
- Google OAuth authentication
- Redux state management
- TypeScript for type safety
- Hot Module Replacement (HMR)

## 📚 Documentation

- [React Documentation](https://react.dev)
- [TypeScript Documentation](https://www.typescriptlang.org/docs)
- [Material UI Documentation](https://mui.com)
- [Redux Toolkit Documentation](https://redux-toolkit.js.org)
- [Vite Documentation](https://vite.dev)
