# Chat Application Design Document

## Overview
A real-time chat application built with Node.js/TypeScript backend and React/TypeScript frontend, designed for **cost-optimized** AWS deployment.

**Cost Focus**: This design prioritizes minimal AWS costs while maintaining core functionality. Estimated monthly cost: **$5-15** (single t3.micro/t4g.micro EC2 instance).

## Architecture

### High-Level Architecture (Cost-Optimized)
```
┌─────────────┐
│   Client    │
│  (React)    │
└──────┬──────┘
       │
       │ HTTPS/WSS
       │
┌──────▼──────────────────────────────────────┐
│         AWS Cloud                            │
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │  Single EC2 Instance (t3.micro)        │ │
│  │  ┌──────────────────────────────────┐ │ │
│  │  │  Nginx (Reverse Proxy)           │ │ │
│  │  │  - Serves React static files     │ │ │
│  │  │  - Proxies API to Node.js        │ │ │
│  │  │  - SSL termination (Let's Encrypt)│ │ │
│  │  └──────────────────────────────────┘ │ │
│  │  ┌──────────────────────────────────┐ │ │
│  │  │  Node.js + Express + Socket.IO   │ │ │
│  │  │  - REST API                      │ │ │
│  │  │  - WebSocket server              │ │ │
│  │  └──────────────────────────────────┘ │ │
│  │  ┌──────────────────────────────────┐ │ │
│  │  │  SQLite Database                 │ │ │
│  │  │  - User data                     │ │ │
│  │  │  - Messages                      │ │ │
│  │  │  - Conversations                 │ │ │
│  │  └──────────────────────────────────┘ │ │
│  │  ┌──────────────────────────────────┐ │ │
│  │  │  Local File Storage              │ │ │
│  │  │  - Uploaded files/images         │ │ │
│  │  │  - User avatars                  │ │ │
│  │  └──────────────────────────────────┘ │ │
│  └────────────────────────────────────────┘ │
│                                              │
│  Optional (if needed):                       │
│  ┌────────────────────────────────────────┐ │
│  │  S3 Bucket (pay-as-you-go)            │ │
│  │  - Backup storage                     │ │
│  │  - Large file offloading             │ │
│  └────────────────────────────────────────┘ │
└──────────────────────────────────────────────┘
```

### Cost Breakdown (Monthly Estimates)
- **EC2 t3.micro** (1 vCPU, 1GB RAM): ~$7.50/month
- **EBS Volume** (20GB gp3): ~$1.60/month
- **Elastic IP**: Free (when attached)
- **Data Transfer**: ~$1-5/month (first 100GB free)
- **Total**: **~$10-15/month**

### Alternative: Lambda-Based Architecture

**⚠️ Lambda is NOT recommended for chat applications** due to WebSocket limitations, but here's the cost breakdown:

#### Lambda Architecture Components
```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │
┌──────▼──────────────────────────────────────┐
│  CloudFront + S3 (Frontend)  ~$1-3/month    │
└──────┬──────────────────────────────────────┘
       │
┌──────▼──────────────────────────────────────┐
│  API Gateway (WebSocket)     ~$3.50/1M msgs │
└──────┬──────────────────────────────────────┘
       │
┌──────▼──────────────────────────────────────┐
│  Lambda Functions            ~$0.20/1M reqs │
└──────┬──────────────────────────────────────┘
       │
┌──────▼──────────────────────────────────────┐
│  DynamoDB (Database)         ~$1-5/month    │
│  or Aurora Serverless        ~$40+/month    │
└──────────────────────────────────────────────┘
```

#### Lambda Cost Estimate (Low Traffic: 10,000 messages/day)

**Monthly Costs:**
- **API Gateway (WebSocket)**: 
  - 300K messages/month × $1.00/million = **$0.30**
  - Connection minutes: 1000 users × 30 min/day × 30 days = 900K mins × $0.25/million = **$0.23**
- **Lambda**:
  - 300K invocations × $0.20/million = **$0.06**
  - Compute: 300K × 200ms × 512MB = 30K GB-seconds × $0.0000166667 = **$0.50**
- **DynamoDB**:
  - On-demand: 300K writes × $1.25/million = **$0.38**
  - 1M reads × $0.25/million = **$0.25**
  - Storage: 1GB × $0.25 = **$0.25**
