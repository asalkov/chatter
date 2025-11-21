# Chat Application Implementation Plan

## Project Overview
Building a real-time chat application with Node.js/TypeScript backend and React/TypeScript frontend, using SQLite database, deployed on AWS EC2.

**Target Cost**: $10-15/month  
**Timeline**: 8-12 weeks  
**Architecture**: Single EC2 t3.micro + SQLite + Nginx

---

## Phase 1: Project Setup & Foundation (Week 1-2)

### 1.1 Initialize Project Structure
- [ ] Create project directory structure
- [ ] Initialize Git repository
- [ ] Set up `.gitignore` (exclude node_modules, .env, SQLite db files)
- [ ] Create README.md with project description

### 1.2 Backend Setup
- [ ] Initialize Node.js project (`npm init`)
- [ ] Install TypeScript and configure `tsconfig.json`
- [ ] Install core dependencies:
  - `express` - Web framework
  - `socket.io` - WebSocket server
  - `prisma` - ORM for SQLite
  - `@prisma/client` - Prisma client
  - `jsonwebtoken` - JWT authentication
  - `bcrypt` - Password hashing
  - `passport` - Authentication middleware
  - `passport-google-oauth20` - Google OAuth strategy
  - `express-session` - Session management
  - `zod` - Validation
  - `dotenv` - Environment variables
  - `cors` - CORS middleware
  - `helmet` - Security headers
- [ ] Install dev dependencies:
  - `@types/node`, `@types/express`, `@types/jsonwebtoken`, `@types/bcrypt`
  - `tsx` or `ts-node` - TypeScript execution
  - `nodemon` - Development auto-reload
  - `jest`, `@types/jest` - Testing
  - `supertest` - API testing

### 1.3 Frontend Setup
- [ ] Initialize React project with Vite (`npm create vite@latest`)
- [ ] Configure TypeScript in Vite
- [ ] Install core dependencies:
  - `react-router-dom` - Routing
  - `socket.io-client` - WebSocket client
  - `redux toolkit` - State management
  - `axios` - HTTP client
  - `react-hook-form` - Form handling
  - `zod` - Validation
- [ ] Install UI dependencies:
  - `tailwindcss` - Styling
  - `@radix-ui/react-*` - Headless UI components
  - `lucide-react` - Icons
  - `class-variance-authority` - CSS utilities
  - `clsx`, `tailwind-merge` - Utility functions
- [ ] Set up TailwindCSS configuration
- [ ] Set up shadcn/ui components

### 1.4 Database Setup
- [ ] Initialize Prisma (`npx prisma init --datasource-provider sqlite`)
- [ ] Design database schema (see schema below)
- [ ] Create initial migration
- [ ] Generate Prisma client
- [ ] Test database connection

### 1.5 Development Environment
- [ ] Create `.env.example` file
- [ ] Set up environment variables:
  - `DATABASE_URL`
  - `JWT_SECRET`
  - `JWT_REFRESH_SECRET`
  - `PORT`
  - `NODE_ENV`
  - `GOOGLE_CLIENT_ID`
  - `GOOGLE_CLIENT_SECRET`
  - `GOOGLE_CALLBACK_URL`
  - `SESSION_SECRET`
  - `FRONTEND_URL`
- [ ] Create development scripts in `package.json`
- [ ] Set up ESLint and Prettier (optional)

**Deliverables:**
- Working development environment
- Project structure established
- Database schema defined
- All dependencies installed

---

## Phase 2: Backend Core - Authentication (Week 3)

