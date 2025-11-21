# Chatter Backend

Node.js/TypeScript backend for the Chatter real-time chat application.

## Tech Stack

- **Runtime**: Node.js 20.x
- **Language**: TypeScript
- **Framework**: Express.js
- **WebSocket**: Socket.IO
- **Database**: SQLite with Prisma ORM
- **Authentication**: JWT + Passport.js (Google OAuth)
- **Validation**: Zod

## Project Structure

```
backend/
├── src/
│   ├── config/          # Configuration files (database, passport)
│   ├── controllers/     # Route controllers
│   ├── middleware/      # Express middleware (auth, error handling)
│   ├── routes/          # API routes
│   ├── services/        # Business logic
│   ├── sockets/         # WebSocket handlers
│   ├── utils/           # Utility functions (JWT, password)
│   └── index.ts         # Entry point
├── tests/               # Test files
├── prisma/              # Database schema and migrations
├── .env.example         # Environment variables template
├── package.json
├── tsconfig.json
└── SETUP.md            # Setup instructions
```

## Getting Started

See [SETUP.md](./SETUP.md) for detailed setup instructions.

### Quick Start

1. Install dependencies:
   ```bash
   npm install
   ```

2. Create `.env` file:
   ```bash
   cp .env.example .env
   ```

3. Run development server:
   ```bash
   npm run dev
   ```

## Available Scripts

- `npm run dev` - Start development server with hot reload
- `npm run build` - Build for production
- `npm start` - Start production server
- `npm test` - Run tests
- `npm run prisma:generate` - Generate Prisma client
- `npm run prisma:migrate` - Run database migrations
- `npm run prisma:studio` - Open Prisma Studio (database GUI)

## API Endpoints

### Health Check
- `GET /health` - Server health status

### Authentication (Coming in Week 2-3)
- `POST /api/auth/register` - Register with email/password
- `POST /api/auth/login` - Login with email/password
- `GET /api/auth/google` - Initiate Google OAuth
- `GET /api/auth/google/callback` - Google OAuth callback
- `POST /api/auth/logout` - Logout
- `POST /api/auth/refresh` - Refresh access token
- `GET /api/auth/me` - Get current user

### Users (Coming in Week 3)
- `GET /api/users/:id` - Get user by ID
- `PATCH /api/users/:id` - Update user profile
- `GET /api/users/search` - Search users
- `POST /api/users/:id/avatar` - Upload avatar

### Conversations (Coming in Week 4)
- `GET /api/conversations` - Get user's conversations
- `POST /api/conversations` - Create conversation
- `GET /api/conversations/:id` - Get conversation details
- `PATCH /api/conversations/:id` - Update conversation
- `DELETE /api/conversations/:id` - Delete conversation

### Messages (Coming in Week 4)
- `GET /api/conversations/:id/messages` - Get messages (paginated)
- `POST /api/conversations/:id/messages` - Send message
- `PATCH /api/messages/:id` - Edit message
- `DELETE /api/messages/:id` - Delete message
- `POST /api/messages/:id/reactions` - Add reaction
- `DELETE /api/messages/:id/reactions/:emoji` - Remove reaction

## WebSocket Events (Coming in Week 5)

### Client → Server
- `authenticate` - Authenticate WebSocket connection
- `message:send` - Send new message
- `message:edit` - Edit message
- `message:delete` - Delete message
- `typing:start` - User started typing
- `typing:stop` - User stopped typing
- `message:read` - Mark messages as read
- `presence:update` - Update user status

### Server → Client
- `message:new` - New message received
- `message:updated` - Message edited
- `message:deleted` - Message deleted
- `typing:user` - User typing status
- `presence:changed` - User presence changed
- `conversation:updated` - Conversation metadata changed
- `error` - Error occurred

## Environment Variables

See `.env.example` for all available environment variables.

Required variables:
- `DATABASE_URL` - SQLite database path
- `JWT_SECRET` - Secret for access tokens
- `JWT_REFRESH_SECRET` - Secret for refresh tokens
- `PORT` - Server port (default: 3000)
- `NODE_ENV` - Environment (development/production)
- `FRONTEND_URL` - Frontend URL for CORS

Optional (for Google OAuth):
- `GOOGLE_CLIENT_ID` - Google OAuth client ID
- `GOOGLE_CLIENT_SECRET` - Google OAuth client secret
- `GOOGLE_CALLBACK_URL` - OAuth callback URL
- `SESSION_SECRET` - Session secret

## Development

### Running Tests
```bash
npm test
```

### Database Management
```bash
# Generate Prisma client
npm run prisma:generate

# Create migration
npm run prisma:migrate

# Open Prisma Studio
npm run prisma:studio
```

### Code Style
- Use TypeScript strict mode
- Follow ESLint rules (when configured)
- Write tests for new features

## Deployment

See main [plan.md](../plan.md) for deployment instructions to AWS EC2.

## License

ISC