- **S3 + CloudFront**:
  - S3 storage: 1GB × $0.023 = **$0.02**
  - CloudFront: 10GB transfer × $0.085 = **$0.85**
- **Data Transfer**: ~**$1-2**

**Total: ~$4-6/month** (very low traffic)

#### Lambda Cost Estimate (Medium Traffic: 100,000 messages/day)

**Monthly Costs:**
- **API Gateway**: 3M messages × $1.00/million = **$3.00** + connection time **$2.30** = **$5.30**
- **Lambda**: 3M invocations + compute = **$5.50**
- **DynamoDB**: 3M writes + 10M reads = **$6.25**
- **S3 + CloudFront**: **$3-5**
- **Data Transfer**: **$5-10**

**Total: ~$25-35/month** (medium traffic)

#### Lambda Cost Estimate (High Traffic: 1M messages/day)

**Monthly Costs:**
- **API Gateway**: 30M messages = **$30** + connection time **$23** = **$53**
- **Lambda**: 30M invocations + compute = **$55**
- **DynamoDB**: 30M writes + 100M reads = **$62**
- **S3 + CloudFront**: **$10-20**
- **Data Transfer**: **$20-50**

**Total: ~$200-240/month** (high traffic)

#### Why Lambda is NOT Ideal for Chat Apps

**Disadvantages:**
1. **WebSocket complexity**: API Gateway WebSocket is complex and expensive
2. **Cold starts**: 100-500ms latency for inactive connections
3. **Connection limits**: API Gateway has 10K concurrent connection limit per account
4. **State management**: Need DynamoDB/Redis for connection tracking
5. **Cost at scale**: Becomes expensive with constant WebSocket traffic
6. **Debugging**: Harder to debug distributed Lambda functions

**When Lambda Makes Sense:**
- **Very low traffic**: <5,000 messages/day (cheaper than EC2)
- **Sporadic usage**: App used only few hours per day
- **No real-time requirements**: REST API only, no WebSockets
- **Serverless preference**: Team expertise in serverless

#### Cost Comparison Summary

| Traffic Level | EC2 (t3.micro) | Lambda + API Gateway |
|--------------|----------------|---------------------|
| **Very Low** (1K msgs/day) | $10-15/month | $3-5/month ✅ |
| **Low** (10K msgs/day) | $10-15/month ✅ | $4-6/month |
| **Medium** (100K msgs/day) | $10-15/month ✅ | $25-35/month |
| **High** (1M msgs/day) | $15-30/month* ✅ | $200-240/month |

*Requires t3.small upgrade

**Recommendation: Use EC2 for chat applications** unless traffic is extremely sporadic (<1 hour/day usage).

### Alternative: EC2 + DynamoDB

**Yes, you can use EC2 + DynamoDB!** This is a good middle-ground option.

#### EC2 + DynamoDB Architecture
```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │
┌──────▼──────────────────────────────────────┐
│  EC2 t3.micro (Node.js + Nginx)             │
│  - WebSocket server                          │
│  - REST API                                  │
│  - Static file serving                       │
└──────┬──────────────────────────────────────┘
       │
┌──────▼──────────────────────────────────────┐
│  DynamoDB (Managed NoSQL)                    │
│  - Users table                               │
│  - Messages table                            │
│  - Conversations table                       │
└──────────────────────────────────────────────┘
```

#### Cost Breakdown (EC2 + DynamoDB)

**Monthly Costs:**
- **EC2 t3.micro**: ~$7.50/month
- **EBS Volume (20GB)**: ~$1.60/month
- **DynamoDB On-Demand**:
  - **Very Low Traffic** (10K msgs/day):
    - 300K writes × $1.25/million = $0.38
    - 1M reads × $0.25/million = $0.25
    - Storage: 1GB × $0.25 = $0.25
    - **Total DynamoDB**: ~$1/month
  - **Low Traffic** (50K msgs/day):
    - 1.5M writes = $1.88
    - 5M reads = $1.25
    - Storage: 5GB = $1.25
    - **Total DynamoDB**: ~$4-5/month
  - **Medium Traffic** (100K msgs/day):
    - 3M writes = $3.75
    - 10M reads = $2.50
    - Storage: 10GB = $2.50
    - **Total DynamoDB**: ~$9-10/month
- **Data Transfer**: ~$1-5/month

