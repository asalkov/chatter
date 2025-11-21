module.exports = {
  apps: [{
    name: 'chatter-backend',
    script: './dist/index.js',
    instances: 1,
    exec_mode: 'cluster',
    autorestart: true,
    watch: false,
    max_memory_restart: '500M',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: '/var/www/chatter/logs/backend-error.log',
    out_file: '/var/www/chatter/logs/backend-out.log',
    log_file: '/var/www/chatter/logs/backend-combined.log',
    time: true,
    merge_logs: true,
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
  }]
};
