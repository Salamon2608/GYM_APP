#!/bin/bash
# ==============================================================================
# TraceFit Gym Management - Production Server Setup Script (Ubuntu 22.04 / 24.04)
# Run on your AWS EC2 instance:
#   chmod +x deploy.sh
#   sudo ./deploy.sh
# ==============================================================================

set -e

echo "🚀 Starting TraceFit Production Server Setup..."

# 1. Update system packages
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# 2. Install essential tools and Node.js 20
echo "📦 Installing Node.js 20, Git, Nginx, and MySQL client..."
sudo apt install -y curl git ufw nginx mysql-client

curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# 3. Install PM2 globally for process management
echo "⚙️ Installing PM2..."
sudo npm install -g pm2

# 4. Clone or pull repository
APP_DIR="/var/www/tracefit"
if [ ! -d "$APP_DIR" ]; then
    echo "📥 Cloning GYM_APP from GitHub..."
    sudo git clone https://github.com/Salamon2608/GYM_APP.git "$APP_DIR"
else
    echo "🔄 Pulling latest changes from GitHub..."
    cd "$APP_DIR"
    sudo git pull origin main
fi

# Set permissions
sudo chown -R $USER:$USER "$APP_DIR"

# 5. Install backend production dependencies
echo "📦 Installing backend dependencies..."
cd "$APP_DIR/backend"
npm ci --only=production

# 6. Setup .env if not exists
if [ ! -f "$APP_DIR/backend/.env" ]; then
    echo "⚙️ Creating .env file from template..."
    cp "$APP_DIR/backend/.env.example" "$APP_DIR/backend/.env"
    echo "⚠️ NOTE: Please edit $APP_DIR/backend/.env with your actual database and JWT secrets!"
fi

# Ensure uploads directory exists
mkdir -p "$APP_DIR/backend/uploads"

# 7. Start backend with PM2
echo "🚀 Starting backend with PM2..."
pm2 start ecosystem.config.js --env production
pm2 startup systemd -u $USER --hp /home/$USER
pm2 save

# 8. Configure firewall (UFW)
echo "🔒 Configuring UFW firewall..."
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw --force enable

echo "✅ TraceFit setup finished successfully!"
echo "➡️ Next steps:"
echo "   1. Edit environment variables: nano $APP_DIR/backend/.env"
echo "   2. Import MySQL database: mysql -h <DB_HOST> -u <DB_USER> -p <DB_NAME> < $APP_DIR/backend/database/schema.sql"
echo "   3. Restart backend: pm2 restart tracefit-backend"