**Total Costs:**
- **Very Low Traffic**: **$11-13/month** (similar to SQLite)
- **Low Traffic**: **$14-18/month**
- **Medium Traffic**: **$19-25/month**

#### Advantages of DynamoDB over SQLite

**Pros:**
1. **Managed service**: No database maintenance, automatic backups
2. **Scalability**: Seamlessly handles growth without migration
3. **Multi-instance ready**: Easy to scale to multiple EC2 instances
4. **High availability**: Built-in replication across availability zones
5. **No backup complexity**: Point-in-time recovery included
6. **Global tables**: Can expand to multiple regions easily
7. **Streams**: Built-in change data capture for real-time features

**Cons:**
1. **Slightly more expensive**: $1-10/month more than SQLite
2. **NoSQL limitations**: Requires different data modeling approach
3. **Query complexity**: Less flexible than SQL for complex queries
4. **Learning curve**: Need to understand DynamoDB patterns

#### Advantages of SQLite over DynamoDB

**Pros:**
1. **Cheaper**: $0 database cost vs $1-10/month
2. **Simpler**: No network latency, easier to debug
3. **SQL queries**: Full SQL support for complex queries
4. **No AWS lock-in**: Portable to any hosting provider
5. **Better for development**: Easier local testing

**Cons:**
1. **Single instance only**: Hard to scale horizontally
2. **Manual backups**: Need to set up EBS snapshots
3. **File locking**: Can be bottleneck under high concurrency
4. **Migration needed**: Must migrate to PostgreSQL/MySQL for scaling

#### Database Comparison Table

| Feature | SQLite | DynamoDB | PostgreSQL (RDS) |
|---------|--------|----------|------------------|
| **Cost/month** | $0 | $1-10 | $15-30 |
| **Scalability** | Single instance | Unlimited | High (with replicas) |
| **Maintenance** | Manual backups | Fully managed | Managed |
| **Multi-instance** | ❌ No | ✅ Yes | ✅ Yes |
| **Query flexibility** | ✅ Full SQL | ⚠️ Limited | ✅ Full SQL |
| **Latency** | <1ms | 1-5ms | 2-10ms |
| **Setup complexity** | ✅ Simple | ⚠️ Moderate | ⚠️ Moderate |
| **Best for** | MVP, low traffic | Growing apps | Complex queries |

#### Recommendation by Use Case

**Use SQLite if:**
- Building MVP or prototype
- Very low traffic (<10K messages/day)
- Want simplest possible setup
- Budget is extremely tight
- Single instance is sufficient

**Use DynamoDB if:**
- Plan to scale beyond single instance
- Want managed database from day 1
- Need high availability
- Comfortable with NoSQL
- Can afford extra $1-10/month

**Use PostgreSQL (RDS) if:**
- Need complex SQL queries
- Require ACID transactions
- Have budget for $15-30/month
- Want traditional relational database
- Need advanced features (full-text search, JSON queries)

#### DynamoDB Data Model for Chat App

```typescript
// Users Table
{
  PK: "USER#<userId>",
  SK: "PROFILE",
  username: string,
  email: string,
  displayName: string,
  avatarUrl: string,
  createdAt: timestamp
}

// Messages Table (with GSI for conversation queries)
{
  PK: "CONV#<conversationId>",
  SK: "MSG#<timestamp>#<messageId>",
  senderId: string,
  content: string,
  type: string,
  createdAt: timestamp,
  // GSI for user's messages
  GSI1PK: "USER#<senderId>",
  GSI1SK: "MSG#<timestamp>"
}

// Conversations Table
{
  PK: "CONV#<conversationId>",
  SK: "META",
  type: "direct" | "group",
  name: string,
  participants: string[],
  createdAt: timestamp
}

// User-Conversation Mapping
{
  PK: "USER#<userId>",
  SK: "CONV#<conversationId>",
  lastReadAt: timestamp,
  role: "admin" | "member"
}
```

### Upgrade Path (When Scaling Needed)
When you outgrow a single instance:
1. **Phase 1**: Upgrade to t3.small/medium (~$15-30/month)
2. **Phase 2**: Add S3 for file storage (~$1-5/month)
3. **Phase 3**: If using SQLite, migrate to DynamoDB or RDS
4. **Phase 4**: Add Redis (ElastiCache t4g.micro ~$12/month) for caching
5. **Phase 5**: Add load balancer and multiple EC2 instances

