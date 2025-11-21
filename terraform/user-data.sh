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

# Create a welcome message
cat > /home/ubuntu/WELCOME.txt << 'EOF'
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   Welcome to Chatter Server!                              ║
║                                                           ║
║   Server setup is complete. Next steps:                   ║
║                                                           ║
║   1. Clone your repository:                               ║
║      cd /var/www/chatter                                  ║
║      git clone <your-repo-url> .                          ║
║                                                           ║
║   2. Deploy backend:                                      ║
║      cd backend                                           ║
║      npm install                                          ║
║      cp .env.example .env                                 ║
║      nano .env                                            ║
║      npm run build                                        ║
║      pm2 start ecosystem.config.js                        ║
║      pm2 save                                             ║
║                                                           ║
║   3. Deploy frontend:                                     ║
║      cd ../frontend                                       ║
║      npm install                                          ║
║      npm run build                                        ║
║                                                           ║
║   4. Restart Nginx to apply changes:                      ║
║      sudo systemctl restart nginx                         ║
║                                                           ║
║   5. Set up SSL:                                          ║
║      sudo certbot --nginx -d yourdomain.com               ║
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
