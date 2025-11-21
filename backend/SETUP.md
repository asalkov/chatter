# Backend Setup Instructions

## Step 1: Install Dependencies

Run the following commands in the `backend/` directory:

### Install TypeScript and Dev Dependencies
```bash
npm install -D typescript @types/node ts-node nodemon
npm install -D @types/express @types/jsonwebtoken @types/bcrypt
npm install -D @types/passport @types/passport-google-oauth20 @types/express-session @types/cors
npm install -D jest @types/jest supertest @types/supertest
```

### Install Core Dependencies
```bash
npm install express socket.io @prisma/client jsonwebtoken bcrypt
npm install passport passport-google-oauth20 express-session
npm install zod dotenv cors helmet
```

### Install Prisma
```bash
npm install -D prisma
```

## Step 2: Create Environment File

Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

Edit `.env` and update the values as needed.

## Step 3: Test the Server

Run the development server:
```bash
npm run dev
```

You should see:
```
🚀 Server is running on port 3000
📍 Environment: development
🔗 Health check: http://localhost:3000/health
```

## Step 4: Test the Health Endpoint

Open your browser or use curl:
```bash
curl http://localhost:3000/health
```

Expected response:
```json
{
  "status": "ok",
  "message": "Chatter API is running",
  "timestamp": "2025-11-20T..."
}
```

## Troubleshooting

### PowerShell Execution Policy Error

If you get an execution policy error when running npm commands:

**Option 1: Run in Command Prompt (cmd.exe) instead of PowerShell**

**Option 2: Set PowerShell execution policy (requires admin)**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Option 3: Use npx prefix**
```powershell
npx npm install
```

### Port Already in Use

If port 3000 is already in use, change the PORT in `.env`:
```
PORT=3001
```

## Next Steps

After successful setup:
1. Proceed to Day 3 - Frontend Setup
2. Or continue with Day 4 - Database Setup (Prisma)