## Technology Stack

### Backend (Node.js + TypeScript)
- **Runtime**: Node.js 20.x LTS
- **Framework**: Express.js
- **WebSocket**: Socket.IO or ws library
- **Database ORM**: Prisma (with SQLite connector) or better-sqlite3
- **Authentication**: JWT (JSON Web Tokens)
- **Validation**: Zod or Joi
- **Testing**: Jest, Supertest
- **API Documentation**: Swagger/OpenAPI

### Frontend (React + TypeScript)
- **Framework**: React 18+
- **Build Tool**: Vite
- **State Management**: Redux Toolkit
- **WebSocket Client**: Socket.IO Client
- **UI Framework**: TailwindCSS + shadcn/ui
- **Icons**: Lucide React
- **HTTP Client**: Axios or Fetch API
- **Form Handling**: React Hook Form
- **Routing**: React Router v6
- **Testing**: Vitest, React Testing Library

### AWS Services (Cost-Optimized)
- **Compute**: Single EC2 t3.micro or t4g.micro instance
- **Database**: SQLite (file-based, no additional cost)
- **Storage**: EBS volume (included with EC2)
- **SSL/TLS**: Let's Encrypt (free)
- **Monitoring**: CloudWatch basic metrics (free tier)
- **DNS**: Route 53 (optional, ~$0.50/month) or use free DNS provider
- **Backup**: EBS snapshots (pay-as-you-go, ~$0.05/GB/month)

### Services NOT Used (To Save Costs)
- ❌ RDS ($15-100+/month)
- ❌ ElastiCache ($12-50+/month)
- ❌ Application Load Balancer ($16+/month)
- ❌ CloudFront ($0.085/GB, adds up quickly)
- ❌ API Gateway ($3.50/million requests)
- ❌ ECS/Fargate (more expensive than EC2)
- ❌ NAT Gateway ($32+/month)
- ❌ Secrets Manager ($0.40/secret/month)

## Core Features

### 1. User Management
- User registration and authentication
- Profile management (avatar, status, bio)
- Online/offline status
- Last seen timestamp

### 2. Real-time Messaging
- One-on-one chat
- Group chat/channels
- Message delivery status (sent, delivered, read)
- Typing indicators
- Message reactions/emojis
- Message editing and deletion
- Reply/thread support

### 3. Media Sharing
- Image uploads
- File attachments
- Voice messages (optional)
- Link previews

### 4. Notifications
- Push notifications (web push API)
- Unread message counters
- Desktop notifications

### 5. Search
- Message search
- User search
- Channel search

## Database Schema

### Users Table
```typescript
interface User {
  id: string;
  username: string;
  email: string;
  passwordHash: string;
  displayName: string;
  avatarUrl?: string;
  status: 'online' | 'offline' | 'away';
  lastSeen: Date;
  createdAt: Date;
  updatedAt: Date;
}
```

### Conversations Table
```typescript
interface Conversation {
  id: string;
  type: 'direct' | 'group';
  name?: string; // for group chats
  avatarUrl?: string;
  createdBy: string;
  createdAt: Date;
  updatedAt: Date;
}
```

### ConversationParticipants Table
```typescript
interface ConversationParticipant {
  id: string;
  conversationId: string;
  userId: string;
  role: 'admin' | 'member';
  joinedAt: Date;
  lastReadAt: Date;
}
```

### Messages Table
```typescript
interface Message {
  id: string;
  conversationId: string;
  senderId: string;
  content: string;
  type: 'text' | 'image' | 'file' | 'system';
  attachmentUrl?: string;
  replyToId?: string;
  editedAt?: Date;
  deletedAt?: Date;
  createdAt: Date;
}
```

### MessageReactions Table
```typescript
interface MessageReaction {
  id: string;
  messageId: string;
  userId: string;
  emoji: string;
  createdAt: Date;
}
```

## API Design

### REST API Endpoints

#### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `POST /api/auth/logout` - Logout user
- `POST /api/auth/refresh` - Refresh access token
- `GET /api/auth/me` - Get current user

#### Users
- `GET /api/users` - Search users
- `GET /api/users/:id` - Get user profile
- `PATCH /api/users/:id` - Update user profile
- `POST /api/users/:id/avatar` - Upload avatar