### 2.1 Database Models
Create Prisma schema:
```prisma
model User {
  id            String          @id @default(uuid())
  username      String          @unique
  email         String          @unique
  passwordHash  String?         // Optional for OAuth users
  displayName   String
  avatarUrl     String?
  authProvider  String          @default("local") // local, google
  googleId      String?         @unique // Google OAuth ID
  status        String          @default("offline") // online, offline, away
  lastSeen      DateTime        @default(now())
  createdAt     DateTime        @default(now())
  updatedAt     DateTime        @updatedAt
  
  sentMessages  Message[]       @relation("SentMessages")
  participants  ConversationParticipant[]
  reactions     MessageReaction[]
}

model Conversation {
  id            String          @id @default(uuid())
  type          String          // direct, group
  name          String?
  avatarUrl     String?
  createdBy     String
  createdAt     DateTime        @default(now())
  updatedAt     DateTime        @updatedAt
  
  messages      Message[]
  participants  ConversationParticipant[]
}

model ConversationParticipant {
  id              String       @id @default(uuid())
  conversationId  String
  userId          String
  role            String       @default("member") // admin, member
  joinedAt        DateTime     @default(now())
  lastReadAt      DateTime     @default(now())
  
  conversation    Conversation @relation(fields: [conversationId], references: [id], onDelete: Cascade)
  user            User         @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  @@unique([conversationId, userId])
  @@index([userId])
  @@index([conversationId])
}

model Message {
  id              String       @id @default(uuid())
  conversationId  String
  senderId        String
  content         String
  type            String       @default("text") // text, image, file, system
  attachmentUrl   String?
  replyToId       String?
  editedAt        DateTime?
  deletedAt       DateTime?
  createdAt       DateTime     @default(now())
  
  conversation    Conversation @relation(fields: [conversationId], references: [id], onDelete: Cascade)
  sender          User         @relation("SentMessages", fields: [senderId], references: [id], onDelete: Cascade)
  replyTo         Message?     @relation("MessageReplies", fields: [replyToId], references: [id], onDelete: SetNull)
  replies         Message[]    @relation("MessageReplies")
  reactions       MessageReaction[]
  
  @@index([conversationId, createdAt])
  @@index([senderId])
}

model MessageReaction {
  id          String   @id @default(uuid())
  messageId   String
  userId      String
  emoji       String
  createdAt   DateTime @default(now())
  
  message     Message  @relation(fields: [messageId], references: [id], onDelete: Cascade)
  user        User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  @@unique([messageId, userId, emoji])
  @@index([messageId])
}
```

