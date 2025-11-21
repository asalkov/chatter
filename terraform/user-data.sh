#!/bin/bash
set -e

# Log output
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting Chatter server setup..."

# Update system
echo "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install Node.js 20.x
echo "Installing Node.js 20.x..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Verify Node.js installation
node --version
npm --version

# Install Nginx
echo "Installing Nginx..."
apt-get install -y nginx

# Install PM2
echo "Installing PM2..."
npm install -g pm2

# Install Git
echo "Installing Git..."
apt-get install -y git

# Install Certbot for SSL
echo "Installing Certbot..."
apt-get install -y certbot python3-certbot-nginx

# Install additional utilities
apt-get install -y curl wget unzip htop

# Create application directory
echo "Creating application directories..."
mkdir -p /var/www/chatter
chown -R ubuntu:ubuntu /var/www/chatter

# Create uploads directory
mkdir -p /var/www/chatter/uploads
chown -R ubuntu:ubuntu /var/www/chatter/uploads

# Create backup directory
mkdir -p /var/www/chatter/backups
chown -R ubuntu:ubuntu /var/www/chatter/backups

# Create logs directory
mkdir -p /var/www/chatter/logs
chown -R ubuntu:ubuntu /var/www/chatter/logs

# Configure log rotation
echo "Configuring log rotation..."
cat > /etc/logrotate.d/chatter << 'EOF'
/var/www/chatter/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 ubuntu ubuntu
    sharedscripts
    postrotate
        pm2 reloadLogs
    endscript
}
EOF

# Install CloudWatch agent
echo "Installing CloudWatch agent..."
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb
rm amazon-cloudwatch-agent.deb

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
  "metrics": {
    "namespace": "CWAgent",
    "metrics_collected": {
      "disk": {
        "measurement": [
          {
            "name": "disk_free",
            "rename": "disk_free",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 300,
        "resources": [
          "/"
        ]
      },
      "mem": {
        "measurement": [
          {
            "name": "mem_used_percent",
            "rename": "mem_used_percent",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 300
      }
    }
  }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Set timezone
echo "Setting timezone to UTC..."
timedatectl set-timezone UTC

# Enable automatic security updates
echo "Enabling automatic security updates..."
apt-get install -y unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades

# Configure firewall (UFW)
echo "Configuring firewall..."
ufw --force enable
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp

# Create Nginx configuration for React + Node.js
echo "Creating Nginx configuration for React frontend and Node.js backend..."
cat > /etc/nginx/sites-available/chatter << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;
    client_max_body_size 50M;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # API routes - proxy to Node.js backend
    location /api {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400;
    }

    # WebSocket/Socket.IO support
    location /socket.io {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://127.0.0.1:3000/health;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        access_log off;
    }

    # Serve React frontend static files
    location / {
        root /var/www/chatter/frontend/dist;
        try_files $uri $uri/ /index.html;
        expires 1d;
        add_header Cache-Control "public, no-transform";
    }

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        root /var/www/chatter/frontend/dist;
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
}
EOF

# Enable the site
ln -sf /etc/nginx/sites-available/chatter /etc/nginx/sites-enabled/default
nginx -t
systemctl restart nginx

# Set up PM2 to start on boot
echo "Setting up PM2 startup..."
env PATH=$PATH:/usr/bin pm2 startup systemd -u ubuntu --hp /home/ubuntu

# Step 1: Clone the repository
echo "Cloning Chatter repository..."
cd /var/www/chatter
sudo -u ubuntu git clone https://github.com/asalkov/chatter.git .

# Verify clone was successful
if [ -d "/var/www/chatter/backend" ] && [ -d "/var/www/chatter/frontend" ]; then
    echo "Repository cloned successfully!"
else
    echo "Warning: Repository clone may have failed. Please check manually."
fi

# Step 2: Deploy Backend
echo "Deploying backend..."
cd /var/www/chatter/backend

# Install backend dependencies
echo "Installing backend dependencies..."
sudo -u ubuntu npm install

# Create production .env file
echo "Creating backend .env file..."
sudo -u ubuntu cat > .env << 'ENVEOF'
# Database
DATABASE_URL="file:./prod.db"

# JWT Secrets (CHANGE THESE IN PRODUCTION!)
JWT_SECRET="$(openssl rand -base64 32)"
JWT_REFRESH_SECRET="$(openssl rand -base64 32)"

# Server
PORT=3000
NODE_ENV=production

# Google OAuth (Configure these manually)
GOOGLE_CLIENT_ID=""
GOOGLE_CLIENT_SECRET=""
GOOGLE_CALLBACK_URL="http://YOUR_SERVER_IP/api/auth/google/callback"

# Session
SESSION_SECRET="$(openssl rand -base64 32)"

# Frontend URL
FRONTEND_URL="http://YOUR_SERVER_IP"
ENVEOF

# Build backend
echo "Building backend..."
sudo -u ubuntu npm run build

# Initialize database (if using Prisma)
if [ -f "prisma/schema.prisma" ]; then
    echo "Initializing database..."
    sudo -u ubuntu npx prisma generate
    sudo -u ubuntu npx prisma migrate deploy
fi

# Start backend with PM2
echo "Starting backend with PM2..."
sudo -u ubuntu pm2 start ecosystem.config.js
sudo -u ubuntu pm2 save

# Verify backend is running
sleep 3
if sudo -u ubuntu pm2 list | grep -q "chatter-backend"; then
    echo "Backend deployed and running successfully!"
else
    echo "Warning: Backend may not be running. Check with 'pm2 list'"
fi

# Create a welcome message
cat > /home/ubuntu/WELCOME.txt << 'EOF'
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   Welcome to Chatter Server!                              ║
║                                                           ║
║   Server setup is complete!                               ║
║                                                           ║
║   ✓ Repository cloned from GitHub                        ║
║   ✓ Backend deployed and running with PM2                ║
║                                                           ║
║   Next steps:                                             ║
║                                                           ║
║   1. Configure backend environment:                       ║
║      nano /var/www/chatter/backend/.env                   ║
║      (Update GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET)     ║
║      (Update YOUR_SERVER_IP with actual IP/domain)       ║
║      pm2 restart chatter-backend                          ║
║                                                           ║
║   2. Deploy frontend:                                     ║
║      cd /var/www/chatter/frontend                         ║
║      npm install                                          ║
║      npm run build                                        ║
║                                                           ║
║   3. Restart Nginx to apply changes:                      ║
║      sudo systemctl restart nginx                         ║
║                                                           ║
║   4. Set up SSL (optional):                               ║
║      sudo certbot --nginx -d yourdomain.com               ║
║                                                           ║
║   Useful commands:                                        ║
║   - Check backend status: pm2 status                      ║
║   - View backend logs: pm2 logs chatter-backend           ║
║   - Restart backend: pm2 restart chatter-backend          ║
║   - Check Nginx status: sudo systemctl status nginx       ║
║   - View Nginx logs: sudo tail -f /var/log/nginx/error.log
║                                                           ║
║   Installed software:                                     ║
║   - Node.js: $(node --version)                            ║
║   - npm: $(npm --version)                                 ║
║   - PM2: $(pm2 --version)                                 ║
║   - Nginx: $(nginx -v 2>&1)                               ║
║   - Git: $(git --version)                                 ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF

chown ubuntu:ubuntu /home/ubuntu/WELCOME.txt

# Display welcome message on login
echo "cat /home/ubuntu/WELCOME.txt" >> /home/ubuntu/.bashrc

# Clean up
echo "Cleaning up..."
apt-get autoremove -y
apt-get clean

echo "Server setup complete!"
echo "Chatter infrastructure is ready for deployment."