#### Conversations
- `GET /api/conversations` - Get user's conversations
- `POST /api/conversations` - Create new conversation
- `GET /api/conversations/:id` - Get conversation details
- `PATCH /api/conversations/:id` - Update conversation
- `DELETE /api/conversations/:id` - Delete conversation
- `POST /api/conversations/:id/participants` - Add participant
- `DELETE /api/conversations/:id/participants/:userId` - Remove participant

#### Messages
- `GET /api/conversations/:id/messages` - Get messages (paginated)
- `POST /api/conversations/:id/messages` - Send message
- `PATCH /api/messages/:id` - Edit message
- `DELETE /api/messages/:id` - Delete message
- `POST /api/messages/:id/reactions` - Add reaction
- `DELETE /api/messages/:id/reactions/:emoji` - Remove reaction

### WebSocket Events

#### Client → Server
- `authenticate` - Authenticate WebSocket connection
- `message:send` - Send new message
- `message:edit` - Edit message
- `message:delete` - Delete message
- `typing:start` - User started typing
- `typing:stop` - User stopped typing
- `message:read` - Mark messages as read
- `presence:update` - Update user presence

#### Server → Client
- `message:new` - New message received
- `message:updated` - Message edited
- `message:deleted` - Message deleted
- `typing:user` - User typing status
- `presence:changed` - User presence changed
- `conversation:updated` - Conversation metadata changed
- `error` - Error occurred

## Security Considerations

### Authentication & Authorization
- JWT-based authentication with refresh tokens
- Secure password hashing (bcrypt/argon2)
- Rate limiting on authentication endpoints
- CORS configuration
- WebSocket authentication via token

### Data Protection
- HTTPS/WSS only
- Encrypted data at rest (RDS encryption)
- Encrypted data in transit (TLS 1.3)
- Secure environment variables (AWS Secrets Manager)
- Input validation and sanitization
- SQL injection prevention (ORM)
- XSS prevention

### AWS Security
- VPC with private subnets for backend
- Security groups and NACLs
- IAM roles with least privilege
- S3 bucket policies
- CloudFront signed URLs for sensitive content

## Scalability Strategy (Cost-Optimized)

### Single Instance Optimization
- **In-memory caching**: Node.js Map/LRU cache for frequently accessed data
- **Database optimization**: Proper SQLite indexing and WAL mode
- **Connection limits**: Limit concurrent WebSocket connections (~500-1000 on t3.micro)
- **Static file serving**: Nginx for efficient static asset delivery
- **Process management**: PM2 for auto-restart and clustering

### When to Scale Up
- **Vertical scaling first**: Upgrade to t3.small → t3.medium (~$15-30/month)
- **Database migration**: Move to PostgreSQL when SQLite becomes bottleneck
- **File storage**: Offload to S3 when local storage fills up
- **Horizontal scaling**: Add load balancer + multiple instances when single instance maxes out

### Performance Limits (Single t3.micro)
- **Concurrent users**: ~100-500 active users
- **Messages/second**: ~50-100 messages
- **Database size**: Up to 10-50GB (SQLite performs well)
- **File storage**: Limited by EBS volume size

## Monitoring & Logging

### Metrics
- CloudWatch metrics for all AWS services
- Custom application metrics
- WebSocket connection count
- Message throughput
- API response times
- Error rates

### Logging
- Structured logging (JSON format)
- CloudWatch Logs
- Log aggregation and analysis
- Error tracking (Sentry/CloudWatch Insights)

### Alerting
- CloudWatch Alarms
- SNS notifications
- Auto-scaling triggers

## Deployment Strategy

### CI/CD Pipeline (Cost-Optimized)
1. **Source**: GitHub/GitLab
2. **Build**: 
   - Backend: Build TypeScript locally or in GitHub Actions (free)
   - Frontend: Static build with Vite (free)
3. **Test**: Unit tests in GitHub Actions (free tier: 2000 minutes/month)
4. **Deploy**:
   - SSH into EC2 instance
   - Pull latest code from Git
   - Run build script
   - Restart PM2 process
5. **Tools**: GitHub Actions (free) + simple bash deployment script

**No CodePipeline/CodeBuild**: Saves ~$1-10/month

