# Chatter - Real-time Chat Application

A modern, real-time chat application built with Node.js, TypeScript, React, and Socket.IO. Deployed on AWS with cost optimization in mind.

## Features

- 🔐 **Authentication**: Email/password and Google OAuth
- 💬 **Real-time Messaging**: Instant message delivery with WebSocket
- 👥 **Group Chats**: Create and manage group conversations
- 📎 **File Sharing**: Upload and share images and files
- 😊 **Message Reactions**: React to messages with emojis
- ✏️ **Message Editing**: Edit and delete your messages
- 👀 **Typing Indicators**: See when others are typing
- 🟢 **Presence Status**: Online/offline/away status
- 📱 **Responsive Design**: Works on desktop and mobile

## Tech Stack

### Backend
- **Runtime**: Node.js 20.x with TypeScript
- **Framework**: Express.js
- **WebSocket**: Socket.IO
- **Database**: SQLite with Prisma ORM
- **Authentication**: JWT + Passport.js (Google OAuth)
- **Validation**: Zod

### Frontend
- **Framework**: React 18+ with TypeScript
- **Build Tool**: Vite
- **State Management**: Redux Toolkit
- **UI Framework**: TailwindCSS + shadcn/ui
- **WebSocket Client**: Socket.IO Client
- **Routing**: React Router v6

### Deployment
- **Platform**: AWS EC2 (t3.micro)
- **Web Server**: Nginx
- **Process Manager**: PM2
- **SSL**: Let's Encrypt
- **Estimated Cost**: $10-15/month

## Project Structure

```
chatter/
├── backend/           # Node.js backend
│   ├── src/
│   │   ├── config/    # Configuration files
│   │   ├── controllers/
│   │   ├── middleware/
│   │   ├── models/
│   │   ├── routes/
│   │   ├── services/
│   │   ├── sockets/   # WebSocket handlers
│   │   └── utils/
│   ├── prisma/        # Database schema
│   └── tests/
├── frontend/          # React frontend
│   ├── src/
│   │   ├── components/
│   │   ├── hooks/
│   │   ├── pages/
│   │   ├── services/
│   │   ├── store/     # Redux store
│   │   └── types/
│   └── public/
├── docs/              # Documentation
├── design.md          # Architecture design
├── plan.md            # Implementation plan
└── daily-plan.md      # Daily task breakdown

```

## Getting Started

### Prerequisites
- Node.js 20.x or higher
- npm or yarn
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd chatter
   ```

2. **Backend Setup**
   ```bash
   cd backend
   npm install
   cp .env.example .env
   # Edit .env with your configuration
   npx prisma migrate dev
   npm run dev
   ```

3. **Frontend Setup**
   ```bash
   cd frontend
   npm install
   cp .env.example .env
   # Edit .env with your configuration
   npm run dev
   ```

4. **Access the Application**
   - Frontend: http://localhost:5173
   - Backend API: http://localhost:3000

## Development

### Backend Development
```bash
cd backend
npm run dev        # Start development server
npm run build      # Build for production
npm test           # Run tests
npx prisma studio  # Open database GUI
```

### Frontend Development
```bash
cd frontend
npm run dev        # Start development server
npm run build      # Build for production
npm test           # Run tests
```

## Environment Variables

### Backend (.env)
```
DATABASE_URL="file:./dev.db"
JWT_SECRET="your-secret-key"
JWT_REFRESH_SECRET="your-refresh-secret"
PORT=3000
NODE_ENV=development
GOOGLE_CLIENT_ID="your-google-client-id"
GOOGLE_CLIENT_SECRET="your-google-client-secret"
GOOGLE_CALLBACK_URL="http://localhost:3000/api/auth/google/callback"
SESSION_SECRET="your-session-secret"
FRONTEND_URL="http://localhost:5173"
```

### Frontend (.env)
```
VITE_API_URL=http://localhost:3000
```

## Deployment

See [plan.md](./plan.md) for detailed deployment instructions to AWS EC2.

## Testing

```bash
# Backend tests
cd backend
npm test

# Frontend tests
cd frontend
npm test
```

## Documentation

- [Design Document](./design.md) - Architecture and design decisions
- [Implementation Plan](./plan.md) - Detailed implementation roadmap
- [Daily Plan](./daily-plan.md) - Day-by-day task breakdown

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the ISC License.

## Acknowledgments

- Socket.IO for real-time communication
- Prisma for elegant database management
- shadcn/ui for beautiful UI components
- AWS for cost-effective hosting

## Support

For issues and questions, please open an issue on GitHub.

---

**Status**: 🚧 In Development

**Timeline**: 12 weeks (60 working days)

**Current Phase**: Week 1 - Project Setup