### 2.2 Google OAuth Setup
- [ ] Create Google Cloud Project:
  - Go to [Google Cloud Console](https://console.cloud.google.com/)
  - Create new project
  - Enable Google+ API
  - Create OAuth 2.0 credentials
  - Add authorized redirect URI: `http://localhost:3000/api/auth/google/callback`
  - Add production URI later: `https://your-domain.com/api/auth/google/callback`
  - Copy Client ID and Client Secret to `.env`

### 2.3 Authentication System
- [ ] Create `src/utils/jwt.ts` - JWT token generation/verification
- [ ] Create `src/utils/password.ts` - Password hashing/comparison
- [ ] Create `src/config/passport.ts` - Passport configuration:
  - Configure Google OAuth strategy
  - Serialize/deserialize user
- [ ] Create `src/middleware/auth.ts` - Authentication middleware
- [ ] Create `src/controllers/authController.ts`:
  - `register` - User registration (email/password)
  - `login` - User login (email/password)
  - `googleAuth` - Initiate Google OAuth
  - `googleCallback` - Handle Google OAuth callback
  - `logout` - User logout
  - `refreshToken` - Refresh access token
  - `getMe` - Get current user
- [ ] Create `src/routes/authRoutes.ts`:
  - `POST /api/auth/register` - Email/password registration
  - `POST /api/auth/login` - Email/password login
  - `GET /api/auth/google` - Initiate Google OAuth
  - `GET /api/auth/google/callback` - Google OAuth callback
  - `POST /api/auth/logout` - Logout
  - `POST /api/auth/refresh` - Refresh token
  - `GET /api/auth/me` - Get current user
- [ ] Implement validation schemas with Zod
- [ ] Add rate limiting for auth endpoints
- [ ] Handle OAuth user creation/login:
  - Check if user exists by Google ID
  - Create new user if doesn't exist
  - Generate JWT tokens
  - Return user data and tokens
- [ ] Test authentication endpoints

### 2.4 User Management
- [ ] Create `src/controllers/userController.ts`:
  - `getUser` - Get user by ID
  - `updateUser` - Update user profile
  - `searchUsers` - Search users by username/email
  - `uploadAvatar` - Upload user avatar
- [ ] Create `src/routes/userRoutes.ts`
- [ ] Implement file upload handling (multer)
- [ ] Store avatars in local filesystem
- [ ] Test user endpoints

**Deliverables:**
- Complete authentication system
- User registration and login working
- JWT token management
- User profile management

---

## Phase 3: Backend Core - Messaging (Week 4-5)

### 3.1 REST API for Conversations
- [ ] Create `src/controllers/conversationController.ts`:
  - `getConversations` - Get user's conversations
  - `createConversation` - Create new conversation
  - `getConversation` - Get conversation details
  - `updateConversation` - Update conversation (name, avatar)
  - `deleteConversation` - Delete conversation
  - `addParticipant` - Add user to conversation
  - `removeParticipant` - Remove user from conversation
- [ ] Create `src/routes/conversationRoutes.ts`
- [ ] Implement authorization checks
- [ ] Test conversation endpoints

### 3.2 REST API for Messages
- [ ] Create `src/controllers/messageController.ts`:
  - `getMessages` - Get messages (paginated, cursor-based)
  - `sendMessage` - Send new message (also via WebSocket)
  - `editMessage` - Edit message
  - `deleteMessage` - Soft delete message
  - `addReaction` - Add emoji reaction
  - `removeReaction` - Remove emoji reaction
- [ ] Create `src/routes/messageRoutes.ts`
- [ ] Implement pagination (cursor-based)
- [ ] Test message endpoints

### 3.3 WebSocket Server Setup
- [ ] Create `src/sockets/socketServer.ts` - Socket.IO setup
- [ ] Create `src/sockets/authMiddleware.ts` - WebSocket authentication
- [ ] Create `src/sockets/handlers/`:
  - `connectionHandler.ts` - Handle connect/disconnect
  - `messageHandler.ts` - Handle message events
  - `typingHandler.ts` - Handle typing indicators
  - `presenceHandler.ts` - Handle user presence
- [ ] Implement WebSocket events:
  - `authenticate` - Authenticate connection
  - `message:send` - Send message
  - `message:edit` - Edit message
  - `message:delete` - Delete message
  - `typing:start` - User started typing
  - `typing:stop` - User stopped typing
  - `message:read` - Mark messages as read
  - `presence:update` - Update user status
- [ ] Implement server-to-client events:
  - `message:new` - New message received
  - `message:updated` - Message edited
  - `message:deleted` - Message deleted
  - `typing:user` - User typing status
  - `presence:changed` - User presence changed
  - `error` - Error occurred
- [ ] Test WebSocket connections

### 3.4 In-Memory Caching
- [ ] Create `src/utils/cache.ts` - Simple LRU cache
- [ ] Cache active WebSocket connections
- [ ] Cache online users
- [ ] Cache recent messages (optional)

**Deliverables:**
- Complete messaging REST API
- WebSocket server with real-time messaging
- Typing indicators
- User presence tracking

---

## Phase 4: Frontend Core - Authentication (Week 6)

### 4.1 Project Structure
```
frontend/src/
├── components/
│   ├── auth/
│   │   ├── LoginForm.tsx
│   │   ├── RegisterForm.tsx
│   │   └── ProtectedRoute.tsx
│   ├── chat/
│   │   ├── ChatList.tsx
│   │   ├── ChatWindow.tsx
│   │   ├── MessageList.tsx
│   │   ├── MessageInput.tsx
│   │   ├── MessageItem.tsx
│   │   └── TypingIndicator.tsx
│   ├── common/
│   │   ├── Avatar.tsx
│   │   ├── Button.tsx
│   │   ├── Input.tsx
│   │   └── Layout.tsx
│   └── user/
│       ├── UserProfile.tsx
│       └── UserSearch.tsx
├── hooks/
│   ├── useAuth.ts
│   ├── useSocket.ts
│   ├── useMessages.ts
│   └── useConversations.ts
├── services/
│   ├── api.ts
│   ├── authService.ts
│   ├── messageService.ts
│   ├── conversationService.ts
│   └── socketService.ts
├── store/
│   ├── authStore.ts
│   ├── chatStore.ts
│   └── uiStore.ts
├── types/
│   ├── auth.types.ts
│   ├── message.types.ts
│   ├── conversation.types.ts
│   └── user.types.ts
├── utils/
│   ├── formatDate.ts
│   └── validators.ts
├── pages/
│   ├── LoginPage.tsx
│   ├── RegisterPage.tsx
│   ├── ChatPage.tsx
│   └── ProfilePage.tsx
├── App.tsx
└── main.tsx
```

### 4.2 Authentication UI
- [ ] Create TypeScript types for User, Auth
- [ ] Create `authStore.ts` with Zustand:
  - User state
  - Login/logout actions
  - Token management
- [ ] Create `authService.ts`:
  - `login()` - Email/password login
  - `register()` - Email/password registration
  - `loginWithGoogle()` - Google OAuth login
  - `logout()`
  - `refreshToken()`
  - `getCurrentUser()`
- [ ] Create `api.ts` - Axios instance with interceptors
- [ ] Implement token refresh logic
- [ ] Create `LoginForm.tsx` component:
  - Email/password inputs
  - "Sign in with Google" button
  - Link to register page
- [ ] Create `RegisterForm.tsx` component:
  - Email/password/username inputs
  - "Sign up with Google" button
  - Link to login page
- [ ] Create `GoogleAuthButton.tsx` component:
  - Styled Google button
  - Handle OAuth redirect
- [ ] Create `ProtectedRoute.tsx` component
- [ ] Create login and register pages
- [ ] Handle OAuth callback:
  - Extract tokens from URL
  - Store in auth store
  - Redirect to chat page
- [ ] Test authentication flow:
  - Email/password login
  - Email/password registration
  - Google OAuth login
  - Google OAuth registration

### 4.3 Layout & Navigation
- [ ] Create main layout component
- [ ] Create navigation/sidebar
- [ ] Implement routing with React Router
- [ ] Add loading states
- [ ] Add error handling

**Deliverables:**
- Working authentication UI
- Login and registration forms
- Protected routes
- Token management

---

## Phase 5: Frontend Core - Chat Interface (Week 7-8)

### 5.1 WebSocket Integration
- [ ] Create `socketService.ts`:
  - Connect/disconnect
  - Authenticate socket
  - Emit events
  - Listen to events
- [ ] Create `useSocket.ts` hook
- [ ] Handle reconnection logic
- [ ] Handle connection errors

### 5.2 Chat Store
- [ ] Create `chatStore.ts` with Zustand:
  - Conversations list
  - Active conversation
  - Messages by conversation
  - Online users
  - Typing users
  - Actions for CRUD operations

### 5.3 Conversation List
- [ ] Create `conversationService.ts`
- [ ] Create `ChatList.tsx` component:
  - Display conversations
  - Show last message
  - Show unread count
  - Show online status
  - Search conversations
- [ ] Implement conversation selection
- [ ] Add create conversation dialog
- [ ] Test conversation list

### 5.4 Chat Window
- [ ] Create `messageService.ts`
- [ ] Create `ChatWindow.tsx` component
- [ ] Create `MessageList.tsx`:
  - Display messages
  - Infinite scroll (load more)
  - Group by date
  - Show sender info
  - Show timestamps
- [ ] Create `MessageItem.tsx`:
  - Display message content
  - Show edit/delete options
  - Show reactions
  - Handle reply
- [ ] Create `MessageInput.tsx`:
  - Text input
  - Send button
  - File upload button
  - Emoji picker (optional)
- [ ] Create `TypingIndicator.tsx`
- [ ] Implement real-time message updates
- [ ] Implement typing indicators
- [ ] Test chat functionality

### 5.5 Message Features
- [ ] Implement message editing
- [ ] Implement message deletion
- [ ] Implement message reactions
- [ ] Implement message replies
- [ ] Implement file uploads
- [ ] Implement image previews
- [ ] Add message timestamps
- [ ] Add read receipts (optional)

### 5.6 User Features
- [ ] Create user search component
- [ ] Create user profile component
- [ ] Implement avatar upload
- [ ] Implement status updates
- [ ] Show online/offline status

**Deliverables:**
- Complete chat interface
- Real-time messaging working
- Typing indicators
- Message CRUD operations
- File sharing

---

## Phase 6: Polish & Testing (Week 9-10)

### 6.1 UI/UX Improvements
- [ ] Add loading skeletons
- [ ] Add empty states
- [ ] Add error messages
- [ ] Improve responsive design
- [ ] Add animations/transitions
- [ ] Optimize for mobile
- [ ] Add dark mode (optional)
- [ ] Improve accessibility

### 6.2 Performance Optimization
- [ ] Implement message pagination
- [ ] Optimize re-renders
- [ ] Add debouncing for search
- [ ] Lazy load images
- [ ] Code splitting
- [ ] Bundle size optimization

### 6.3 Testing
- [ ] Write backend unit tests:
  - Auth controller tests
  - Message controller tests
  - Conversation controller tests
- [ ] Write backend integration tests:
  - API endpoint tests
  - WebSocket tests
- [ ] Write frontend unit tests:
  - Component tests
  - Hook tests
  - Service tests
- [ ] Manual testing:
  - Test all user flows
  - Test error scenarios
  - Test edge cases

### 6.4 Security Hardening
- [ ] Add rate limiting
- [ ] Add input sanitization
- [ ] Add CSRF protection
- [ ] Add XSS protection
- [ ] Review authentication flow
- [ ] Add security headers (helmet)
- [ ] Validate file uploads
- [ ] Add file size limits

### 6.5 Documentation
- [ ] Update README with setup instructions
- [ ] Document API endpoints
- [ ] Document WebSocket events
- [ ] Add code comments
- [ ] Create deployment guide

**Deliverables:**
- Polished UI/UX
- Comprehensive tests
- Security hardened
- Documentation complete

---

## Phase 7: AWS Deployment (Week 11)

### 7.1 Prepare for Deployment
- [ ] Create production build scripts
- [ ] Set up environment variables for production
- [ ] Configure CORS for production domain
- [ ] Optimize SQLite for production (WAL mode)
- [ ] Set up logging (Winston or Pino)
- [ ] Set up error tracking (optional: Sentry)

### 7.2 AWS EC2 Setup
- [ ] Create AWS account (if needed)
- [ ] Launch EC2 t3.micro instance (Ubuntu 22.04)
- [ ] Assign Elastic IP
- [ ] Configure Security Groups:
  - Port 22 (SSH)
  - Port 80 (HTTP)
  - Port 443 (HTTPS)
- [ ] Connect via SSH
- [ ] Update system: `sudo apt update && sudo apt upgrade`

### 7.3 Server Configuration
- [ ] Install Node.js 20.x:
  ```bash
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt install -y nodejs
  ```
- [ ] Install Nginx:
  ```bash
  sudo apt install nginx
  ```
- [ ] Install PM2:
  ```bash
  sudo npm install -g pm2
  ```
- [ ] Install Git:
  ```bash
  sudo apt install git
  ```
- [ ] Create application directory:
  ```bash
  sudo mkdir -p /var/www/chatter
  sudo chown $USER:$USER /var/www/chatter
  ```

### 7.4 Deploy Backend
- [ ] Clone repository to `/var/www/chatter/backend`
- [ ] Install dependencies: `npm install`
- [ ] Create `.env` file with production values
- [ ] Build TypeScript: `npm run build`
- [ ] Run Prisma migrations: `npx prisma migrate deploy`
- [ ] Generate Prisma client: `npx prisma generate`
- [ ] Create PM2 ecosystem file:
  ```javascript
  module.exports = {
    apps: [{
      name: 'chatter-backend',
      script: './dist/index.js',
      instances: 1,
      exec_mode: 'cluster',
      env: {
        NODE_ENV: 'production',
        PORT: 3000
      }
    }]
  };
  ```
- [ ] Start with PM2: `pm2 start ecosystem.config.js`
- [ ] Set PM2 to start on boot: `pm2 startup && pm2 save`
- [ ] Test backend: `curl http://localhost:3000/health`

### 7.5 Deploy Frontend
- [ ] Build frontend locally: `npm run build`
- [ ] Upload build files to `/var/www/chatter/frontend/dist`
- [ ] Or clone and build on server

### 7.6 Configure Nginx
- [ ] Create Nginx config: `/etc/nginx/sites-available/chatter`
  ```nginx
  server {
      listen 80;
      server_name your-domain.com;  # or use IP temporarily
      
      # Frontend
      location / {
          root /var/www/chatter/frontend/dist;
          try_files $uri $uri/ /index.html;
          
          # Enable gzip compression
          gzip on;
          gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
      }
      
      # Backend API
      location /api {
          proxy_pass http://localhost:3000;
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection 'upgrade';
          proxy_set_header Host $host;
          proxy_cache_bypass $http_upgrade;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      }
      
      # WebSocket
      location /socket.io {
          proxy_pass http://localhost:3000;
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "upgrade";
          proxy_set_header Host $host;
          proxy_cache_bypass $http_upgrade;
      }
  }
  ```
- [ ] Enable site: `sudo ln -s /etc/nginx/sites-available/chatter /etc/nginx/sites-enabled/`
- [ ] Test config: `sudo nginx -t`
- [ ] Restart Nginx: `sudo systemctl restart nginx`
- [ ] Test application via IP

### 7.7 SSL Setup (Let's Encrypt)
- [ ] Install Certbot:
  ```bash
  sudo apt install certbot python3-certbot-nginx
  ```
- [ ] Get SSL certificate:
  ```bash
  sudo certbot --nginx -d your-domain.com
  ```
- [ ] Test auto-renewal: `sudo certbot renew --dry-run`
- [ ] Verify HTTPS works

### 7.8 Domain Setup (Optional)
- [ ] Register domain (Namecheap, Google Domains, etc.)
- [ ] Point A record to Elastic IP
- [ ] Wait for DNS propagation
- [ ] Update Nginx config with domain
- [ ] Get SSL certificate for domain

**Deliverables:**
- Application deployed on AWS
- HTTPS enabled
- Application accessible via domain/IP

---

## Phase 8: Monitoring & Maintenance (Week 12)

### 8.1 Backup Strategy
- [ ] Create backup script for SQLite database:
  ```bash
  #!/bin/bash
  DATE=$(date +%Y%m%d_%H%M%S)
  sqlite3 /var/www/chatter/backend/prisma/dev.db ".backup /var/www/chatter/backups/db_$DATE.db"
  # Keep only last 7 days
  find /var/www/chatter/backups -name "db_*.db" -mtime +7 -delete
  ```
- [ ] Set up cron job for daily backups:
  ```bash
  0 2 * * * /var/www/chatter/scripts/backup.sh
  ```
- [ ] Create EBS snapshot schedule (AWS Console)
- [ ] Test backup restoration

### 8.2 Monitoring Setup
- [ ] Set up CloudWatch basic monitoring
- [ ] Create CloudWatch alarms:
  - CPU utilization > 80%
  - Disk space < 20%
  - Status check failed
- [ ] Set up log rotation:
  ```bash
  sudo nano /etc/logrotate.d/chatter
  ```
- [ ] Monitor PM2 logs: `pm2 logs`
- [ ] Set up uptime monitoring (optional: UptimeRobot)

### 8.3 Cost Monitoring
- [ ] Set up AWS billing alerts ($10, $20, $50)
- [ ] Review AWS Cost Explorer monthly
- [ ] Monitor data transfer usage

### 8.4 Performance Monitoring
- [ ] Add application metrics
- [ ] Monitor WebSocket connections
- [ ] Monitor database size
- [ ] Monitor response times

### 8.5 Deployment Automation
- [ ] Create deployment script:
  ```bash
  #!/bin/bash
  cd /var/www/chatter/backend
  git pull origin main
  npm install
  npm run build
  npx prisma migrate deploy
  pm2 restart chatter-backend
  
  cd /var/www/chatter/frontend
  git pull origin main
  npm install
  npm run build
  sudo systemctl reload nginx
  ```
- [ ] Set up GitHub Actions (optional):
  - Run tests on push
  - Deploy on merge to main

**Deliverables:**
- Automated backups
- Monitoring and alerts
- Deployment automation
- Production-ready application

---

## Google OAuth Implementation Details

### Backend Implementation Example

#### 1. Passport Configuration (`src/config/passport.ts`)
```typescript
import passport from 'passport';
import { Strategy as GoogleStrategy } from 'passport-google-oauth20';
import { prisma } from './database';

passport.use(
  new GoogleStrategy(
    {
      clientID: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
      callbackURL: process.env.GOOGLE_CALLBACK_URL!,
    },
    async (accessToken, refreshToken, profile, done) => {
      try {
        // Check if user exists
        let user = await prisma.user.findUnique({
          where: { googleId: profile.id },
        });

        if (!user) {
          // Check if email already exists (linked to local account)
          const existingUser = await prisma.user.findUnique({
            where: { email: profile.emails?.[0].value },
          });

          if (existingUser) {
            // Link Google account to existing user
            user = await prisma.user.update({
              where: { id: existingUser.id },
              data: {
                googleId: profile.id,
                authProvider: 'google',
                avatarUrl: profile.photos?.[0].value,
              },
            });
          } else {
            // Create new user
            user = await prisma.user.create({
              data: {
                googleId: profile.id,
                email: profile.emails?.[0].value!,
                username: profile.emails?.[0].value!.split('@')[0] + '_' + Date.now(),
                displayName: profile.displayName,
                avatarUrl: profile.photos?.[0].value,
                authProvider: 'google',
              },
            });
          }
        }

        return done(null, user);
      } catch (error) {
        return done(error as Error);
      }
    }
  )
);

passport.serializeUser((user: any, done) => {
  done(null, user.id);
});

passport.deserializeUser(async (id: string, done) => {
  try {
    const user = await prisma.user.findUnique({ where: { id } });
    done(null, user);
  } catch (error) {
    done(error);
  }
});
```

#### 2. Auth Controller (`src/controllers/authController.ts`)
```typescript
import { Request, Response } from 'express';
import { generateTokens } from '../utils/jwt';

export const googleCallback = async (req: Request, res: Response) => {
  try {
    const user = req.user as any;
    
    // Generate JWT tokens
    const { accessToken, refreshToken } = generateTokens(user.id);
    
    // Redirect to frontend with tokens
    const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:5173';
    res.redirect(
      `${frontendUrl}/auth/callback?token=${accessToken}&refreshToken=${refreshToken}`
    );
  } catch (error) {
    res.redirect(`${process.env.FRONTEND_URL}/login?error=auth_failed`);
  }
};
```

#### 3. Auth Routes (`src/routes/authRoutes.ts`)
```typescript
import express from 'express';
import passport from 'passport';
import { googleCallback } from '../controllers/authController';

const router = express.Router();

// Initiate Google OAuth
router.get(
  '/google',
  passport.authenticate('google', {
    scope: ['profile', 'email'],
  })
);

// Google OAuth callback
router.get(
  '/google/callback',
  passport.authenticate('google', {
    session: false,
    failureRedirect: '/login',
  }),
  googleCallback
);

export default router;
```

### Frontend Implementation Example

#### 1. Auth Service (`src/services/authService.ts`)
```typescript
const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000';

export const authService = {
  loginWithGoogle: () => {
    // Redirect to backend Google OAuth endpoint
    window.location.href = `${API_URL}/api/auth/google`;
  },
  
  handleOAuthCallback: (token: string, refreshToken: string) => {
    // Store tokens
    localStorage.setItem('accessToken', token);
    localStorage.setItem('refreshToken', refreshToken);
  },
};
```

#### 2. Google Auth Button (`src/components/auth/GoogleAuthButton.tsx`)
```typescript
import { Button } from '@/components/ui/button';
import { authService } from '@/services/authService';

export const GoogleAuthButton = () => {
  const handleGoogleLogin = () => {
    authService.loginWithGoogle();
  };

  return (
    <Button
      onClick={handleGoogleLogin}
      variant="outline"
      className="w-full"
    >
      <svg className="w-5 h-5 mr-2" viewBox="0 0 24 24">
        {/* Google icon SVG */}
      </svg>
      Continue with Google
    </Button>
  );
};
```

#### 3. OAuth Callback Page (`src/pages/OAuthCallbackPage.tsx`)
```typescript
import { useEffect } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { useAuthStore } from '@/store/authStore';
import { authService } from '@/services/authService';

export const OAuthCallbackPage = () => {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const { setTokens, fetchCurrentUser } = useAuthStore();

  useEffect(() => {
    const token = searchParams.get('token');
    const refreshToken = searchParams.get('refreshToken');
    const error = searchParams.get('error');

    if (error) {
      navigate('/login?error=' + error);
      return;
    }

    if (token && refreshToken) {
      authService.handleOAuthCallback(token, refreshToken);
      setTokens(token, refreshToken);
      fetchCurrentUser().then(() => {
        navigate('/chat');
      });
    } else {
      navigate('/login');
    }
  }, [searchParams, navigate, setTokens, fetchCurrentUser]);

  return (
    <div className="flex items-center justify-center min-h-screen">
      <div className="text-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-gray-900 mx-auto"></div>
        <p className="mt-4 text-gray-600">Completing sign in...</p>
      </div>
    </div>
  );
};
```

#### 4. Update Router (`src/App.tsx`)
```typescript
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { OAuthCallbackPage } from './pages/OAuthCallbackPage';

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/register" element={<RegisterPage />} />
        <Route path="/auth/callback" element={<OAuthCallbackPage />} />
        <Route path="/chat" element={<ProtectedRoute><ChatPage /></ProtectedRoute>} />
      </Routes>
    </BrowserRouter>
  );
}
```

### Production Deployment Notes

#### Update Google OAuth Credentials
1. Go to Google Cloud Console
2. Add production redirect URI:
   - `https://your-domain.com/api/auth/google/callback`
3. Update environment variables on EC2:
   ```bash
   GOOGLE_CALLBACK_URL=https://your-domain.com/api/auth/google/callback
   FRONTEND_URL=https://your-domain.com
   ```

#### Security Considerations
- Use HTTPS in production (required by Google OAuth)
- Set secure session cookies
- Validate redirect URLs
- Implement CSRF protection
- Rate limit OAuth endpoints

---

## Success Criteria

### Functional Requirements
- ✅ Users can register and login with email/password
- ✅ Users can login with Google OAuth
- ✅ Users can send/receive messages in real-time
- ✅ Users can create direct and group conversations
- ✅ Users can see typing indicators
- ✅ Users can see online/offline status
- ✅ Users can edit and delete messages
- ✅ Users can react to messages
- ✅ Users can upload files and images
- ✅ Messages are persisted in database
- ✅ Application is accessible via HTTPS

### Non-Functional Requirements
- ✅ Response time < 200ms for API calls
- ✅ WebSocket latency < 100ms
- ✅ Application handles 100+ concurrent users
- ✅ 99% uptime
- ✅ Monthly cost < $15
- ✅ Mobile responsive design
- ✅ Secure authentication
- ✅ Data backed up daily

---

## Risk Management

### Technical Risks
| Risk | Impact | Mitigation |
|------|--------|------------|
| SQLite performance issues | High | Monitor query performance, add indexes, upgrade to PostgreSQL if needed |
| WebSocket connection drops | Medium | Implement reconnection logic, show connection status |
| Single point of failure | High | Regular backups, quick recovery plan |
| Security vulnerabilities | High | Regular security audits, keep dependencies updated |
| Disk space exhaustion | Medium | Monitor disk usage, implement log rotation, archive old messages |

### Operational Risks
| Risk | Impact | Mitigation |
|------|--------|------------|
| AWS cost overrun | Medium | Set billing alerts, monitor usage |
| Deployment failures | Medium | Test deployments, have rollback plan |
| Data loss | High | Automated backups, test restoration |

---

## Future Enhancements (Post-MVP)

### Phase 9: Advanced Features
- [ ] Voice messages
- [ ] Video calls (WebRTC)
- [ ] Message search
- [ ] Push notifications
- [ ] Message threads
- [ ] User blocking
- [ ] Message pinning
- [ ] Custom emojis
- [ ] File preview
- [ ] Link previews
- [ ] Markdown support
- [ ] Code syntax highlighting

### Phase 10: Scaling
- [ ] Migrate to PostgreSQL (RDS)
- [ ] Add Redis for caching
- [ ] Add load balancer
- [ ] Deploy multiple EC2 instances
- [ ] Add CDN for static assets
- [ ] Implement horizontal scaling

---

## Resources & References

### Documentation
- [Node.js Docs](https://nodejs.org/docs/)
- [Express.js Guide](https://expressjs.com/)
- [Socket.IO Docs](https://socket.io/docs/)
- [Prisma Docs](https://www.prisma.io/docs)
- [React Docs](https://react.dev/)
- [Vite Guide](https://vitejs.dev/guide/)
- [TailwindCSS Docs](https://tailwindcss.com/docs)

### Tools
- [Postman](https://www.postman.com/) - API testing
- [Insomnia](https://insomnia.rest/) - API testing
- [Prisma Studio](https://www.prisma.io/studio) - Database GUI
- [PM2 Docs](https://pm2.keymetrics.io/docs/)

### AWS Resources
- [EC2 Getting Started](https://docs.aws.amazon.com/ec2/)
- [AWS Free Tier](https://aws.amazon.com/free/)
- [Let's Encrypt](https://letsencrypt.org/)

---

## Notes

- Keep commits small and focused
- Write tests as you go
- Document complex logic
- Review security best practices regularly
- Monitor costs weekly
- Back up before major changes
- Test on mobile devices regularly