### Environment Strategy (Cost-Optimized)
- **Development**: Local development (no Docker needed, native Node.js)
- **Staging**: Same EC2 instance, different port or subdomain
- **Production**: Same EC2 instance, main domain

**Single instance for both**: Use Nginx virtual hosts to separate staging/production

### Blue-Green Deployment
- Zero-downtime deployments
- Quick rollback capability
- Database migration strategy

## Cost Optimization Strategies

### Immediate Savings
- **Use t4g.micro (ARM)**: 20% cheaper than t3.micro (~$6/month vs ~$7.50)
- **Reserved Instance**: Save 30-40% with 1-year commitment (~$5/month)
- **Spot Instance**: Save 70% but risk interruption (not recommended for production)
- **Free Tier**: New AWS accounts get 750 hours/month free t2.micro for 12 months

### Operational Savings
- **Automated backups**: Use EBS snapshots, delete old ones
- **Log rotation**: Prevent disk space issues
- **Compression**: Enable gzip in Nginx
- **Image optimization**: Compress uploads before storing
- **Database cleanup**: Archive old messages periodically

### Monitoring Costs
- **CloudWatch**: Stay within free tier (10 metrics, 5GB logs)
- **Billing alerts**: Set up alerts at $10, $20, $50
- **Cost Explorer**: Review monthly to identify unexpected charges

## Development Phases

### Phase 1: MVP (4-6 weeks)
- Basic authentication
- One-on-one messaging
- Real-time message delivery
- Simple UI
- Basic AWS deployment

### Phase 2: Enhanced Features (4-6 weeks)
- Group chats
- File/image sharing
- Message reactions
- Typing indicators
- Read receipts
- Enhanced UI/UX

### Phase 3: Scale & Polish (4-6 weeks)
- Performance optimization
- Advanced search
- Push notifications
- Message threads
- User presence
- Admin features

### Phase 4: Production Ready (2-4 weeks)
- Security audit
- Load testing
- Monitoring setup
- Documentation
- Production deployment

## Project Structure

### Backend Structure
```
backend/
├── src/
│   ├── config/          # Configuration files
│   ├── controllers/     # Route controllers
│   ├── middleware/      # Express middleware
│   ├── models/          # Database models
│   ├── routes/          # API routes
│   ├── services/        # Business logic
│   ├── sockets/         # WebSocket handlers
│   ├── utils/           # Utility functions
│   ├── validators/      # Request validators
│   └── index.ts         # Entry point
├── tests/
├── prisma/              # Prisma schema
├── Dockerfile
├── package.json
└── tsconfig.json
```

### Frontend Structure
```
frontend/
├── src/
│   ├── components/      # React components
│   │   ├── chat/
│   │   ├── auth/
│   │   └── common/
│   ├── hooks/           # Custom hooks
│   ├── services/        # API services
│   ├── store/           # State management
│   ├── types/           # TypeScript types
│   ├── utils/           # Utility functions
│   ├── pages/           # Page components
│   ├── App.tsx
│   └── main.tsx
├── public/
├── package.json
├── vite.config.ts
└── tsconfig.json
```

## Next Steps (Cost-Optimized)

1. **Initialize Project**
   - Initialize backend and frontend projects (no monorepo needed)
   - Set up TypeScript configurations
   - Initialize SQLite database with Prisma

2. **Set Up Development Environment**
   - Local Node.js development
   - SQLite database file
   - Environment variable management (.env files)

3. **Implement Core Backend**
   - Database schema with Prisma + SQLite
   - Authentication system (JWT)
   - REST API endpoints
   - WebSocket server with Socket.IO

4. **Implement Core Frontend**
   - Authentication UI
   - Chat interface
   - WebSocket client
   - State management (Zustand)

5. **AWS Setup (Simple)**
   - Launch EC2 t3.micro instance (Ubuntu 22.04)
   - Assign Elastic IP
   - Configure security groups (ports 22, 80, 443)
   - Install Node.js, Nginx, PM2, Certbot
   - Set up Let's Encrypt SSL
   - Deploy application
   - Configure automated backups

6. **Optional: Domain Setup**
   - Register domain (~$10-15/year)
   - Point DNS to Elastic IP
   - Configure SSL certificate

## References & Resources

- [Socket.IO Documentation](https://socket.io/docs/)
- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [Prisma Documentation](https://www.prisma.io/docs)
- [React Documentation](https://react.dev/)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
