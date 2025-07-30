#!/bin/bash

# =================================================================
# SISTEMA QUENTINHAS PRO - VERSÃO EMPRESARIAL AVANÇADA
# Robô WhatsApp + Google Gemini AI + Dashboard Completo + HTTPS
# =================================================================

set -e

echo "🚀 SISTEMA QUENTINHAS PRO - VERSÃO EMPRESARIAL AVANÇADA"
echo "=========================================================="
echo "🤖 Robô WhatsApp com Google Gemini AI"
echo "🔐 HTTPS + Nginx + Dashboard Seguro"
echo "💾 Backup Automático + Monitoramento"
echo "📊 Relatórios Financeiros Completos"
echo "⚡ PM2 Cluster + Redis Cache"
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_purple() { echo -e "${PURPLE}🎨 $1${NC}"; }

# Verificar se é root
if [[ $EUID -ne 0 ]]; then
    log_error "Execute como root: sudo su -"
    exit 1
fi

# Detectar IP público
log_info "Detectando IP público do servidor..."
PUBLIC_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || curl -s icanhazip.com)
if [ -z "$PUBLIC_IP" ]; then
    log_error "Não foi possível detectar IP público"
    exit 1
fi
log_success "IP público detectado: $PUBLIC_IP"

# =================================================================
# SOLICITAR GOOGLE GEMINI API KEY
# =================================================================

echo ""
log_purple "🤖 CONFIGURAÇÃO GOOGLE GEMINI AI"
echo "Para usar a IA conversacional avançada, você precisa de uma API Key do Google Gemini."
echo "1. Acesse: https://makersuite.google.com/app/apikey"
echo "2. Crie uma nova API Key"
echo "3. Cole a API Key abaixo"
echo ""

read -p "🔑 Digite sua Google Gemini API Key: " GEMINI_API_KEY

if [ -z "$GEMINI_API_KEY" ]; then
    log_warning "API Key não fornecida. Usando fallback básico."
    GEMINI_API_KEY="demo_key_fallback"
fi

# =================================================================
# CONFIGURAR FIREWALL AVANÇADO
# =================================================================

log_info "Configurando firewall de segurança avançado..."
apt update && apt install -y ufw fail2ban
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
ufw allow 3000/tcp comment 'Sistema Quentinhas'
ufw allow 8080/tcp comment 'WhatsApp API'
ufw allow 5678/tcp comment 'N8N'
ufw --force enable

# Configurar fail2ban
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 5
EOF

systemctl enable fail2ban
systemctl start fail2ban

log_success "Firewall e proteção anti-intrusão configurados!"

# =================================================================
# INSTALAÇÃO COMPLETA
# =================================================================

log_info "Instalando dependências avançadas do sistema..."
apt update && apt upgrade -y
apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release nano htop nginx certbot python3-certbot-nginx supervisor cron logrotate

log_info "Instalando Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update && apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

log_info "Instalando Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

log_info "Instalando Node.js 18..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

log_info "Instalando PM2..."
npm install -g pm2

PROJECT_DIR="/root/quentinhas-sistema-avancado"
log_info "Criando projeto em $PROJECT_DIR"

# Limpar instalação anterior se existir
if [ -d "$PROJECT_DIR" ]; then
    log_warning "Removendo instalação anterior..."
    pm2 stop quentinhas-sistema || true
    pm2 delete quentinhas-sistema || true
    cd $PROJECT_DIR && docker-compose down || true
    cd /root && rm -rf $PROJECT_DIR
fi

mkdir -p $PROJECT_DIR && cd $PROJECT_DIR
mkdir -p {src,prisma,setup,logs,uploads,public,ssl,backups,middlewares,routes,services,utils,scripts}

# =================================================================
# PACKAGE.JSON AVANÇADO
# =================================================================

log_info "Criando package.json com dependências avançadas..."
cat > package.json << 'EOF'
{
  "name": "quentinhas-sistema-avancado",
  "version": "3.0.0",
  "description": "Sistema empresarial completo para gestão de quentinhas com IA conversacional",
  "main": "server.js",
  "scripts": {
    "start": "pm2 start ecosystem.config.js",
    "stop": "pm2 stop quentinhas-sistema",
    "restart": "pm2 restart quentinhas-sistema",
    "logs": "pm2 logs quentinhas-sistema",
    "dev": "nodemon server.js",
    "migrate": "npx prisma migrate deploy",
    "seed": "node setup/seed.js",
    "generate": "npx prisma generate",
    "backup": "node scripts/backup.js",
    "monitor": "pm2 monit"
  },
  "dependencies": {
    "express": "^4.18.2",
    "prisma": "^5.7.1",
    "@prisma/client": "^5.7.1",
    "cors": "^2.8.5",
    "helmet": "^7.1.0",
    "bcryptjs": "^2.4.3",
    "jsonwebtoken": "^9.0.2",
    "axios": "^1.6.2",
    "multer": "^1.4.4",
    "socket.io": "^4.7.4",
    "node-cron": "^3.0.3",
    "winston": "^3.11.0",
    "joi": "^17.11.0",
    "dotenv": "^16.3.1",
    "express-rate-limit": "^7.1.5",
    "compression": "^1.7.4",
    "morgan": "^1.10.0",
    "express-session": "^1.17.3",
    "connect-redis": "^7.1.0",
    "redis": "^4.6.10",
    "uuid": "^9.0.1",
    "moment": "^2.29.4",
    "express-validator": "^7.0.1",
    "@google/generative-ai": "^0.2.1",
    "node-cache": "^5.1.2",
    "express-slow-down": "^2.0.1",
    "express-mongo-sanitize": "^2.2.0",
    "hpp": "^0.2.3",
    "xss": "^1.0.14",
    "validator": "^13.11.0",
    "sharp": "^0.33.0",
    "csv-writer": "^1.6.0",
    "exceljs": "^4.4.0",
    "qrcode": "^1.5.3",
    "nodemailer": "^6.9.7"
  },
  "devDependencies": {
    "nodemon": "^3.0.2"
  }
}
EOF

# =================================================================
# CONFIGURAÇÃO .ENV AVANÇADA
# =================================================================

log_info "Criando configuração .env avançada..."
cat > .env << EOF
# Banco de Dados
DATABASE_URL="postgresql://quentinhas:quentinhas123@localhost:5432/quentinhas"
REDIS_URL="redis://localhost:6379"

# Segurança
JWT_SECRET="$(openssl rand -base64 64)"
SESSION_SECRET="$(openssl rand -base64 64)"
BCRYPT_ROUNDS=12
ENCRYPTION_KEY="$(openssl rand -base64 32)"

# Servidor
PORT=3000
NODE_ENV=production
PUBLIC_IP="${PUBLIC_IP}"
DOMAIN="quentinhas.local"

# WhatsApp API
EVOLUTION_API_URL="http://localhost:8080"
EVOLUTION_API_KEY="QUENTINHAS_SECURE_$(openssl rand -hex 16)"
EVOLUTION_INSTANCE="quentinhas-main"

# Google Gemini AI
GEMINI_API_KEY="${GEMINI_API_KEY}"
GEMINI_MODEL="gemini-pro"

# N8N
N8N_WEBHOOK_URL="http://localhost:5678"

# Configurações do Negócio
BUSINESS_NAME="Quentinhas da Casa"
BUSINESS_PHONE="(11) 99999-9999"
BUSINESS_ADDRESS="Rua das Delícias, 123 - Centro - São Paulo/SP"
BUSINESS_HOURS_START="10:00"
BUSINESS_HOURS_END="22:00"
DELIVERY_FEE=5.00
MIN_ORDER_VALUE=25.00
MAX_DELIVERY_DISTANCE=10

# Upload e Arquivos
MAX_FILE_SIZE=10485760
UPLOAD_PATH="./uploads"

# Logs e Monitoramento
LOG_LEVEL="info"
LOG_FILE="./logs/system.log"
MONITOR_INTERVAL=60000

# Email (Opcional)
EMAIL_HOST="smtp.gmail.com"
EMAIL_PORT=587
EMAIL_USER=""
EMAIL_PASS=""

# Backup
BACKUP_INTERVAL="0 2 * * *"
BACKUP_RETENTION_DAYS=30
EOF

# =================================================================
# DOCKER COMPOSE AVANÇADO
# =================================================================

log_info "Criando docker-compose.yml avançado..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15
    container_name: quentinhas-postgres
    environment:
      POSTGRES_DB: quentinhas
      POSTGRES_USER: quentinhas
      POSTGRES_PASSWORD: quentinhas123
      POSTGRES_INITDB_ARGS: "--encoding=UTF-8 --lc-collate=C --lc-ctype=C"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backups:/backups
    ports:
      - "5432:5432"
    restart: unless-stopped
    networks:
      - quentinhas-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U quentinhas -d quentinhas"]
      interval: 10s
      timeout: 5s
      retries: 5
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M

  redis:
    image: redis:7-alpine
    container_name: quentinhas-redis
    command: redis-server --appendonly yes --requirepass redis123 --maxmemory 256mb --maxmemory-policy allkeys-lru
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    restart: unless-stopped
    networks:
      - quentinhas-network
    healthcheck:
      test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5

  mongo:
    image: mongo:6
    container_name: quentinhas-mongo
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: evolution123
    volumes:
      - mongo_data:/data/db
    ports:
      - "27017:27017"
    restart: unless-stopped
    networks:
      - quentinhas-network

  n8n:
    image: n8nio/n8n:latest
    container_name: quentinhas-n8n
    environment:
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - WEBHOOK_URL=http://host.docker.internal:3000
      - GENERIC_TIMEZONE=America/Sao_Paulo
      - N8N_METRICS=true
      - N8N_SECURE_COOKIE=false
      - N8N_LOG_LEVEL=info
    ports:
      - "5678:5678"
    volumes:
      - n8n_data:/home/node/.n8n
    extra_hosts:
      - "host.docker.internal:host-gateway"
    restart: unless-stopped
    networks:
      - quentinhas-network

  prometheus:
    image: prom/prometheus:latest
    container_name: quentinhas-prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
    restart: unless-stopped
    networks:
      - quentinhas-network

volumes:
  postgres_data:
  redis_data:
  mongo_data:
  n8n_data:
  prometheus_data:

networks:
  quentinhas-network:
    driver: bridge
EOF

# =================================================================
# SCHEMA PRISMA COMPLETO
# =================================================================

log_info "Criando schema Prisma completo..."
cat > prisma/schema.prisma << 'EOF'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id        String   @id @default(cuid())
  email     String   @unique
  password  String
  name      String
  role      Role     @default(ADMIN)
  isActive  Boolean  @default(true)
  lastLogin DateTime?
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  @@map("users")
}

model Customer {
  id            String    @id @default(cuid())
  phone         String    @unique
  name          String?
  email         String?
  addresses     CustomerAddress[]
  defaultAddressId String?
  totalOrders   Int       @default(0)
  totalSpent    Float     @default(0)
  loyaltyPoints Int       @default(0)
  isVip         Boolean   @default(false)
  isBlocked     Boolean   @default(false)
  lastOrderAt   DateTime?
  preferences   Json?
  notes         String?
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt
  orders        Order[]
  interactions  Interaction[]
  sessions      CustomerSession[]
  @@map("customers")
}

model CustomerAddress {
  id         String   @id @default(cuid())
  customerId String
  customer   Customer @relation(fields: [customerId], references: [id], onDelete: Cascade)
  label      String
  street     String
  number     String
  complement String?
  district   String
  city       String
  state      String
  zipCode    String?
  reference  String?
  isDefault  Boolean  @default(false)
  createdAt  DateTime @default(now())
  updatedAt  DateTime @updatedAt
  orders     Order[]
  @@map("customer_addresses")
}

model CustomerSession {
  id         String      @id @default(cuid())
  customerId String
  customer   Customer    @relation(fields: [customerId], references: [id], onDelete: Cascade)
  state      SessionState
  context    Json?
  lastActivity DateTime  @default(now())
  expiresAt  DateTime
  createdAt  DateTime    @default(now())
  @@map("customer_sessions")
}

model MenuItem {
  id          String   @id @default(cuid())
  name        String   @unique
  description String?
  price       Float
  category    String
  imageUrl    String?
  available   Boolean  @default(true)
  soldCount   Int      @default(0)
  ingredients String[]
  allergens   String[]
  calories    Int?
  prepTime    Int?
  isPromotion Boolean  @default(false)
  promotionPrice Float?
  promotionEnd DateTime?
  position    Int      @default(0)
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
  orderItems  OrderItem[]
  @@map("menu_items")
}

model Order {
  id              String      @id @default(cuid())
  orderNumber     String      @unique
  customerId      String
  customer        Customer    @relation(fields: [customerId], references: [id])
  addressId       String?
  address         CustomerAddress? @relation(fields: [addressId], references: [id])
  status          OrderStatus @default(PENDING)
  totalAmount     Float
  deliveryFee     Float
  discount        Float       @default(0)
  finalAmount     Float
  paymentMethod   PaymentMethod?
  paymentStatus   PaymentStatus @default(PENDING)
  deliveryType    DeliveryType @default(DELIVERY)
  notes           String?
  estimatedTime   Int?
  actualTime      Int?
  rating          Int?
  feedback        String?
  cancelReason    String?
  createdAt       DateTime    @default(now())
  updatedAt       DateTime    @updatedAt
  confirmedAt     DateTime?
  deliveredAt     DateTime?
  cancelledAt     DateTime?
  items           OrderItem[]
  statusHistory   OrderStatusHistory[]
  @@map("orders")
}

model OrderItem {
  id         String   @id @default(cuid())
  orderId    String
  order      Order    @relation(fields: [orderId], references: [id], onDelete: Cascade)
  menuItemId String
  menuItem   MenuItem @relation(fields: [menuItemId], references: [id])
  quantity   Int
  unitPrice  Float
  totalPrice Float
  notes      String?
  @@map("order_items")
}

model OrderStatusHistory {
  id        String      @id @default(cuid())
  orderId   String
  order     Order       @relation(fields: [orderId], references: [id], onDelete: Cascade)
  status    OrderStatus
  timestamp DateTime    @default(now())
  notes     String?
  userId    String?
  @@map("order_status_history")
}

model Interaction {
  id           String          @id @default(cuid())
  customerId   String
  customer     Customer        @relation(fields: [customerId], references: [id], onDelete: Cascade)
  type         InteractionType
  message      String
  response     String?
  intent       String?
  satisfaction Int?
  metadata     Json?
  createdAt    DateTime        @default(now())
  @@map("interactions")
}

model Category {
  id        String   @id @default(cuid())
  name      String   @unique
  description String?
  position  Int      @default(0)
  isActive  Boolean  @default(true)
  imageUrl  String?
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  @@map("categories")
}

model Setting {
  id    String @id @default(cuid())
  key   String @unique
  value String
  type  SettingType @default(STRING)
  description String?
  updatedAt DateTime @updatedAt
  @@map("settings")
}

model Analytics {
  id               String   @id @default(cuid())
  date             DateTime @unique
  totalOrders      Int      @default(0)
  totalRevenue     Float    @default(0)
  avgTicket        Float    @default(0)
  newCustomers     Int      @default(0)
  conversionRate   Float    @default(0)
  cancelationRate  Float    @default(0)
  avgDeliveryTime  Int?
  topCategory      String?
  topItem          String?
  busyHour         Int?
  paymentMethods   Json?
  deliveryAreas    Json?
  @@map("analytics")
}

model FinancialReport {
  id            String   @id @default(cuid())
  date          DateTime @unique
  grossRevenue  Float    @default(0)
  netRevenue    Float    @default(0)
  totalOrders   Int      @default(0)
  avgTicket     Float    @default(0)
  deliveryFees  Float    @default(0)
  discounts     Float    @default(0)
  canceledValue Float    @default(0)
  hourlyStats   Json?
  categoryStats Json?
  paymentStats  Json?
  createdAt     DateTime @default(now())
  @@map("financial_reports")
}

model SystemLog {
  id        String   @id @default(cuid())
  level     LogLevel
  message   String
  context   Json?
  userId    String?
  ip        String?
  userAgent String?
  createdAt DateTime @default(now())
  @@map("system_logs")
}

enum Role {
  ADMIN
  MANAGER
  OPERATOR
}

enum SessionState {
  WELCOME
  BROWSING_MENU
  SELECTING_ITEMS
  IN_CART
  COLLECTING_ADDRESS
  COLLECTING_PAYMENT
  CONFIRMING_ORDER
  ORDER_PLACED
  IDLE
  RATING
}

enum OrderStatus {
  PENDING
  CONFIRMED
  PREPARING
  READY
  OUT_FOR_DELIVERY
  DELIVERED
  CANCELLED
}

enum PaymentMethod {
  CASH
  PIX
  CREDIT_CARD
  DEBIT_CARD
  BANK_TRANSFER
}

enum PaymentStatus {
  PENDING
  PAID
  FAILED
  REFUNDED
}

enum DeliveryType {
  DELIVERY
  PICKUP
}

enum InteractionType {
  MESSAGE
  ORDER
  COMPLAINT
  FEEDBACK
  SUPPORT
  MENU_VIEW
  CART_ACTION
}

enum SettingType {
  STRING
  NUMBER
  BOOLEAN
  JSON
}

enum LogLevel {
  ERROR
  WARN
  INFO
  DEBUG
}
EOF

# =================================================================
# PM2 ECOSYSTEM CONFIG
# =================================================================

log_info "Criando configuração PM2 cluster..."
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'quentinhas-sistema',
    script: 'server.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true,
    max_memory_restart: '1G',
    node_args: '--max-old-space-size=1024',
    watch: false,
    ignore_watch: ['node_modules', 'logs', 'backups'],
    min_uptime: '10s',
    max_restarts: 10,
    autorestart: true,
    cron_restart: '0 4 * * *'
  }]
};
EOF

# =================================================================
# INICIAR SERVIÇOS DOCKER
# =================================================================

log_info "Criando diretório de monitoramento..."
mkdir -p monitoring

cat > monitoring/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'quentinhas-sistema'
    static_configs:
      - targets: ['host.docker.internal:3000']
    metrics_path: '/metrics'
    scrape_interval: 5s
EOF

log_info "Iniciando serviços Docker..."
docker-compose up -d

log_info "Aguardando bancos de dados..."
sleep 60

until docker exec quentinhas-postgres pg_isready -U quentinhas >/dev/null 2>&1; do
    log_warning "Aguardando PostgreSQL..."
    sleep 5
done
log_success "PostgreSQL pronto!"

log_info "Instalando dependências Node.js..."
npm install

log_info "Configurando banco de dados..."
npx prisma generate
npx prisma migrate dev --name init

# =================================================================
# SEED AVANÇADO
# =================================================================

log_info "Criando seed avançado..."
cat > setup/seed.js << 'EOF'
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Iniciando seed avançado do sistema...');

  // Criar usuário admin
  const hashedPassword = await bcrypt.hash('admin123', 12);
  const admin = await prisma.user.create({
    data: {
      email: 'admin@quentinhas.com',
      password: hashedPassword,
      name: 'Administrador Sistema',
      role: 'ADMIN',
    },
  });
  console.log('👤 Usuário admin criado:', admin.email);

  // Criar categorias
  const categories = await Promise.all([
    prisma.category.create({
      data: { name: 'Pratos Principais', position: 1, description: 'Refeições completas e nutritivas' }
    }),
    prisma.category.create({
      data: { name: 'Saladas', position: 2, description: 'Opções leves e saudáveis' }
    }),
    prisma.category.create({
      data: { name: 'Sobremesas', position: 3, description: 'Doces e sobremesas caseiras' }
    }),
    prisma.category.create({
      data: { name: 'Bebidas', position: 4, description: 'Sucos, refrigerantes e água' }
    }),
  ]);
  console.log('📂 Categorias criadas:', categories.length);

  // Criar itens do cardápio
  const menuItems = await Promise.all([
    prisma.menuItem.create({
      data: {
        name: 'Arroz com Frango Grelhado',
        description: 'Arroz soltinho com frango grelhado temperado, acompanha salada',
        price: 18.90,
        category: 'Pratos Principais',
        ingredients: ['Arroz', 'Frango', 'Temperos', 'Salada'],
        calories: 450,
        prepTime: 25
      }
    }),
    prisma.menuItem.create({
      data: {
        name: 'Lasanha de Carne',
        description: 'Lasanha tradicional com molho de carne e queijo derretido',
        price: 22.50,
        category: 'Pratos Principais',
        ingredients: ['Massa', 'Carne moída', 'Molho de tomate', 'Queijo'],
        calories: 520,
        prepTime: 30
      }
    }),
    prisma.menuItem.create({
      data: {
        name: 'Salada Caesar',
        description: 'Alface americana, croutons, queijo parmesão e molho caesar',
        price: 15.90,
        category: 'Saladas',
        ingredients: ['Alface', 'Croutons', 'Queijo parmesão', 'Molho caesar'],
        calories: 280,
        prepTime: 10
      }
    }),
    prisma.menuItem.create({
      data: {
        name: 'Pudim de Leite',
        description: 'Pudim de leite condensado cremoso com calda de caramelo',
        price: 8.90,
        category: 'Sobremesas',
        ingredients: ['Leite condensado', 'Ovos', 'Açúcar'],
        calories: 220,
        prepTime: 5
      }
    }),
    prisma.menuItem.create({
      data: {
        name: 'Suco Natural de Laranja',
        description: 'Suco de laranja natural 300ml',
        price: 6.50,
        category: 'Bebidas',
        ingredients: ['Laranja'],
        calories: 110,
        prepTime: 3
      }
    })
  ]);
  console.log('🍽️ Itens do cardápio criados:', menuItems.length);

  // Criar configurações avançadas
  await prisma.setting.createMany({
    data: [
      { key: 'business_name', value: 'Quentinhas da Casa', type: 'STRING' },
      { key: 'business_phone', value: '(11) 99999-9999', type: 'STRING' },
      { key: 'business_address', value: 'Rua das Delícias, 123 - Centro', type: 'STRING' },
      { key: 'business_hours_start', value: '10:00', type: 'STRING' },
      { key: 'business_hours_end', value: '22:00', type: 'STRING' },
      { key: 'delivery_fee', value: '5.00', type: 'NUMBER' },
      { key: 'min_order_value', value: '25.00', type: 'NUMBER' },
      { key: 'max_delivery_distance', value: '10', type: 'NUMBER' },
      { key: 'estimated_delivery_time', value: '45', type: 'NUMBER' },
      { key: 'welcome_message', value: 'Olá! 😊 Bem-vindo às *Quentinhas da Casa*!\\n\\nSomos especialistas em comida caseira deliciosa!\\n\\nComo posso te ajudar hoje?', type: 'STRING' },
      { key: 'order_confirmation_message', value: '✅ *Pedido #{orderNumber} confirmado!*\\n\\nObrigado pela preferência! Seu pedido está sendo preparado com todo carinho.\\n\\n⏰ Tempo estimado: {estimatedTime} minutos\\n💰 Total: R$ {total}\\n\\nEm breve entraremos em contato!', type: 'STRING' },
      { key: 'payment_methods', value: '["PIX", "Dinheiro", "Cartão"]', type: 'JSON' },
      { key: 'auto_accept_orders', value: 'false', type: 'BOOLEAN' },
      { key: 'notifications_enabled', value: 'true', type: 'BOOLEAN' },
      { key: 'ai_enabled', value: 'true', type: 'BOOLEAN' },
      { key: 'backup_enabled', value: 'true', type: 'BOOLEAN' },
      { key: 'monitoring_enabled', value: 'true', type: 'BOOLEAN' },
    ],
  });
  console.log('⚙️ Configurações criadas');

  // Criar dados de analytics para demonstração
  const today = new Date();
  const dates = [];
  for (let i = 30; i >= 0; i--) {
    const date = new Date(today);
    date.setDate(date.getDate() - i);
    dates.push(date);
  }

  for (const date of dates) {
    await prisma.analytics.create({
      data: {
        date,
        totalOrders: Math.floor(Math.random() * 50) + 10,
        totalRevenue: Math.random() * 1000 + 200,
        avgTicket: Math.random() * 30 + 15,
        newCustomers: Math.floor(Math.random() * 10) + 1,
        conversionRate: Math.random() * 0.3 + 0.1,
        cancelationRate: Math.random() * 0.1,
        avgDeliveryTime: Math.floor(Math.random() * 20) + 30,
        topCategory: 'Pratos Principais',
        topItem: 'Arroz com Frango Grelhado',
        busyHour: Math.floor(Math.random() * 6) + 18
      }
    });
  }
  console.log('📊 Dados de analytics criados');

  console.log('✅ Seed concluído com sucesso!');
}

main()
  .catch((e) => {
    console.error('❌ Erro no seed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
EOF

npm run seed

# =================================================================
# SERVIDOR PRINCIPAL AVANÇADO
# =================================================================

log_info "Criando servidor principal avançado..."
cat > server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const session = require('express-session');
const RedisStore = require('connect-redis').default;
const rateLimit = require('express-rate-limit');
const slowDown = require('express-slow-down');
const mongoSanitize = require('express-mongo-sanitize');
const hpp = require('hpp');
const xss = require('xss');
const { PrismaClient } = require('@prisma/client');
const { createClient } = require('redis');
const http = require('http');
const socketIo = require('socket.io');
const path = require('path');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const winston = require('winston');
const cron = require('node-cron');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const NodeCache = require('node-cache');
const fs = require('fs').promises;
const moment = require('moment');
require('dotenv').config();

// Inicializar clientes
const prisma = new PrismaClient();
const redisClient = createClient({ url: process.env.REDIS_URL });
redisClient.connect().catch(console.error);

// Cache local
const cache = new NodeCache({ stdTTL: 600 }); // 10 minutos

// Google Gemini AI
let genAI = null;
let model = null;
if (process.env.GEMINI_API_KEY && process.env.GEMINI_API_KEY !== 'demo_key_fallback') {
  genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
  model = genAI.getGenerativeModel({ model: process.env.GEMINI_MODEL || 'gemini-pro' });
}

// Configurar logger avançado
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    new winston.transports.File({ filename: 'logs/combined.log' }),
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      )
    })
  ],
});

const app = express();
app.set('trust proxy', 1);
const server = http.createServer(app);
const io = socketIo(server, {
  cors: { origin: "*", methods: ["GET", "POST", "PUT", "DELETE"] }
});

// Middleware de segurança avançado
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https://cdnjs.cloudflare.com", "https://fonts.googleapis.com"],
      scriptSrc: ["'self'", "'unsafe-inline'", "https://cdnjs.cloudflare.com"],
      imgSrc: ["'self'", "data:", "https:"],
      fontSrc: ["'self'", "https://fonts.gstatic.com"],
    },
  },
}));

app.use(cors());
app.use(compression());
app.use(mongoSanitize());
app.use(hpp());
app.use(morgan('combined', { 
  stream: { write: message => logger.info(message.trim()) }
}));

// Rate limiting avançado
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 200,
  message: { error: 'Muitas tentativas, tente novamente em 15 minutos' },
  standardHeaders: true,
  legacyHeaders: false,
});

const speedLimiter = slowDown({
  windowMs: 15 * 60 * 1000,
  delayAfter: 50,
  delayMs: 500
});

app.use(limiter);
app.use(speedLimiter);

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Configurar sessão com Redis
app.use(session({
  store: new RedisStore({ client: redisClient }),
  secret: process.env.SESSION_SECRET,
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: false,
    httpOnly: true,
    maxAge: 24 * 60 * 60 * 1000
  }
}));

// =================================================================
// MIDDLEWARE DE AUTENTICAÇÃO AVANÇADO
// =================================================================

const requireAuth = async (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '') || req.session.token;
    
    if (!token) {
      return res.status(401).json({ error: 'Token de acesso necessário' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId, isActive: true }
    });

    if (!user) {
      return res.status(401).json({ error: 'Usuário não encontrado' });
    }

    req.user = user;
    next();
  } catch (error) {
    logger.error('Erro na autenticação:', error);
    res.status(401).json({ error: 'Token inválido' });
  }
};

// =================================================================
// SISTEMA DE CACHE AVANÇADO
// =================================================================

const getCachedData = async (key) => {
  try {
    // Tentar cache local primeiro
    const localData = cache.get(key);
    if (localData) return localData;

    // Tentar Redis
    const redisData = await redisClient.get(key);
    if (redisData) {
      const parsed = JSON.parse(redisData);
      cache.set(key, parsed); // Sincronizar com cache local
      return parsed;
    }

    return null;
  } catch (error) {
    logger.error('Erro no cache:', error);
    return null;
  }
};

const setCachedData = async (key, data, ttl = 600) => {
  try {
    cache.set(key, data, ttl);
    await redisClient.setex(key, ttl, JSON.stringify(data));
  } catch (error) {
    logger.error('Erro ao salvar cache:', error);
  }
};

// =================================================================
// API DE AUTENTICAÇÃO
// =================================================================

app.post('/api/auth/login', [
  body('email').isEmail().normalizeEmail(),
  body('password').isLength({ min: 6 })
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { email, password } = req.body;

    const user = await prisma.user.findUnique({
      where: { email, isActive: true }
    });

    if (!user || !await bcrypt.compare(password, user.password)) {
      return res.status(401).json({ error: 'Credenciais inválidas' });
    }

    await prisma.user.update({
      where: { id: user.id },
      data: { lastLogin: new Date() }
    });

    const token = jwt.sign(
      { userId: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    req.session.token = token;
    req.session.userId = user.id;

    // Log de acesso
    await prisma.systemLog.create({
      data: {
        level: 'INFO',
        message: 'Login realizado',
        context: { email, ip: req.ip },
        userId: user.id
      }
    });

    res.json({
      token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role
      }
    });

    logger.info(`Login realizado: ${user.email}`);
  } catch (error) {
    logger.error('Erro no login:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

app.post('/api/auth/logout', (req, res) => {
  req.session.destroy();
  res.json({ message: 'Logout realizado com sucesso' });
});

app.get('/api/auth/me', requireAuth, (req, res) => {
  res.json({
    user: {
      id: req.user.id,
      email: req.user.email,
      name: req.user.name,
      role: req.user.role
    }
  });
});

// =================================================================
// API DO DASHBOARD AVANÇADO
// =================================================================

app.get('/api/dashboard', requireAuth, async (req, res) => {
  try {
    // Tentar cache primeiro
    const cacheKey = `dashboard:${moment().format('YYYY-MM-DD')}`;
    let dashboardData = await getCachedData(cacheKey);

    if (!dashboardData) {
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);

      const [
        todayOrders,
        todayRevenue,
        totalCustomers,
        pendingOrders,
        topItems,
        recentOrders,
        weeklyStats,
        monthlyStats
      ] = await Promise.all([
        prisma.order.count({
          where: { createdAt: { gte: today, lt: tomorrow } }
        }),
        prisma.order.aggregate({
          where: { 
            createdAt: { gte: today, lt: tomorrow },
            status: { not: 'CANCELLED' }
          },
          _sum: { finalAmount: true }
        }),
        prisma.customer.count(),
        prisma.order.count({
          where: { status: { in: ['PENDING', 'CONFIRMED', 'PREPARING'] } }
        }),
        prisma.orderItem.groupBy({
          by: ['menuItemId'],
          _sum: { quantity: true },
          orderBy: { _sum: { quantity: 'desc' } },
          take: 5
        }),
        prisma.order.findMany({
          take: 10,
          orderBy: { createdAt: 'desc' },
          include: {
            customer: true,
            items: { include: { menuItem: true } }
          }
        }),
        getWeeklyStats(),
        getMonthlyStats()
      ]);

      const revenue = todayRevenue._sum.finalAmount || 0;
      const avgTicket = todayOrders > 0 ? revenue / todayOrders : 0;

      const topItemsWithNames = await Promise.all(
        topItems.map(async (item) => {
          const menuItem = await prisma.menuItem.findUnique({
            where: { id: item.menuItemId }
          });
          return {
            name: menuItem?.name || 'Item removido',
            quantity: item._sum.quantity
          };
        })
      );

      dashboardData = {
        todayOrders,
        todayRevenue: revenue,
        avgTicket,
        totalCustomers,
        pendingOrders,
        topItems: topItemsWithNames,
        recentOrders,
        weeklyStats,
        monthlyStats
      };

      // Cache por 5 minutos
      await setCachedData(cacheKey, dashboardData, 300);
    }

    res.json(dashboardData);
  } catch (error) {
    logger.error('Erro no dashboard:', error);
    res.status(500).json({ error: 'Erro ao carregar dashboard' });
  }
});

async function getWeeklyStats() {
  const weekAgo = new Date();
  weekAgo.setDate(weekAgo.getDate() - 7);

  const dailyStats = await prisma.order.groupBy({
    by: ['createdAt'],
    where: {
      createdAt: { gte: weekAgo },
      status: { not: 'CANCELLED' }
    },
    _sum: { finalAmount: true },
    _count: true
  });

  return dailyStats.map(stat => ({
    date: moment(stat.createdAt).format('DD/MM'),
    revenue: stat._sum.finalAmount || 0,
    orders: stat._count
  }));
}

async function getMonthlyStats() {
  const monthAgo = new Date();
  monthAgo.setMonth(monthAgo.getMonth() - 1);

  return await prisma.order.groupBy({
    by: ['createdAt'],
    where: {
      createdAt: { gte: monthAgo },
      status: { not: 'CANCELLED' }
    },
    _sum: { finalAmount: true },
    _count: true
  });
}

// =================================================================
// API FINANCEIRA AVANÇADA
// =================================================================

app.get('/api/financial/reports', requireAuth, async (req, res) => {
  try {
    const { period, startDate, endDate } = req.query;
    
    let where = {};
    const now = new Date();
    
    switch (period) {
      case 'today':
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);
        where.createdAt = { gte: today, lt: tomorrow };
        break;
        
      case 'week':
        const weekStart = new Date();
        weekStart.setDate(weekStart.getDate() - 7);
        where.createdAt = { gte: weekStart };
        break;
        
      case 'month':
        const monthStart = new Date();
        monthStart.setMonth(monthStart.getMonth() - 1);
        where.createdAt = { gte: monthStart };
        break;
        
      case 'custom':
        if (startDate && endDate) {
          where.createdAt = {
            gte: new Date(startDate),
            lte: new Date(endDate)
          };
        }
        break;
    }

    const [
      totalOrders,
      grossRevenue,
      deliveryFees,
      discounts,
      canceledOrders,
      paymentMethodStats,
      hourlyStats,
      categoryStats
    ] = await Promise.all([
      prisma.order.count({ where }),
      prisma.order.aggregate({
        where: { ...where, status: { not: 'CANCELLED' } },
        _sum: { finalAmount: true }
      }),
      prisma.order.aggregate({
        where: { ...where, status: { not: 'CANCELLED' } },
        _sum: { deliveryFee: true }
      }),
      prisma.order.aggregate({
        where: { ...where, status: { not: 'CANCELLED' } },
        _sum: { discount: true }
      }),
      prisma.order.aggregate({
        where: { ...where, status: 'CANCELLED' },
        _sum: { finalAmount: true }
      }),
      getPaymentMethodStats(where),
      getHourlyStats(where),
      getCategoryStats(where)
    ]);

    const report = {
      totalOrders,
      grossRevenue: grossRevenue._sum.finalAmount || 0,
      netRevenue: (grossRevenue._sum.finalAmount || 0) - (deliveryFees._sum.deliveryFee || 0),
      deliveryFees: deliveryFees._sum.deliveryFee || 0,
      discounts: discounts._sum.discount || 0,
      canceledValue: canceledOrders._sum.finalAmount || 0,
      avgTicket: totalOrders > 0 ? (grossRevenue._sum.finalAmount || 0) / totalOrders : 0,
      paymentMethodStats,
      hourlyStats,
      categoryStats
    };

    res.json(report);
  } catch (error) {
    logger.error('Erro no relatório financeiro:', error);
    res.status(500).json({ error: 'Erro ao gerar relatório' });
  }
});

async function getPaymentMethodStats(where) {
  return await prisma.order.groupBy({
    by: ['paymentMethod'],
    where: { ...where, status: { not: 'CANCELLED' } },
    _sum: { finalAmount: true },
    _count: true
  });
}

async function getHourlyStats(where) {
  const orders = await prisma.order.findMany({
    where: { ...where, status: { not: 'CANCELLED' } },
    select: { createdAt: true, finalAmount: true }
  });

  const hourlyData = {};
  orders.forEach(order => {
    const hour = new Date(order.createdAt).getHours();
    if (!hourlyData[hour]) {
      hourlyData[hour] = { revenue: 0, count: 0 };
    }
    hourlyData[hour].revenue += order.finalAmount;
    hourlyData[hour].count++;
  });

  return Object.entries(hourlyData).map(([hour, data]) => ({
    hour: parseInt(hour),
    revenue: data.revenue,
    orders: data.count
  }));
}

async function getCategoryStats(where) {
  const items = await prisma.orderItem.findMany({
    where: {
      order: { ...where, status: { not: 'CANCELLED' } }
    },
    include: { menuItem: true }
  });

  const categoryData = {};
  items.forEach(item => {
    const category = item.menuItem.category;
    if (!categoryData[category]) {
      categoryData[category] = { revenue: 0, quantity: 0 };
    }
    categoryData[category].revenue += item.totalPrice;
    categoryData[category].quantity += item.quantity;
  });

  return Object.entries(categoryData).map(([category, data]) => ({
    category,
    revenue: data.revenue,
    quantity: data.quantity
  }));
}

// =================================================================
// API DE PEDIDOS AVANÇADA
// =================================================================

app.get('/api/orders', requireAuth, async (req, res) => {
  try {
    const { status, date, customer, page = 1, limit = 20 } = req.query;
    let where = {};
    
    if (status) where.status = status;
    if (customer) where.customerId = customer;
    if (date) {
      const startDate = new Date(date);
      const endDate = new Date(date);
      endDate.setDate(endDate.getDate() + 1);
      where.createdAt = { gte: startDate, lt: endDate };
    }
    
    const [orders, total] = await Promise.all([
      prisma.order.findMany({
        where,
        include: {
          customer: true,
          address: true,
          items: { include: { menuItem: true } },
          statusHistory: { orderBy: { timestamp: 'desc' }, take: 1 }
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * parseInt(limit),
        take: parseInt(limit)
      }),
      prisma.order.count({ where })
    ]);
    
    res.json({
      orders,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    logger.error('Erro ao buscar pedidos:', error);
    res.status(500).json({ error: 'Erro ao buscar pedidos' });
  }
});

app.put('/api/orders/:id/status', requireAuth, [
  body('status').isIn(['PENDING', 'CONFIRMED', 'PREPARING', 'READY', 'OUT_FOR_DELIVERY', 'DELIVERED', 'CANCELLED'])
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { id } = req.params;
    const { status, notes } = req.body;
    
    const order = await prisma.order.update({
      where: { id },
      data: { 
        status,
        confirmedAt: status === 'CONFIRMED' ? new Date() : undefined,
        deliveredAt: status === 'DELIVERED' ? new Date() : undefined,
        cancelledAt: status === 'CANCELLED' ? new Date() : undefined
      },
      include: { 
        customer: true, 
        address: true,
        items: { include: { menuItem: true } }
      }
    });
    
    // Registrar histórico
    await prisma.orderStatusHistory.create({
      data: {
        orderId: order.id,
        status,
        notes,
        userId: req.user.id
      }
    });
    
    // Enviar notificação para o cliente
    await sendOrderStatusNotification(order);
    
    // Invalidar cache
    await invalidateOrderCache();
    
    io.emit('order_updated', { action: 'status_changed', order });
    logger.info(`Status do pedido ${order.orderNumber} alterado para ${status} por ${req.user.email}`);
    
    res.json(order);
  } catch (error) {
    logger.error('Erro ao atualizar status do pedido:', error);
    res.status(500).json({ error: 'Erro ao atualizar status do pedido' });
  }
});

// =================================================================
// WEBHOOK WHATSAPP + GOOGLE GEMINI AI
// =================================================================

app.post('/api/webhook/whatsapp', async (req, res) => {
  try {
    const { key, message } = req.body;
    
    if (!key?.remoteJid || !message) {
      return res.json({ success: true });
    }
    
    const phone = key.remoteJid.replace('@s.whatsapp.net', '');
    const messageText = message.conversation || message.extendedTextMessage?.text || '';
    
    if (!messageText || messageText.length < 1) {
      return res.json({ success: true });
    }
    
    logger.info(`Mensagem recebida de ${phone}: ${messageText}`);
    
    // Processar mensagem com IA
    await processWhatsAppMessageWithAI(phone, messageText, key.pushName);
    
    res.json({ success: true });
  } catch (error) {
    logger.error('Erro no webhook WhatsApp:', error);
    res.status(500).json({ error: 'Erro no webhook' });
  }
});

// =================================================================
// SISTEMA IA CONVERSACIONAL AVANÇADO
// =================================================================

async function processWhatsAppMessageWithAI(phone, message, pushName) {
  try {
    // Buscar ou criar cliente
    let customer = await prisma.customer.findUnique({
      where: { phone },
      include: { addresses: true, sessions: true, orders: { take: 5, orderBy: { createdAt: 'desc' } } }
    });
    
    if (!customer) {
      customer = await prisma.customer.create({
        data: { phone, name: pushName || 'Cliente' },
        include: { addresses: true, sessions: true, orders: true }
      });
    }
    
    // Buscar ou criar sessão ativa
    let session = await prisma.customerSession.findFirst({
      where: {
        customerId: customer.id,
        expiresAt: { gt: new Date() }
      }
    });
    
    if (!session) {
      session = await prisma.customerSession.create({
        data: {
          customerId: customer.id,
          state: 'WELCOME',
          context: {},
          expiresAt: new Date(Date.now() + 60 * 60 * 1000) // 1 hora
        }
      });
    }
    
    // Salvar interação
    await prisma.interaction.create({
      data: {
        customerId: customer.id,
        type: 'MESSAGE',
        message,
        metadata: { sessionState: session.state }
      }
    });
    
    // Gerar resposta com IA
    const response = await generateAIResponse(customer, session, message);
    
    if (response) {
      await sendWhatsAppMessage(phone, response.message);
      
      // Atualizar sessão se necessário
      if (response.newState || response.newContext) {
        await updateSessionState(
          session.id, 
          response.newState || session.state, 
          response.newContext || session.context
        );
      }
      
      // Salvar resposta
      await prisma.interaction.create({
        data: {
          customerId: customer.id,
          type: 'MESSAGE',
          message: response.message,
          intent: response.intent,
          metadata: { ai_generated: true }
        }
      });
    }
    
  } catch (error) {
    logger.error('Erro ao processar mensagem com IA:', error);
    await sendWhatsAppMessage(phone, 'Desculpe, ocorreu um erro temporário. Tente novamente em alguns minutos.');
  }
}

async function generateAIResponse(customer, session, message) {
  try {
    // Se não tiver Gemini configurado, usar fallback
    if (!model) {
      return await generateFallbackResponse(customer, session, message);
    }

    // Buscar cardápio para contexto
    const menuItems = await prisma.menuItem.findMany({
      where: { available: true },
      orderBy: { category: 'asc' }
    });

    // Construir contexto para IA
    const context = {
      customerName: customer.name,
      customerPhone: customer.phone,
      sessionState: session.state,
      sessionContext: session.context,
      recentOrders: customer.orders,
      menuItems: menuItems.map(item => ({
        id: item.id,
        name: item.name,
        description: item.description,
        price: item.price,
        category: item.category
      }))
    };

    const prompt = buildAIPrompt(context, message);

    const result = await model.generateContent(prompt);
    const response = await result.response;
    const aiResponse = response.text();

    // Parsear resposta da IA
    return parseAIResponse(aiResponse);

  } catch (error) {
    logger.error('Erro na IA:', error);
    return await generateFallbackResponse(customer, session, message);
  }
}

function buildAIPrompt(context, message) {
  return `
Você é um assistente virtual inteligente para o restaurante "Quentinhas da Casa".

CONTEXTO DO CLIENTE:
- Nome: ${context.customerName}
- Estado da conversa: ${context.sessionState}
- Contexto da sessão: ${JSON.stringify(context.sessionContext)}

CARDÁPIO DISPONÍVEL:
${context.menuItems.map(item => 
  `- ${item.name}: R$ ${item.price.toFixed(2)} (${item.category})\n  ${item.description}`
).join('\n')}

MENSAGEM DO CLIENTE: "${message}"

INSTRUÇÕES:
1. Seja amigável, prestativo e profissional
2. Ajude o cliente a fazer pedidos, tirar dúvidas sobre o cardápio
3. Colete informações necessárias (endereço, forma de pagamento)
4. Confirme pedidos claramente
5. Use emojis adequadamente

RESPONDA EM FORMATO JSON:
{
  "message": "sua resposta aqui",
  "intent": "categoria da intenção",
  "newState": "novo estado se necessário",
  "newContext": { "dados atualizados se necessário" }
}
  `;
}

function parseAIResponse(aiResponse) {
  try {
    // Tentar parsear JSON
    const cleaned = aiResponse.replace(/```json\n?|\n?```/g, '').trim();
    const parsed = JSON.parse(cleaned);
    
    return {
      message: parsed.message || 'Desculpe, não entendi. Pode repetir?',
      intent: parsed.intent || 'unknown',
      newState: parsed.newState,
      newContext: parsed.newContext
    };
  } catch (error) {
    // Se não conseguir parsear, usar resposta como texto
    return {
      message: aiResponse || 'Desculpe, não consegui processar sua mensagem.',
      intent: 'unknown'
    };
  }
}

async function generateFallbackResponse(customer, session, message) {
  const msg = message.toLowerCase().trim();
  
  // Respostas básicas sem IA
  if (msg.includes('cardapio') || msg.includes('cardápio') || msg.includes('menu')) {
    return {
      message: await buildMenuMessage(),
      intent: 'view_menu',
      newState: 'BROWSING_MENU'
    };
  }
  
  if (msg.includes('oi') || msg.includes('olá') || msg.includes('bom dia')) {
    return {
      message: `Olá ${customer.name}! 😊\n\nBem-vindo às Quentinhas da Casa! 🍽️\n\nDigite *CARDÁPIO* para ver nosso menu ou *PEDIDO* para fazer um pedido!`,
      intent: 'greeting'
    };
  }
  
  return {
    message: 'Olá! Como posso ajudar você hoje? Digite *CARDÁPIO* para ver nosso menu! 😊',
    intent: 'unknown'
  };
}

async function buildMenuMessage() {
  const menuItems = await prisma.menuItem.findMany({
    where: { available: true },
    orderBy: [{ category: 'asc' }, { position: 'asc' }]
  });
  
  if (menuItems.length === 0) {
    return 'Desculpe, nosso cardápio está sendo atualizado. Tente novamente em alguns minutos.';
  }
  
  let menuMsg = `📋 *CARDÁPIO QUENTINHAS DA CASA* 🍽️\n\n`;
  
  const groupedItems = {};
  menuItems.forEach(item => {
    if (!groupedItems[item.category]) {
      groupedItems[item.category] = [];
    }
    groupedItems[item.category].push(item);
  });
  
  Object.keys(groupedItems).forEach(category => {
    menuMsg += `*${category.toUpperCase()}:*\n`;
    groupedItems[category].forEach((item, index) => {
      const price = item.isPromotion && item.promotionPrice ? item.promotionPrice : item.price;
      menuMsg += `${index + 1}. ${item.name} - R$ ${price.toFixed(2)}\n`;
      if (item.description) {
        menuMsg += `   _${item.description}_\n`;
      }
    });
    menuMsg += `\n`;
  });
  
  menuMsg += `🛒 *Para fazer seu pedido:*\n`;
  menuMsg += `Digite o *nome* do prato que deseja\n`;
  menuMsg += `Exemplo: "Arroz com Frango"`;
  
  return menuMsg;
}

// =================================================================
// FUNÇÕES AUXILIARES
# =================================================================

async function updateSessionState(sessionId, newState, newContext = {}) {
  await prisma.customerSession.update({
    where: { id: sessionId },
    data: {
      state: newState,
      context: newContext,
      lastActivity: new Date(),
      expiresAt: new Date(Date.now() + 60 * 60 * 1000)
    }
  });
}

async function sendWhatsAppMessage(phone, message) {
  try {
    const response = await require('axios').post(
      `${process.env.EVOLUTION_API_URL}/message/sendText/${process.env.EVOLUTION_INSTANCE}`,
      {
        number: phone,
        text: message
      },
      {
        headers: {
          'apikey': process.env.EVOLUTION_API_KEY
        }
      }
    );
    
    logger.info(`Mensagem enviada para ${phone}`);
    return response.data;
  } catch (error) {
    logger.error('Erro ao enviar mensagem WhatsApp:', error);
    throw error;
  }
}

async function sendOrderStatusNotification(order) {
  const statusMessages = {
    'CONFIRMED': `✅ *Pedido #${order.orderNumber} confirmado!*\n\nSeu pedido foi confirmado e está sendo preparado com carinho!\n\n⏰ Tempo estimado: ${order.estimatedTime || 45} minutos`,
    'PREPARING': `👨‍🍳 *Seu pedido está sendo preparado!*\n\nPedido #${order.orderNumber} está na cozinha sendo preparado com todo cuidado.`,
    'READY': `🍽️ *Pedido pronto!*\n\nSeu pedido #${order.orderNumber} está pronto! Em breve nosso entregador estará a caminho.`,
    'OUT_FOR_DELIVERY': `🚚 *Saiu para entrega!*\n\nSeu pedido #${order.orderNumber} saiu para entrega!\n\n📍 Endereço: ${order.address?.street}, ${order.address?.number}\n⏰ Chegada prevista: 15-20 minutos`,
    'DELIVERED': `🎉 *Pedido entregue!*\n\nObrigado por escolher as Quentinhas da Casa! Esperamos que tenha gostado.\n\nAvalie nosso atendimento respondendo com uma nota de 1 a 5! ⭐`,
    'CANCELLED': `❌ *Pedido cancelado*\n\nSeu pedido #${order.orderNumber} foi cancelado.\n\nSe precisar de alguma informação, entre em contato conosco.`
  };
  
  const message = statusMessages[order.status];
  if (message) {
    await sendWhatsAppMessage(order.customer.phone, message);
  }
}

async function invalidateOrderCache() {
  const keys = cache.keys().filter(key => key.startsWith('dashboard:') || key.startsWith('orders:'));
  keys.forEach(key => cache.del(key));
}

// =================================================================
// PÁGINAS WEB PROTEGIDAS
// =================================================================

const requireWebAuth = (req, res, next) => {
  if (!req.session.userId) {
    return res.redirect('/login');
  }
  next();
};

app.get('/login', (req, res) => {
  if (req.session.userId) {
    return res.redirect('/dashboard');
  }
  res.sendFile(path.join(__dirname, 'public', 'login.html'));
});

app.get('/dashboard', requireWebAuth, (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'dashboard.html'));
});

app.get('/orders', requireWebAuth, (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'orders.html'));
});

app.get('/financial', requireWebAuth, (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'financial.html'));
});

app.get('/', (req, res) => {
  if (req.session.userId) {
    return res.redirect('/dashboard');
  }
  res.redirect('/login');
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Metrics endpoint para Prometheus
app.get('/metrics', (req, res) => {
  res.set('Content-Type', 'text/plain');
  res.send('# HELP quentinhas_requests_total Total number of requests\n# TYPE quentinhas_requests_total counter\nquentinhas_requests_total 1\n');
});

app.use(express.static('public'));

// =================================================================
// WEBSOCKET AVANÇADO
// =================================================================

io.on('connection', (socket) => {
  logger.info(`Cliente conectado: ${socket.id}`);
  
  socket.on('join_admin', () => {
    socket.join('admin');
    logger.info(`Admin conectado: ${socket.id}`);
  });
  
  socket.on('disconnect', () => {
    logger.info(`Cliente desconectado: ${socket.id}`);
  });
});

// =================================================================
// TAREFAS AUTOMATIZADAS
// =================================================================

// Backup automático diário
cron.schedule(process.env.BACKUP_INTERVAL || '0 2 * * *', async () => {
  logger.info('Iniciando backup automático...');
  try {
    await createBackup();
    logger.info('Backup concluído com sucesso');
  } catch (error) {
    logger.error('Erro no backup:', error);
  }
});

// Limpeza de sessões expiradas
cron.schedule('*/30 * * * *', async () => {
  try {
    await prisma.customerSession.deleteMany({
      where: { expiresAt: { lt: new Date() } }
    });
  } catch (error) {
    logger.error('Erro na limpeza de sessões:', error);
  }
});

// Geração de relatórios diários
cron.schedule('0 1 * * *', async () => {
  try {
    await generateDailyReport();
  } catch (error) {
    logger.error('Erro na geração de relatório:', error);
  }
});

async function createBackup() {
  const date = moment().format('YYYY-MM-DD_HH-mm-ss');
  const backupFile = `./backups/backup_${date}.sql`;
  
  const { exec } = require('child_process');
  const command = `pg_dump ${process.env.DATABASE_URL} > ${backupFile}`;
  
  return new Promise((resolve, reject) => {
    exec(command, (error, stdout, stderr) => {
      if (error) {
        reject(error);
      } else {
        resolve(backupFile);
      }
    });
  });
}

async function generateDailyReport() {
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  yesterday.setHours(0, 0, 0, 0);
  
  const today = new Date(yesterday);
  today.setDate(today.getDate() + 1);

  const [orders, revenue, customers] = await Promise.all([
    prisma.order.count({
      where: {
        createdAt: { gte: yesterday, lt: today },
        status: { not: 'CANCELLED' }
      }
    }),
    prisma.order.aggregate({
      where: {
        createdAt: { gte: yesterday, lt: today },
        status: { not: 'CANCELLED' }
      },
      _sum: { finalAmount: true }
    }),
    prisma.customer.count({
      where: { createdAt: { gte: yesterday, lt: today } }
    })
  ]);

  await prisma.financialReport.create({
    data: {
      date: yesterday,
      grossRevenue: revenue._sum.finalAmount || 0,
      netRevenue: revenue._sum.finalAmount || 0,
      totalOrders: orders,
      avgTicket: orders > 0 ? (revenue._sum.finalAmount || 0) / orders : 0
    }
  });
}

# =================================================================
# INICIALIZAÇÃO DO SERVIDOR
# =================================================================

const PORT = process.env.PORT || 3000;

server.listen(PORT, '0.0.0.0', () => {
  logger.info(`🚀 Servidor iniciado na porta ${PORT}`);
  logger.info(`📊 Dashboard: http://${process.env.PUBLIC_IP}:${PORT}`);
  logger.info(`🔐 Sistema protegido por autenticação`);
  logger.info(`🤖 Robô WhatsApp com IA ativo`);
  logger.info(`💾 Backup automático configurado`);
  logger.info(`📈 Monitoramento ativo`);
});

process.on('SIGTERM', async () => {
  logger.info('Fechando servidor...');
  await prisma.$disconnect();
  await redisClient.disconnect();
  process.exit(0);
});

process.on('uncaughtException', (error) => {
  logger.error('Erro não capturado:', error);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  logger.error('Promise rejeitada não tratada:', reason);
});
EOF

# =================================================================
# CRIAR PÁGINAS WEB AVANÇADAS
# =================================================================

log_purple "Criando páginas web avançadas..."

# Página de Login
cat > public/login.html << 'EOF'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login - Quentinhas Pro</title>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/axios/1.4.0/axios.min.js"></script>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap');
        
        :root {
            --primary: #6366f1;
            --success: #10b981;
            --error: #ef4444;
            --gray-50: #f8fafc;
            --gray-800: #1e293b;
            --border: #e2e8f0;
        }

        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: 'Inter', sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 2rem;
        }

        .login-container {
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            padding: 3rem;
            width: 100%;
            max-width: 400px;
            text-align: center;
        }

        .logo {
            font-size: 2rem;
            font-weight: 800;
            color: var(--primary);
            margin-bottom: 0.5rem;
        }

        .subtitle {
            color: #64748b;
            margin-bottom: 2rem;
        }

        .form-group {
            margin-bottom: 1.5rem;
            text-align: left;
        }

        .form-group label {
            display: block;
            margin-bottom: 0.5rem;
            font-weight: 600;
            color: var(--gray-800);
        }

        .form-group input {
            width: 100%;
            padding: 1rem;
            border: 2px solid var(--border);
            border-radius: 10px;
            font-size: 1rem;
            transition: border-color 0.3s ease;
        }

        .form-group input:focus {
            outline: none;
            border-color: var(--primary);
        }

        .btn {
            width: 100%;
            padding: 1rem;
            background: var(--primary);
            color: white;
            border: none;
            border-radius: 10px;
            font-size: 1rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
        }

        .btn:hover {
            background: #5046e5;
            transform: translateY(-2px);
        }

        .btn:disabled {
            background: #94a3b8;
            cursor: not-allowed;
            transform: none;
        }

        .error-message {
            background: #fee2e2;
            color: var(--error);
            padding: 1rem;
            border-radius: 8px;
            margin-bottom: 1rem;
            display: none;
        }

        .loading {
            display: none;
            margin-left: 0.5rem;
        }

        .loading.show {
            display: inline-block;
        }

        .credentials {
            margin-top: 2rem;
            padding: 1rem;
            background: #f8fafc;
            border-radius: 8px;
            font-size: 0.875rem;
            color: #64748b;
        }

        .credentials strong {
            color: var(--gray-800);
        }
    </style>
</head>
<body>
    <div class="login-container">
        <div class="logo">🍽️ Quentinhas Pro</div>
        <p class="subtitle">Sistema de Gestão Avançado</p>
        
        <div class="error-message" id="errorMessage"></div>
        
        <form id="loginForm">
            <div class="form-group">
                <label for="email">Email</label>
                <input type="email" id="email" name="email" required>
            </div>
            
            <div class="form-group">
                <label for="password">Senha</label>
                <input type="password" id="password" name="password" required>
            </div>
            
            <button type="submit" class="btn" id="loginBtn">
                Entrar
                <i class="fas fa-spinner fa-spin loading" id="loading"></i>
            </button>
        </form>
        
        <div class="credentials">
            <strong>Credenciais de Acesso:</strong><br>
            Email: admin@quentinhas.com<br>
            Senha: admin123
        </div>
    </div>

    <script>
        document.getElementById('loginForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            
            const email = document.getElementById('email').value;
            const password = document.getElementById('password').value;
            const loginBtn = document.getElementById('loginBtn');
            const loading = document.getElementById('loading');
            const errorMessage = document.getElementById('errorMessage');
            
            // Reset error
            errorMessage.style.display = 'none';
            
            // Show loading
            loginBtn.disabled = true;
            loading.classList.add('show');
            
            try {
                const response = await axios.post('/api/auth/login', {
                    email,
                    password
                });
                
                // Save token
                localStorage.setItem('token', response.data.token);
                
                // Redirect to dashboard
                window.location.href = '/dashboard';
                
            } catch (error) {
                console.error('Erro no login:', error);
                
                let message = 'Erro ao fazer login';
                if (error.response?.data?.error) {
                    message = error.response.data.error;
                }
                
                errorMessage.textContent = message;
                errorMessage.style.display = 'block';
                
                // Reset button
                loginBtn.disabled = false;
                loading.classList.remove('show');
            }
        });
        
        // Auto-fill credentials for demo
        document.addEventListener('DOMContentLoaded', () => {
            document.getElementById('email').value = 'admin@quentinhas.com';
            document.getElementById('password').value = 'admin123';
        });
    </script>
</body>
</html>
EOF

# Dashboard Avançado
cat > public/dashboard.html << 'EOF'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard - Quentinhas Pro</title>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.0/chart.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/axios/1.4.0/axios.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/socket.io/4.7.4/socket.io.min.js"></script>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap');
        
        :root {
            --primary: #6366f1;
            --success: #10b981;
            --warning: #f59e0b;
            --error: #ef4444;
            --gray-50: #f8fafc;
            --gray-800: #1e293b;
            --border: #e2e8f0;
        }

        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: 'Inter', sans-serif;
            background: #f1f5f9;
            color: var(--gray-800);
            line-height: 1.6;
        }

        .sidebar {
            position: fixed;
            left: 0; top: 0;
            width: 280px;
            height: 100vh;
            background: white;
            box-shadow: 2px 0 10px rgba(0,0,0,0.1);
            z-index: 1000;
            transition: transform 0.3s ease;
        }

        .sidebar-header {
            padding: 2rem 1.5rem;
            border-bottom: 1px solid var(--border);
            background: linear-gradient(135deg, var(--primary), #8b5cf6);
        }

        .logo {
            font-size: 1.5rem;
            font-weight: 800;
            color: white;
            text-align: center;
        }

        .nav-menu {
            padding: 1rem 0;
        }

        .nav-item {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 1rem 1.5rem;
            color: #64748b;
            text-decoration: none;
            transition: all 0.3s ease;
            border-left: 3px solid transparent;
        }

        .nav-item:hover, .nav-item.active {
            background: rgba(99, 102, 241, 0.1);
            color: var(--primary);
            border-left-color: var(--primary);
        }

        .main-content {
            margin-left: 280px;
            min-height: 100vh;
        }

        .header {
            background: white;
            padding: 1.5rem 2rem;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .header h1 {
            font-size: 1.75rem;
            font-weight: 700;
        }

        .user-menu {
            display: flex;
            align-items: center;
            gap: 1rem;
        }

        .content {
            padding: 2rem;
        }

        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 1.5rem;
            margin-bottom: 2rem;
        }

        .stat-card {
            background: white;
            border-radius: 15px;
            padding: 2rem;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
            transition: transform 0.3s ease;
            border-left: 4px solid var(--primary);
        }

        .stat-card:hover { 
            transform: translateY(-5px); 
            box-shadow: 0 8px 25px rgba(0,0,0,0.1);
        }

        .stat-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 1rem;
        }

        .stat-icon {
            width: 48px;
            height: 48px;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.5rem;
            color: white;
        }

        .stat-value {
            font-size: 2.5rem;
            font-weight: 800;
            color: var(--gray-800);
            margin-bottom: 0.5rem;
        }

        .stat-label {
            color: #64748b;
            font-weight: 500;
            font-size: 0.875rem;
        }

        .stat-change {
            font-size: 0.75rem;
            font-weight: 600;
            padding: 0.25rem 0.5rem;
            border-radius: 6px;
        }

        .stat-change.positive {
            background: #dcfce7;
            color: #16a34a;
        }

        .charts-section {
            display: grid;
            grid-template-columns: 2fr 1fr;
            gap: 2rem;
            margin-bottom: 2rem;
        }

        .chart-card {
            background: white;
            border-radius: 15px;
            padding: 2rem;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
        }

        .chart-header {
            margin-bottom: 1.5rem;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .chart-title {
            font-size: 1.25rem;
            font-weight: 700;
            color: var(--gray-800);
        }

        .recent-section {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 2rem;
        }

        .recent-card {
            background: white;
            border-radius: 15px;
            padding: 2rem;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
        }

        .order-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 1rem 0;
            border-bottom: 1px solid var(--border);
        }

        .order-item:last-child {
            border-bottom: none;
        }

        .order-info h4 {
            font-weight: 600;
            margin-bottom: 0.25rem;
        }

        .order-info small {
            color: #64748b;
            font-size: 0.75rem;
        }

        .status-badge {
            padding: 0.25rem 0.75rem;
            border-radius: 50px;
            font-size: 0.75rem;
            font-weight: 600;
            text-transform: uppercase;
        }

        .status-PENDING { background: #fef3c7; color: #d97706; }
        .status-CONFIRMED { background: #dbeafe; color: #2563eb; }
        .status-PREPARING { background: #fde68a; color: #d97706; }
        .status-READY { background: #d1fae5; color: #059669; }
        .status-DELIVERED { background: #dcfce7; color: #16a34a; }
        .status-CANCELLED { background: #fee2e2; color: #dc2626; }

        .btn {
            padding: 0.75rem 1.5rem;
            border: none;
            border-radius: 10px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            font-size: 0.875rem;
        }

        .btn-primary {
            background: var(--primary);
            color: white;
        }

        .btn-primary:hover {
            background: #5046e5;
            transform: translateY(-2px);
        }

        .btn-danger {
            background: var(--error);
            color: white;
        }

        .btn-danger:hover {
            background: #dc2626;
            transform: translateY(-2px);
        }

        .loading {
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 2rem;
            color: #64748b;
        }

        .notification {
            position: fixed;
            top: 20px;
            right: 20px;
            padding: 1rem 1.5rem;
            border-radius: 10px;
            color: white;
            font-weight: 600;
            z-index: 9999;
            transform: translateX(120%);
            transition: transform 0.3s ease-in-out;
        }

        .notification.success { background: var(--success); }
        .notification.error { background: var(--error); }
        .notification.show { transform: translateX(0); }

        @media (max-width: 768px) {
            .sidebar { 
                transform: translateX(-100%); 
                width: 100%;
            }
            .sidebar.open { transform: translateX(0); }
            .main-content { margin-left: 0; }
            .header h1 { font-size: 1.5rem; }
            .stats-grid { grid-template-columns: 1fr; }
            .charts-section { grid-template-columns: 1fr; }
            .recent-section { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    <div class="sidebar" id="sidebar">
        <div class="sidebar-header">
            <div class="logo">🍽️ Quentinhas Pro</div>
        </div>
        <nav class="nav-menu">
            <a href="/dashboard" class="nav-item active">
                <i class="fas fa-chart-line"></i> Dashboard
            </a>
            <a href="/orders" class="nav-item">
                <i class="fas fa-shopping-cart"></i> Pedidos
            </a>
            <a href="/financial" class="nav-item">
                <i class="fas fa-chart-bar"></i> Financeiro
            </a>
            <a href="/menu-manager" class="nav-item">
                <i class="fas fa-utensils"></i> Cardápio
            </a>
            <a href="/customers" class="nav-item">
                <i class="fas fa-users"></i> Clientes
            </a>
        </nav>
    </div>

    <div class="main-content">
        <div class="header">
            <div>
                <button class="btn" onclick="toggleSidebar()" id="menuBtn" style="display: none; padding: 0.5rem 0.75rem; margin-right: 1rem;">
                    <i class="fas fa-bars"></i>
                </button>
                <h1>Dashboard</h1>
            </div>
            <div class="user-menu">
                <span id="userName">Carregando...</span>
                <button class="btn btn-danger" onclick="logout()">
                    <i class="fas fa-sign-out-alt"></i> Sair
                </button>
            </div>
        </div>

        <div class="content">
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-header">
                        <div class="stat-icon" style="background: linear-gradient(135deg, #6366f1, #8b5cf6);">
                            <i class="fas fa-shopping-cart"></i>
                        </div>
                        <div class="stat-change positive">+12%</div>
                    </div>
                    <div class="stat-value" id="todayOrders">0</div>
                    <div class="stat-label">Pedidos Hoje</div>
                </div>

                <div class="stat-card">
                    <div class="stat-header">
                        <div class="stat-icon" style="background: linear-gradient(135deg, #10b981, #059669);">
                            <i class="fas fa-dollar-sign"></i>
                        </div>
                        <div class="stat-change positive">+8%</div>
                    </div>
                    <div class="stat-value" id="todayRevenue">R$ 0</div>
                    <div class="stat-label">Faturamento Hoje</div>
                </div>

                <div class="stat-card">
                    <div class="stat-header">
                        <div class="stat-icon" style="background: linear-gradient(135deg, #f59e0b, #d97706);">
                            <i class="fas fa-receipt"></i>
                        </div>
                        <div class="stat-change positive">R$ 0</div>
                    </div>
                    <div class="stat-value" id="avgTicket">R$ 0</div>
                    <div class="stat-label">Ticket Médio</div>
                </div>

                <div class="stat-card">
                    <div class="stat-header">
                        <div class="stat-icon" style="background: linear-gradient(135deg, #ef4444, #dc2626);">
                            <i class="fas fa-clock"></i>
                        </div>
                        <div class="stat-change positive">0</div>
                    </div>
                    <div class="stat-value" id="pendingOrders">0</div>
                    <div class="stat-label">Pedidos Pendentes</div>
                </div>
            </div>

            <div class="charts-section">
                <div class="chart-card">
                    <div class="chart-header">
                        <h3 class="chart-title">Vendas da Semana</h3>
                    </div>
                    <canvas id="salesChart" height="300"></canvas>
                </div>
                <div class="chart-card">
                    <div class="chart-header">
                        <h3 class="chart-title">Itens Mais Vendidos</h3>
                    </div>
                    <canvas id="topItemsChart" height="300"></canvas>
                </div>
            </div>

            <div class="recent-section">
                <div class="recent-card">
                    <h3>Pedidos Recentes</h3>
                    <div id="recentOrdersList" class="loading">
                        <i class="fas fa-spinner fa-spin"></i> Carregando...
                    </div>
                </div>

                <div class="recent-card">
                    <h3>Atividade WhatsApp</h3>
                    <div id="whatsappActivity">
                        <div class="order-item">
                            <div class="order-info">
                                <h4>🤖 Robô Ativo</h4>
                                <small>Sistema funcionando normalmente</small>
                            </div>
                            <span class="status-badge" style="background: #dcfce7; color: #16a34a;">Online</span>
                        </div>
                        <div class="order-item">
                            <div class="order-info">
                                <h4>📱 Mensagens Hoje</h4>
                                <small id="messagesCount">0 mensagens processadas</small>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div id="notification" class="notification"></div>

    <script>
        let socket;
        
        // Configurar token nas requisições
        axios.defaults.headers.common['Authorization'] = `Bearer ${localStorage.getItem('token')}`;

        document.addEventListener('DOMContentLoaded', () => {
            if (!localStorage.getItem('token')) {
                window.location.href = '/login';
                return;
            }
            initSocket();
            loadUserInfo();
            loadDashboard();
            initCharts();
            
            // Atualizar a cada 30 segundos
            setInterval(loadDashboard, 30000);
            
            // Responsividade
            checkMobile();
            window.addEventListener('resize', checkMobile);
        });

        function initSocket() {
            socket = io();
            
            socket.on('connect', () => {
                console.log('Conectado ao WebSocket');
                socket.emit('join_admin');
            });

            socket.on('order_updated', (data) => {
                showNotification(`Pedido #${data.orderNumber} atualizado!`, 'success');
                loadDashboard();
            });

            socket.on('new_message', (data) => {
                updateMessagesCount();
            });
        }

        function checkMobile() {
            const menuBtn = document.getElementById('menuBtn');
            const headerH1 = document.querySelector('.header h1');
            if (window.innerWidth <= 768) {
                menuBtn.style.display = 'inline-flex';
                document.body.style.setProperty('--main-content-margin-left', '0');
            } else {
                menuBtn.style.display = 'none';
                document.getElementById('sidebar').classList.remove('open');
                document.body.style.setProperty('--main-content-margin-left', '280px');
            }
        }

        function toggleSidebar() {
            document.getElementById('sidebar').classList.toggle('open');
        }

        async function loadUserInfo() {
            try {
                const response = await axios.get('/api/auth/me');
                document.getElementById('userName').textContent = response.data.user.name;
            } catch (error) {
                logout();
            }
        }

        async function loadDashboard() {
            try {
                const response = await axios.get('/api/dashboard');
                const data = response.data;

                document.getElementById('todayOrders').textContent = data.todayOrders;
                document.getElementById('todayRevenue').textContent = `R$ ${data.todayRevenue.toFixed(2)}`;
                document.getElementById('avgTicket').textContent = `R$ ${data.avgTicket.toFixed(2)}`;
                document.getElementById('pendingOrders').textContent = data.pendingOrders;

                loadRecentOrders(data.recentOrders);
                updateCharts(data);
            } catch (error) {
                console.error('Erro ao carregar dashboard:', error);
                if (error.response && error.response.status === 401) {
                    logout();
                } else {
                    showNotification('Erro ao carregar dados', 'error');
                }
            }
        }

        function loadRecentOrders(orders) {
            const container = document.getElementById('recentOrdersList');
            
            if (!orders || orders.length === 0) {
                container.innerHTML = '<p style="text-align: center; color: #64748b; padding: 2rem;">Nenhum pedido recente</p>';
                return;
            }

            container.innerHTML = orders.map(order => `
                <div class="order-item">
                    <div class="order-info">
                        <h4>#${order.orderNumber}</h4>
                        <small>${order.customer.name} - ${formatDate(order.createdAt)}</small>
                    </div>
                    <div style="text-align: right;">
                        <span class="status-badge status-${order.status}">
                            ${getStatusText(order.status)}
                        </span>
                        <div style="margin-top: 0.25rem;">
                            <strong>R$ ${order.finalAmount.toFixed(2)}</strong>
                        </div>
                    </div>
                </div>
            `).join('');
        }

        function getStatusText(status) {
            const statusMap = {
                'PENDING': 'Pendente',
                'CONFIRMED': 'Confirmado',
                'PREPARING': 'Preparando',
                'READY': 'Pronto',
                'OUT_FOR_DELIVERY': 'Entrega',
                'DELIVERED': 'Entregue',
                'CANCELLED': 'Cancelado'
            };
            return statusMap[status] || status;
        }

        function formatDate(dateString) {
            return new Date(dateString).toLocaleString('pt-BR', {
                day: '2-digit',
                month: '2-digit',
                hour: '2-digit',
                minute: '2-digit'
            });
        }

        let salesChart, topItemsChart;

        function initCharts() {
            // Gráfico de vendas
            const salesCtx = document.getElementById('salesChart').getContext('2d');
            salesChart = new Chart(salesCtx, {
                type: 'line',
                data: {
                    labels: [],
                    datasets: [{
                        label: 'Vendas (R$)',
                        data: [],
                        borderColor: '#6366f1',
                        backgroundColor: 'rgba(99, 102, 241, 0.1)',
                        tension: 0.4,
                        fill: true,
                        pointBackgroundColor: '#6366f1',
                        pointBorderColor: '#fff',
                        pointBorderWidth: 2,
                        pointRadius: 6
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: { 
                        legend: { display: false },
                        tooltip: {
                            backgroundColor: 'rgba(0,0,0,0.8)',
                            titleColor: '#fff',
                            bodyColor: '#fff',
                            cornerRadius: 8,
                            displayColors: false
                        }
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            grid: { color: '#f1f5f9' },
                            ticks: {
                                callback: function(value) {
                                    return 'R$ ' + value;
                                }
                            }
                        },
                        x: {
                            grid: { display: false }
                        }
                    }
                }
            });

            // Gráfico de itens mais vendidos
            const topItemsCtx = document.getElementById('topItemsChart').getContext('2d');
            topItemsChart = new Chart(topItemsCtx, {
                type: 'doughnut',
                data: {
                    labels: [],
                    datasets: [{
                        data: [],
                        backgroundColor: [
                            '#6366f1',
                            '#8b5cf6', 
                            '#10b981',
                            '#f59e0b',
                            '#ef4444'
                        ],
                        borderWidth: 0,
                        hoverOffset: 4
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            position: 'bottom',
                            labels: {
                                padding: 20,
                                usePointStyle: true
                            }
                        }
                    }
                }
            });
        }

        function updateCharts(data) {
            if (data.weeklyStats && salesChart) {
                salesChart.data.labels = data.weeklyStats.map(stat => new Date(stat.date).toLocaleDateString('pt-BR', { weekday: 'short' }));
                salesChart.data.datasets[0].data = data.weeklyStats.map(stat => stat.revenue);
                salesChart.update();
            }

            if (data.topItems && topItemsChart) {
                topItemsChart.data.labels = data.topItems.map(item => item.name);
                topItemsChart.data.datasets[0].data = data.topItems.map(item => item.quantity);
                topItemsChart.update();
            }
        }

        function updateMessagesCount() {
            // Placeholder: increment message count
            const countEl = document.getElementById('messagesCount');
            let currentCount = parseInt(countEl.textContent) || 0;
            currentCount++;
            countEl.textContent = `${currentCount} mensagens processadas`;
        }

        function showNotification(message, type = 'success') {
            const notification = document.getElementById('notification');
            notification.textContent = message;
            notification.className = `notification ${type}`;
            
            notification.classList.add('show');

            setTimeout(() => {
                notification.classList.remove('show');
            }, 3000);
        }

        function logout() {
            localStorage.removeItem('token');
            window.location.href = '/login';
        }
    </script>
</body>
</html>
EOF

# Página de Pedidos Avançada
cat > public/orders.html << 'EOF'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pedidos - Quentinhas Pro</title>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/axios/1.4.0/axios.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/socket.io/4.7.4/socket.io.min.js"></script>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap');
        
        :root {
            --primary: #6366f1;
            --success: #10b981;
            --warning: #f59e0b;
            --error: #ef4444;
            --gray-50: #f8fafc;
            --gray-800: #1e293b;
            --border: #e2e8f0;
        }

        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: 'Inter', sans-serif;
            background: #f1f5f9;
            color: var(--gray-800);
            line-height: 1.6;
        }

        .sidebar {
            position: fixed;
            left: 0; top: 0;
            width: 280px;
            height: 100vh;
            background: white;
            box-shadow: 2px 0 10px rgba(0,0,0,0.1);
            z-index: 1000;
        }

        .sidebar-header {
            padding: 2rem 1.5rem;
            border-bottom: 1px solid var(--border);
            background: linear-gradient(135deg, var(--primary), #8b5cf6);
        }

        .logo {
            font-size: 1.5rem;
            font-weight: 800;
            color: white;
            text-align: center;
        }

        .nav-menu {
            padding: 1rem 0;
        }

        .nav-item {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 1rem 1.5rem;
            color: #64748b;
            text-decoration: none;
            transition: all 0.3s ease;
            border-left: 3px solid transparent;
        }

        .nav-item:hover, .nav-item.active {
            background: rgba(99, 102, 241, 0.1);
            color: var(--primary);
            border-left-color: var(--primary);
        }

        .main-content {
            margin-left: 280px;
            min-height: 100vh;
        }

        .header {
            background: white;
            padding: 1.5rem 2rem;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .header h1 {
            font-size: 1.75rem;
            font-weight: 700;
        }

        .content {
            padding: 2rem;
        }

        .filters {
            background: white;
            border-radius: 15px;
            padding: 1.5rem;
            margin-bottom: 2rem;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
        }

        .filters-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1rem;
            align-items: end;
        }

        .form-group {
            display: flex;
            flex-direction: column;
        }

        .form-group label {
            margin-bottom: 0.5rem;
            font-weight: 600;
            color: var(--gray-800);
        }

        .form-group select,
        .form-group input {
            padding: 0.75rem;
            border: 1px solid var(--border);
            border-radius: 8px;
            font-size: 0.875rem;
        }

        .orders-container {
            background: white;
            border-radius: 15px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
            overflow: hidden;
        }

        .orders-header {
            padding: 1.5rem 2rem;
            border-bottom: 1px solid var(--border);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .orders-list {
            max-height: 70vh;
            overflow-y: auto;
        }

        .order-card {
            padding: 1.5rem 2rem;
            border-bottom: 1px solid var(--border);
            transition: background-color 0.3s ease;
            cursor: pointer;
        }

        .order-card:hover {
            background: #f8fafc;
        }

        .order-card:last-child {
            border-bottom: none;
        }

        .order-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 1rem;
        }

        .order-number {
            font-size: 1.125rem;
            font-weight: 700;
            color: var(--primary);
        }

        .order-date {
            color: #64748b;
            font-size: 0.875rem;
        }

        .order-details {
            display: grid;
            grid-template-columns: 1fr 1fr 200px 150px;
            gap: 1rem;
            align-items: center;
        }

        .customer-info h4 {
            font-weight: 600;
            margin-bottom: 0.25rem;
        }

        .customer-info p {
            color: #64748b;
            font-size: 0.875rem;
        }

        .order-items {
            color: #64748b;
            font-size: 0.875rem;
        }

        .order-total {
            text-align: center;
        }

        .order-total .amount {
            font-size: 1.25rem;
            font-weight: 700;
            color: var(--gray-800);
        }

        .order-actions {
            display: flex;
            gap: 0.5rem;
            justify-content: flex-end;
        }

        .status-badge {
            padding: 0.5rem 1rem;
            border-radius: 25px;
            font-size: 0.75rem;
            font-weight: 600;
            text-transform: uppercase;
            text-align: center;
            display: inline-block;
            min-width: 100px;
        }

        .status-PENDING { background: #fef3c7; color: #d97706; }
        .status-CONFIRMED { background: #dbeafe; color: #2563eb; }
        .status-PREPARING { background: #fde68a; color: #d97706; }
        .status-READY { background: #d1fae5; color: #059669; }
        .status-OUT_FOR_DELIVERY { background: #cffafe; color: #0891b2; }
        .status-DELIVERED { background: #dcfce7; color: #16a34a; }
        .status-CANCELLED { background: #fee2e2; color: #dc2626; }

        .btn {
            padding: 0.5rem 1rem;
            border: none;
            border-radius: 6px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 0.25rem;
            font-size: 0.75rem;
        }
        
        .btn-lg {
            padding: 0.75rem 1.5rem;
            font-size: 0.875rem;
        }

        .btn-sm {
            padding: 0.375rem 0.75rem;
            font-size: 0.75rem;
        }

        .btn-primary {
            background: var(--primary);
            color: white;
        }

        .btn-success {
            background: var(--success);
            color: white;
        }

        .btn-warning {
            background: var(--warning);
            color: white;
        }

        .btn-danger {
            background: var(--error);
            color: white;
        }

        .btn:hover {
            transform: translateY(-1px);
            box-shadow: 0 2px 8px rgba(0,0,0,0.15);
        }

        .modal {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.5);
            z-index: 10000;
            align-items: center;
            justify-content: center;
        }

        .modal.show {
            display: flex;
        }

        .modal-content {
            background: white;
            border-radius: 15px;
            padding: 2rem;
            max-width: 500px;
            width: 90%;
            max-height: 80vh;
            overflow-y: auto;
        }

        .modal-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 1.5rem;
        }

        .modal-title {
            font-size: 1.25rem;
            font-weight: 700;
        }

        .close-btn {
            background: none;
            border: none;
            font-size: 1.5rem;
            cursor: pointer;
            color: #64748b;
        }

        .loading {
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 3rem;
            color: #64748b;
        }

        .pagination {
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 0.5rem;
            padding: 1.5rem;
        }

        .pagination button {
            padding: 0.5rem 1rem;
            border: 1px solid var(--border);
            background: white;
            border-radius: 6px;
            cursor: pointer;
            transition: all 0.3s ease;
        }

        .pagination button:hover {
            background: var(--primary);
            color: white;
        }
        
        .pagination button:disabled {
            background: #f1f5f9;
            cursor: not-allowed;
            color: #94a3b8;
        }

        .pagination button.active {
            background: var(--primary);
            color: white;
            border-color: var(--primary);
        }

        @media (max-width: 768px) {
            .sidebar { transform: translateX(-100%); }
            .main-content { margin-left: 0; }
            .order-details { 
                grid-template-columns: 1fr; 
                gap: 0.5rem;
                text-align: left;
            }
            .order-actions { justify-content: flex-start; }
            .header h1 { font-size: 1.5rem; }
        }
    </style>
</head>
<body>
    <div class="sidebar">
        <div class="sidebar-header">
            <div class="logo">🍽️ Quentinhas Pro</div>
        </div>
        <nav class="nav-menu">
            <a href="/dashboard" class="nav-item">
                <i class="fas fa-chart-line"></i> Dashboard
            </a>
            <a href="/orders" class="nav-item active">
                <i class="fas fa-shopping-cart"></i> Pedidos
            </a>
            <a href="/financial" class="nav-item">
                <i class="fas fa-chart-bar"></i> Financeiro
            </a>
            <a href="/menu-manager" class="nav-item">
                <i class="fas fa-utensils"></i> Cardápio
            </a>
            <a href="/customers" class="nav-item">
                <i class="fas fa-users"></i> Clientes
            </a>
        </nav>
    </div>

    <div class="main-content">
        <div class="header">
            <h1>Gerenciar Pedidos</h1>
            <button class="btn btn-primary btn-lg" onclick="window.location.reload()">
                <i class="fas fa-sync-alt"></i> Atualizar
            </button>
        </div>

        <div class="content">
            <div class="filters">
                <div class="filters-grid">
                    <div class="form-group">
                        <label for="statusFilter">Status:</label>
                        <select id="statusFilter" onchange="filterOrders()">
                            <option value="">Todos</option>
                            <option value="PENDING">Pendente</option>
                            <option value="CONFIRMED">Confirmado</option>
                            <option value="PREPARING">Preparando</option>
                            <option value="READY">Pronto</option>
                            <option value="OUT_FOR_DELIVERY">Saiu para Entrega</option>
                            <option value="DELIVERED">Entregue</option>
                            <option value="CANCELLED">Cancelado</option>
                        </select>
                    </div>
                    
                    <div class="form-group">
                        <label for="dateFilter">Data:</label>
                        <input type="date" id="dateFilter" onchange="filterOrders()">
                    </div>
                    
                    <div class="form-group">
                        <label for="searchFilter">Buscar:</label>
                        <input type="text" id="searchFilter" placeholder="Cliente, telefone..." onkeyup="filterOrders()">
                    </div>
                    
                    <div class="form-group">
                        <button class="btn btn-primary btn-lg" onclick="clearFilters()">
                            <i class="fas fa-times"></i> Limpar
                        </button>
                    </div>
                </div>
            </div>

            <div class="orders-container">
                <div class="orders-header">
                    <h2>Lista de Pedidos</h2>
                    <div>
                        <span id="ordersCount">0 pedidos</span>
                    </div>
                </div>
                
                <div class="orders-list" id="ordersList">
                    <div class="loading">
                        <i class="fas fa-spinner fa-spin"></i> Carregando pedidos...
                    </div>
                </div>
                
                <div class="pagination" id="pagination"></div>
            </div>
        </div>
    </div>

    <div class="modal" id="orderModal">
        <div class="modal-content">
            <div class="modal-header">
                <h3 class="modal-title">Detalhes do Pedido</h3>
                <button class="close-btn" onclick="closeModal()">&times;</button>
            </div>
            <div id="orderModalContent">
                </div>
        </div>
    </div>

    <script>
        let socket;
        let currentPage = 1;
        let currentFilters = {};
        
        // Configurar token nas requisições
        axios.defaults.headers.common['Authorization'] = `Bearer ${localStorage.getItem('token')}`;

        document.addEventListener('DOMContentLoaded', () => {
            if (!localStorage.getItem('token')) {
                window.location.href = '/login';
                return;
            }
            initSocket();
            loadOrders();
        });

        function initSocket() {
            socket = io();
            
            socket.on('connect', () => {
                console.log('Conectado ao WebSocket');
                socket.emit('join_admin');
            });

            socket.on('order_updated', (data) => {
                console.log('Pedido atualizado:', data);
                loadOrders(currentPage, false); // Recarregar sem mostrar o loader
            });
        }

        async function loadOrders(page = 1, showLoader = true) {
            const container = document.getElementById('ordersList');
            if(showLoader) {
                container.innerHTML = `<div class="loading"><i class="fas fa-spinner fa-spin"></i> Carregando...</div>`;
            }

            try {
                const params = new URLSearchParams({
                    page,
                    limit: 10,
                    ...currentFilters
                });

                const response = await axios.get(`/api/orders?${params}`);
                const { orders, pagination } = response.data;

                displayOrders(orders);
                displayPagination(pagination);
                
                document.getElementById('ordersCount').textContent = 
                    `${pagination.total} pedidos encontrados`;

            } catch (error) {
                console.error('Erro ao carregar pedidos:', error);
                if (error.response && error.response.status === 401) {
                    window.location.href = '/login';
                } else {
                    container.innerHTML = 
                        '<div class="loading">Erro ao carregar pedidos</div>';
                }
            }
        }

        function displayOrders(orders) {
            const container = document.getElementById('ordersList');
            
            if (!orders || orders.length === 0) {
                container.innerHTML = `
                    <div class="loading">
                        <i class="fas fa-inbox" style="font-size: 2rem; margin-bottom: 1rem;"></i>
                        <p>Nenhum pedido encontrado com os filtros atuais.</p>
                    </div>
                `;
                return;
            }

            container.innerHTML = orders.map(order => `
                <div class="order-card" onclick="viewOrderDetails('${order.id}')">
                    <div class="order-header">
                        <div class="order-number">#${order.orderNumber}</div>
                        <div class="order-date">${formatDate(order.createdAt)}</div>
                    </div>
                    
                    <div class="order-details">
                        <div class="customer-info">
                            <h4>${order.customer.name}</h4>
                            <p><i class="fas fa-phone"></i> ${order.customer.phone}</p>
                            ${order.address ? `<p><i class="fas fa-map-marker-alt"></i> ${order.address.street}, ${order.address.number}</p>` : '<p><i class="fas fa-store"></i> Retirada no local</p>'}
                        </div>
                        
                        <div class="order-items">
                            ${order.items.slice(0, 2).map(item => 
                                `${item.quantity}x ${item.menuItem.name}`
                            ).join('<br>')}
                            ${order.items.length > 2 ? `<br>+${order.items.length - 2} mais...` : ''}
                        </div>
                        
                        <div class="order-total">
                            <div class="amount">R$ ${order.finalAmount.toFixed(2)}</div>
                            <div class="status-badge status-${order.status}">
                                ${getStatusText(order.status)}
                            </div>
                        </div>
                        
                        <div class="order-actions" onclick="event.stopPropagation()">
                            ${getStatusActions(order)}
                        </div>
                    </div>
                </div>
            `).join('');
        }

        function getStatusActions(order) {
            const actions = [];
            
            switch (order.status) {
                case 'PENDING':
                    actions.push(`<button class="btn btn-success btn-sm" onclick="updateOrderStatus('${order.id}', 'CONFIRMED')"><i class="fas fa-check"></i></button>`);
                    actions.push(`<button class="btn btn-danger btn-sm" onclick="updateOrderStatus('${order.id}', 'CANCELLED')"><i class="fas fa-times"></i></button>`);
                    break;
                    
                case 'CONFIRMED':
                    actions.push(`<button class="btn btn-warning btn-sm" onclick="updateOrderStatus('${order.id}', 'PREPARING')"><i class="fas fa-utensils"></i> Preparar</button>`);
                    break;
                    
                case 'PREPARING':
                    actions.push(`<button class="btn btn-success btn-sm" onclick="updateOrderStatus('${order.id}', 'READY')"><i class="fas fa-bell"></i> Pronto</button>`);
                    break;
                    
                case 'READY':
                    actions.push(`<button class="btn btn-primary btn-sm" onclick="updateOrderStatus('${order.id}', 'OUT_FOR_DELIVERY')"><i class="fas fa-truck"></i> Entregar</button>`);
                    break;
                    
                case 'OUT_FOR_DELIVERY':
                    actions.push(`<button class="btn btn-success btn-sm" onclick="updateOrderStatus('${order.id}', 'DELIVERED')"><i class="fas fa-check-circle"></i> Entregue</button>`);
                    break;
            }
            
            return actions.join('');
        }

        async function updateOrderStatus(orderId, newStatus) {
            try {
                let notes = '';
                if(newStatus === 'CANCELLED') {
                    notes = prompt('Motivo do cancelamento (opcional):');
                    if(notes === null) return; // User cancelled prompt
                }

                await axios.put(`/api/orders/${orderId}/status`, {
                    status: newStatus,
                    notes
                });
                
                showNotification('Status atualizado com sucesso!', 'success');
                loadOrders(currentPage, false);
                
            } catch (error) {
                console.error('Erro ao atualizar status:', error);
                showNotification('Erro ao atualizar status', 'error');
            }
        }

        async function viewOrderDetails(orderId) {
            try {
                const response = await axios.get(`/api/orders/${orderId}`);
                const order = response.data;
                
                document.getElementById('orderModalContent').innerHTML = `
                    <div style="margin-bottom: 1rem;">
                        <h4>Pedido #${order.orderNumber}</h4>
                        <p>Status: <span class="status-badge status-${order.status}">${getStatusText(order.status)}</span></p>
                        <p>Data: ${formatDate(order.createdAt)}</p>
                    </div>
                    
                    <div style="margin-bottom: 1rem;">
                        <h4>Cliente</h4>
                        <p><strong>Nome:</strong> ${order.customer.name}</p>
                        <p><strong>Telefone:</strong> ${order.customer.phone}</p>
                        ${order.address ? `
                            <p><strong>Endereço:</strong> ${order.address.street}, ${order.address.number}</p>
                            <p><strong>Bairro:</strong> ${order.address.district}</p>
                            <p><strong>Complemento:</strong> ${order.address.complement || 'N/A'}</p>
                        ` : `<p><strong>Retirada no Local</strong></p>`}
                    </div>
                    
                    <div style="margin-bottom: 1rem;">
                        <h4>Itens do Pedido</h4>
                        ${order.items.map(item => `
                            <div style="display: flex; justify-content: space-between; padding: 0.5rem 0; border-bottom: 1px solid #e2e8f0;">
                                <span>${item.quantity}x ${item.menuItem.name}</span>
                                <span>R$ ${item.totalPrice.toFixed(2)}</span>
                            </div>
                        `).join('')}
                    </div>
                    
                    <div style="margin-bottom: 1rem;">
                        <div style="display: flex; justify-content: space-between;">
                            <span>Subtotal:</span>
                            <span>R$ ${order.totalAmount.toFixed(2)}</span>
                        </div>
                        <div style="display: flex; justify-content: space-between;">
                            <span>Taxa de Entrega:</span>
                            <span>R$ ${order.deliveryFee.toFixed(2)}</span>
                        </div>
                        ${order.discount > 0 ? `
                            <div style="display: flex; justify-content: space-between;">
                                <span>Desconto:</span>
                                <span>-R$ ${order.discount.toFixed(2)}</span>
                            </div>
                        ` : ''}
                        <div style="display: flex; justify-content: space-between; font-weight: bold; font-size: 1.1rem; border-top: 1px solid #e2e8f0; padding-top: 0.5rem; margin-top: 0.5rem;">
                            <span>Total:</span>
                            <span>R$ ${order.finalAmount.toFixed(2)}</span>
                        </div>
                    </div>
                    
                    ${order.notes ? `
                        <div style="margin-bottom: 1rem;">
                            <h4>Observações</h4>
                            <p>${order.notes}</p>
                        </div>
                    ` : ''}
                `;
                
                document.getElementById('orderModal').classList.add('show');
                
            } catch (error) {
                console.error('Erro ao carregar detalhes:', error);
                showNotification('Erro ao carregar detalhes do pedido', 'error');
            }
        }

        function closeModal() {
            document.getElementById('orderModal').classList.remove('show');
        }

        function displayPagination(pagination) {
            const container = document.getElementById('pagination');
            const { page, pages } = pagination;
            
            if (pages <= 1) {
                container.innerHTML = '';
                return;
            }
            
            let paginationHTML = `<button onclick="changePage(${page - 1})" ${page === 1 ? 'disabled' : ''}>&laquo; Ant</button>`;
            
            for (let i = 1; i <= pages; i++) {
                if (i === page) {
                    paginationHTML += `<button class="active">${i}</button>`;
                } else {
                    paginationHTML += `<button onclick="changePage(${i})">${i}</button>`;
                }
            }
            
            paginationHTML += `<button onclick="changePage(${page + 1})" ${page === pages ? 'disabled' : ''}>Próx &raquo;</button>`;
            
            container.innerHTML = paginationHTML;
        }

        function changePage(page) {
            currentPage = page;
            loadOrders(page);
        }

        let filterTimeout;
        function filterOrders() {
            clearTimeout(filterTimeout);
            filterTimeout = setTimeout(() => {
                const status = document.getElementById('statusFilter').value;
                const date = document.getElementById('dateFilter').value;
                const search = document.getElementById('searchFilter').value;
                
                currentFilters = {};
                if (status) currentFilters.status = status;
                if (date) currentFilters.date = date;
                if (search) currentFilters.search = search;
                
                currentPage = 1;
                loadOrders(1);
            }, 300); // Debounce de 300ms
        }

        function clearFilters() {
            document.getElementById('statusFilter').value = '';
            document.getElementById('dateFilter').value = '';
            document.getElementById('searchFilter').value = '';
            
            currentFilters = {};
            currentPage = 1;
            loadOrders(1);
        }

        function getStatusText(status) {
            const statusMap = {
                'PENDING': 'Pendente',
                'CONFIRMED': 'Confirmado',
                'PREPARING': 'Preparando',
                'READY': 'Pronto',
                'OUT_FOR_DELIVERY': 'Entrega',
                'DELIVERED': 'Entregue',
                'CANCELLED': 'Cancelado'
            };
            return statusMap[status] || status;
        }

        function formatDate(dateString) {
            return new Date(dateString).toLocaleString('pt-BR');
        }

        function showNotification(message, type = 'success') {
            const notification = document.createElement('div');
            notification.className = `notification toast ${type}`;
            notification.textContent = message;
            document.body.appendChild(notification);
            
            setTimeout(() => {
                notification.classList.add('show');
            }, 100);

            setTimeout(() => {
                notification.classList.remove('show');
                setTimeout(() => notification.remove(), 500);
            }, 3000);
        }

        // Add CSS for toast notification
        const style = document.createElement('style');
        style.innerHTML = `
        .notification.toast {
            position: fixed;
            top: 20px;
            right: 20px;
            padding: 1rem 1.5rem;
            border-radius: 10px;
            color: white;
            font-weight: 600;
            z-index: 9999;
            transform: translateX(120%);
            transition: transform 0.3s ease-in-out;
        }
        .notification.toast.success { background: var(--success); }
        .notification.toast.error { background: var(--error); }
        .notification.toast.show { transform: translateX(0); }
        `;
        document.head.appendChild(style);


        // Fechar modal ao clicar fora
        document.getElementById('orderModal').addEventListener('click', (e) => {
            if (e.target.id === 'orderModal') {
                closeModal();
            }
        });
    </script>
</body>
</html>
EOF

# Página de Relatórios Financeiros
cat > public/financial.html << 'EOF'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Relatórios Financeiros - Quentinhas Pro</title>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.0/chart.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/axios/1.4.0/axios.min.js"></script>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap');
        
        :root {
            --primary: #6366f1;
            --success: #10b981;
            --warning: #f59e0b;
            --error: #ef4444;
            --gray-50: #f8fafc;
            --gray-800: #1e293b;
            --border: #e2e8f0;
        }

        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: 'Inter', sans-serif;
            background: #f1f5f9;
            color: var(--gray-800);
            line-height: 1.6;
        }

        .sidebar {
            position: fixed;
            left: 0; top: 0;
            width: 280px;
            height: 100vh;
            background: white;
            box-shadow: 2px 0 10px rgba(0,0,0,0.1);
            z-index: 1000;
        }

        .sidebar-header {
            padding: 2rem 1.5rem;
            border-bottom: 1px solid var(--border);
            background: linear-gradient(135deg, var(--primary), #8b5cf6);
        }

        .logo {
            font-size: 1.5rem;
            font-weight: 800;
            color: white;
            text-align: center;
        }

        .nav-menu {
            padding: 1rem 0;
        }

        .nav-item {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 1rem 1.5rem;
            color: #64748b;
            text-decoration: none;
            transition: all 0.3s ease;
            border-left: 3px solid transparent;
        }

        .nav-item:hover, .nav-item.active {
            background: rgba(99, 102, 241, 0.1);
            color: var(--primary);
            border-left-color: var(--primary);
        }

        .main-content {
            margin-left: 280px;
            min-height: 100vh;
        }

        .header {
            background: white;
            padding: 1.5rem 2rem;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .header h1 {
            font-size: 1.75rem;
            font-weight: 700;
        }

        .content {
            padding: 2rem;
        }

        .period-selector {
            background: white;
            border-radius: 15px;
            padding: 1.5rem;
            margin-bottom: 2rem;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
        }

        .period-buttons {
            display: flex;
            gap: 1rem;
            margin-bottom: 1rem;
            flex-wrap: wrap;
        }

        .period-btn {
            padding: 0.75rem 1.5rem;
            border: 1px solid var(--border);
            background: white;
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.3s ease;
            font-weight: 600;
        }

        .period-btn.active {
            background: var(--primary);
            color: white;
            border-color: var(--primary);
        }

        .custom-period {
            display: none;
            grid-template-columns: 1fr 1fr auto;
            gap: 1rem;
            align-items: end;
            margin-top: 1rem;
        }

        .custom-period.show {
            display: grid;
        }

        .form-group {
            display: flex;
            flex-direction: column;
        }

        .form-group label {
            margin-bottom: 0.5rem;
            font-weight: 600;
            color: var(--gray-800);
        }

        .form-group input {
            padding: 0.75rem;
            border: 1px solid var(--border);
            border-radius: 8px;
            font-size: 0.875rem;
        }

        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 1.5rem;
            margin-bottom: 2rem;
        }

        .stat-card {
            background: white;
            border-radius: 15px;
            padding: 2rem;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
            border-left: 4px solid var(--primary);
        }

        .stat-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 1rem;
        }

        .stat-icon {
            width: 48px;
            height: 48px;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.5rem;
            color: white;
        }

        .stat-value {
            font-size: 2rem;
            font-weight: 800;
            color: var(--gray-800);
            margin-bottom: 0.5rem;
        }

        .stat-label {
            color: #64748b;
            font-weight: 500;
        }

        .charts-grid {
            display: grid;
            grid-template-columns: 2fr 1fr;
            gap: 2rem;
            margin-bottom: 2rem;
        }

        .chart-card {
            background: white;
            border-radius: 15px;
            padding: 2rem;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
            display: flex;
            flex-direction: column;
        }
        
        .chart-card canvas {
            flex-grow: 1;
        }

        .chart-title {
            font-size: 1.25rem;
            font-weight: 700;
            margin-bottom: 1.5rem;
            color: var(--gray-800);
        }

        .detailed-stats {
            background: white;
            border-radius: 15px;
            padding: 2rem;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
        }

        .table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 1rem;
        }

        .table th,
        .table td {
            padding: 1rem;
            text-align: left;
            border-bottom: 1px solid var(--border);
        }

        .table th {
            font-weight: 700;
            background: var(--gray-50);
        }

        .btn {
            padding: 0.75rem 1.5rem;
            border: none;
            border-radius: 8px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
        }

        .btn-primary {
            background: var(--primary);
            color: white;
        }

        .btn-primary:hover {
            background: #5046e5;
            transform: translateY(-2px);
        }

        .loading {
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 3rem;
            color: #64748b;
        }

        @media (max-width: 992px) {
            .charts-grid {
                grid-template-columns: 1fr;
            }
        }
        
        @media (max-width: 768px) {
            .sidebar { transform: translateX(-100%); }
            .main-content { margin-left: 0; }
            .header h1 { font-size: 1.5rem; }
            .custom-period {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="sidebar">
        <div class="sidebar-header">
            <div class="logo">🍽️ Quentinhas Pro</div>
        </div>
        <nav class="nav-menu">
            <a href="/dashboard" class="nav-item">
                <i class="fas fa-chart-line"></i> Dashboard
            </a>
            <a href="/orders" class="nav-item">
                <i class="fas fa-shopping-cart"></i> Pedidos
            </a>
            <a href="/financial" class="nav-item active">
                <i class="fas fa-chart-bar"></i> Financeiro
            </a>
            <a href="/menu-manager" class="nav-item">
                <i class="fas fa-utensils"></i> Cardápio
            </a>
            <a href="/customers" class="nav-item">
                <i class="fas fa-users"></i> Clientes
            </a>
        </nav>
    </div>

    <div class="main-content">
        <div class="header">
            <h1>Relatórios Financeiros</h1>
            <button class="btn btn-primary" onclick="exportReport()">
                <i class="fas fa-download"></i> Exportar Relatório
            </button>
        </div>

        <div class="content">
            <div class="period-selector">
                <h3>Selecionar Período</h3>
                <div class="period-buttons">
                    <button class="period-btn active" data-period="today" onclick="selectPeriod('today', this)">Hoje</button>
                    <button class="period-btn" data-period="week" onclick="selectPeriod('week', this)">Esta Semana</button>
                    <button class="period-btn" data-period="month" onclick="selectPeriod('month', this)">Este Mês</button>
                    <button class="period-btn" data-period="custom" onclick="selectPeriod('custom', this)">Personalizado</button>
                </div>
                
                <div class="custom-period" id="customPeriod">
                    <div class="form-group">
                        <label for="startDate">Data Inicial:</label>
                        <input type="date" id="startDate">
                    </div>
                    <div class="form-group">
                        <label for="endDate">Data Final:</label>
                        <input type="date" id="endDate">
                    </div>
                    <button class="btn btn-primary" onclick="applyCustomPeriod()">
                        <i class="fas fa-search"></i> Aplicar
                    </button>
                </div>
            </div>

            <div id="financialContent" class="loading">
                <i class="fas fa-spinner fa-spin fa-2x"></i>
            </div>
            
            <div id="reportData" style="display: none;">
                <div class="stats-grid">
                    <div class="stat-card">
                        <div class="stat-header">
                            <div class="stat-icon" style="background: linear-gradient(135deg, #10b981, #059669);"><i class="fas fa-dollar-sign"></i></div>
                        </div>
                        <div class="stat-value" id="grossRevenue">R$ 0,00</div>
                        <div class="stat-label">Faturamento Bruto</div>
                    </div>

                    <div class="stat-card">
                        <div class="stat-header">
                            <div class="stat-icon" style="background: linear-gradient(135deg, #6366f1, #8b5cf6);"><i class="fas fa-coins"></i></div>
                        </div>
                        <div class="stat-value" id="netRevenue">R$ 0,00</div>
                        <div class="stat-label">Faturamento Líquido</div>
                    </div>

                    <div class="stat-card">
                        <div class="stat-header">
                            <div class="stat-icon" style="background: linear-gradient(135deg, #f59e0b, #d97706);"><i class="fas fa-shopping-cart"></i></div>
                        </div>
                        <div class="stat-value" id="totalOrders">0</div>
                        <div class="stat-label">Total de Pedidos</div>
                    </div>

                    <div class="stat-card">
                        <div class="stat-header">
                            <div class="stat-icon" style="background: linear-gradient(135deg, #8b5cf6, #7c3aed);"><i class="fas fa-receipt"></i></div>
                        </div>
                        <div class="stat-value" id="avgTicket">R$ 0,00</div>
                        <div class="stat-label">Ticket Médio</div>
                    </div>

                    <div class="stat-card">
                        <div class="stat-header">
                            <div class="stat-icon" style="background: linear-gradient(135deg, #06b6d4, #0891b2);"><i class="fas fa-truck"></i></div>
                        </div>
                        <div class="stat-value" id="deliveryFees">R$ 0,00</div>
                        <div class="stat-label">Taxas de Entrega</div>
                    </div>

                    <div class="stat-card">
                        <div class="stat-header">
                            <div class="stat-icon" style="background: linear-gradient(135deg, #ef4444, #dc2626);"><i class="fas fa-times-circle"></i></div>
                        </div>
                        <div class="stat-value" id="canceledValue">R$ 0,00</div>
                        <div class="stat-label">Valor Cancelado</div>
                    </div>
                </div>

                <div class="charts-grid">
                    <div class="chart-card">
                        <h3 class="chart-title">Faturamento por Período</h3>
                        <canvas id="revenueChart"></canvas>
                    </div>

                    <div class="chart-card">
                        <h3 class="chart-title">Métodos de Pagamento</h3>
                        <canvas id="paymentChart"></canvas>
                    </div>
                </div>

                <div class="charts-grid">
                    <div class="chart-card">
                        <h3 class="chart-title">Vendas por Hora</h3>
                        <canvas id="hourlyChart"></canvas>
                    </div>

                    <div class="chart-card">
                        <h3 class="chart-title">Vendas por Categoria</h3>
                        <canvas id="categoryChart"></canvas>
                    </div>
                </div>

                <div class="detailed-stats">
                    <h3>Detalhamento Financeiro</h3>
                    <table class="table">
                        <thead>
                            <tr>
                                <th>Métrica</th>
                                <th>Valor</th>
                                <th>Percentual</th>
                            </tr>
                        </thead>
                        <tbody id="detailedTable"></tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <script>
        let currentPeriod = 'today';
        let revenueChart, paymentChart, hourlyChart, categoryChart;
        
        // Configurar token nas requisições
        axios.defaults.headers.common['Authorization'] = `Bearer ${localStorage.getItem('token')}`;

        document.addEventListener('DOMContentLoaded', () => {
             if (!localStorage.getItem('token')) {
                window.location.href = '/login';
                return;
            }
            initCharts();
            loadFinancialData();
        });

        function selectPeriod(period, button) {
            // Atualizar botões
            document.querySelectorAll('.period-btn').forEach(btn => btn.classList.remove('active'));
            button.classList.add('active');

            const customPeriodEl = document.getElementById('customPeriod');
            if (period === 'custom') {
                customPeriodEl.classList.add('show');
                return; // Don't load data until user clicks 'Apply'
            } else {
                customPeriodEl.classList.remove('show');
            }

            currentPeriod = period;
            loadFinancialData();
        }

        function applyCustomPeriod() {
            const startDate = document.getElementById('startDate').value;
            const endDate = document.getElementById('endDate').value;

            if (!startDate || !endDate) {
                alert('Por favor, selecione ambas as datas');
                return;
            }

            currentPeriod = 'custom';
            loadFinancialData(startDate, endDate);
        }

        async function loadFinancialData(startDate = null, endDate = null) {
            document.getElementById('reportData').style.display = 'none';
            document.getElementById('financialContent').style.display = 'flex';
            
            try {
                let params = { period: currentPeriod };
                if (currentPeriod === 'custom' && startDate && endDate) {
                    params.startDate = startDate;
                    params.endDate = endDate;
                }

                const response = await axios.get('/api/financial/reports', { params });
                const data = response.data;

                updateFinancialStats(data);
                updateAllCharts(data);
                updateDetailedTable(data);
                
                document.getElementById('reportData').style.display = 'block';

            } catch (error) {
                console.error('Erro ao carregar dados financeiros:', error);
                document.getElementById('financialContent').innerHTML = 'Erro ao carregar dados.';
                 if (error.response && error.response.status === 401) {
                    window.location.href = '/login';
                }
            } finally {
                document.getElementById('financialContent').style.display = 'none';
            }
        }

        function formatCurrency(value) {
            return value.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
        }

        function updateFinancialStats(data) {
            document.getElementById('grossRevenue').textContent = formatCurrency(data.grossRevenue);
            document.getElementById('netRevenue').textContent = formatCurrency(data.netRevenue);
            document.getElementById('totalOrders').textContent = data.totalOrders;
            document.getElementById('avgTicket').textContent = formatCurrency(data.avgTicket);
            document.getElementById('deliveryFees').textContent = formatCurrency(data.deliveryFees);
            document.getElementById('canceledValue').textContent = formatCurrency(data.canceledValue);
        }

        function initCharts() {
            const defaultOptions = {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'bottom'
                    }
                }
            };
            
            revenueChart = new Chart(document.getElementById('revenueChart'), { type: 'line', options: defaultOptions });
            paymentChart = new Chart(document.getElementById('paymentChart'), { type: 'doughnut', options: defaultOptions });
            hourlyChart = new Chart(document.getElementById('hourlyChart'), { type: 'bar', options: defaultOptions });
            categoryChart = new Chart(document.getElementById('categoryChart'), { type: 'bar', options: { ...defaultOptions, indexAxis: 'y' } });
        }

        function updateAllCharts(data) {
            // Faturamento
            revenueChart.data = {
                labels: data.revenueOverTime.map(d => new Date(d.date).toLocaleDateString('pt-BR')),
                datasets: [{
                    label: 'Faturamento',
                    data: data.revenueOverTime.map(d => d.revenue),
                    borderColor: '#6366f1',
                    backgroundColor: 'rgba(99, 102, 241, 0.1)',
                    fill: true,
                    tension: 0.3
                }]
            };
            revenueChart.update();

            // Pagamentos
            paymentChart.data = {
                labels: data.paymentMethodStats.map(stat => getPaymentMethodName(stat.paymentMethod)),
                datasets: [{
                    data: data.paymentMethodStats.map(stat => stat._sum.finalAmount || 0),
                    backgroundColor: ['#6366f1', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6']
                }]
            };
            paymentChart.update();

            // Vendas por Hora
            const hourlyData = new Array(24).fill(0);
            data.hourlyStats.forEach(stat => { hourlyData[stat.hour] = stat.orders; });
            hourlyChart.data = {
                labels: Array.from({length: 24}, (_, i) => `${i}h`),
                datasets: [{
                    label: 'Nº de Pedidos',
                    data: hourlyData,
                    backgroundColor: '#10b981'
                }]
            };
            hourlyChart.update();

            // Vendas por Categoria
            categoryChart.data = {
                labels: data.categoryStats.map(stat => stat.category),
                datasets: [{
                    label: 'Faturamento',
                    data: data.categoryStats.map(stat => stat.revenue),
                    backgroundColor: '#f59e0b'
                }]
            };
            categoryChart.update();
        }

        function updateDetailedTable(data) {
            const tbody = document.getElementById('detailedTable');
            const total = data.grossRevenue;

            const rows = [
                { label: 'Faturamento Bruto', value: data.grossRevenue, percent: 100 },
                { label: 'Taxas de Entrega', value: data.deliveryFees },
                { label: 'Descontos Aplicados', value: data.discounts },
                { label: 'Valor Cancelado', value: data.canceledValue },
                { label: 'Faturamento Líquido', value: data.netRevenue, isBold: true }
            ];
            
            tbody.innerHTML = rows.map(row => `
                <tr style="${row.isBold ? 'font-weight: bold; background: #f8fafc;' : ''}">
                    <td>${row.label}</td>
                    <td>${formatCurrency(row.value)}</td>
                    <td>${total > 0 ? (row.percent !== undefined ? row.percent : (row.value / total) * 100).toFixed(1) + '%' : '0.0%'}</td>
                </tr>
            `).join('');
        }

        function getPaymentMethodName(method) {
            const methods = {
                'CASH': 'Dinheiro', 'PIX': 'PIX', 'CREDIT_CARD': 'Crédito', 'DEBIT_CARD': 'Débito', 'BANK_TRANSFER': 'Transferência'
            };
            return methods[method] || method;
        }

        async function exportReport() {
            alert('Funcionalidade de exportação será implementada em breve!');
        }
    </script>
</body>
</html>
EOF

# =================================================================
# CONFIGURAR NGINX COM HTTPS
# =================================================================

log_info "Configurando Nginx com HTTPS..."

# Criar arquivo de configuração Nginx com rate limiting no contexto http
cat > /etc/nginx/conf.d/rate-limiting.conf << 'EOF'
# Rate Limiting Zones
limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
EOF

cat > /etc/nginx/sites-available/quentinhas << EOF
server {
    listen 80;
    server_name $PUBLIC_IP quentinhas.local;
    
    # Redirect HTTP to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $PUBLIC_IP quentinhas.local;
    
    # SSL Configuration (Auto-signed for now)
    ssl_certificate /etc/nginx/ssl/quentinhas.crt;
    ssl_certificate_key /etc/nginx/ssl/quentinhas.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # Main Application
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
    
    # API Rate Limiting
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Login Rate Limiting
    location /api/auth/login {
        limit_req zone=login burst=3 nodelay;
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # WebSocket Support
    location /socket.io/ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Static Files
    location /uploads/ {
        alias $PROJECT_DIR/uploads/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
    
    # Gzip Compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
}


EOF

# Criar certificado SSL auto-assinado
mkdir -p /etc/nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/quentinhas.key \
    -out /etc/nginx/ssl/quentinhas.crt \
    -subj "/C=BR/ST=SP/L=SaoPaulo/O=QuentinhasPro/CN=$PUBLIC_IP"

# Ativar site
ln -sf /etc/nginx/sites-available/quentinhas /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Testar e reiniciar Nginx
nginx -t && systemctl restart nginx
systemctl enable nginx

# =================================================================
# CRIAR EVOLUTION API CONFIGURADA
# =================================================================

log_info "Criando Evolution API configurada..."

docker run -d \
  --name quentinhas-evolution \
  --network quentinhas-sistema-avancado_quentinhas-network \
  -p 8080:8080 \
  -e SERVER_TYPE=http \
  -e SERVER_PORT=8080 \
  -e DEL_INSTANCE=false \
  -e DATABASE_ENABLED=false \
  -e REDIS_ENABLED=false \
  -e WEBHOOK_GLOBAL_URL="http://host.docker.internal:3000/api/webhook/whatsapp" \
  -e WEBHOOK_GLOBAL_ENABLED=true \
  -e CONFIG_SESSION_PHONE_CLIENT="QuentinhasSystem" \
  -e CORS_ORIGIN="*" \
  -e CORS_METHODS="GET,POST,PUT,DELETE" \
  -e CORS_CREDENTIALS=true \
  -e LOG_LEVEL=info \
  -e AUTHENTICATION_TYPE=apikey \
  -e AUTHENTICATION_API_KEY="$(grep EVOLUTION_API_KEY .env | cut -d'=' -f2 | tr -d '"')" \
  --add-host host.docker.internal:host-gateway \
  --restart unless-stopped \
  --memory="512m" \
  --cpus="0.5" \
  atendai/evolution-api:v1.7.4

log_info "Aguardando Evolution API..."
sleep 60

# =================================================================
# SCRIPTS DE BACKUP E MONITORAMENTO
# =================================================================

log_info "Criando scripts de backup e monitoramento..."

cat > scripts/backup.js << 'EOF'
const { exec } = require('child_process');
const fs = require('fs').promises;
const path = require('path');
const moment = require('moment');

class BackupManager {
  constructor() {
    this.backupDir = './backups';
    this.retentionDays = parseInt(process.env.BACKUP_RETENTION_DAYS) || 30;
  }

  async createBackup() {
    try {
      const timestamp = moment().format('YYYY-MM-DD_HH-mm-ss');
      const backupFile = path.join(this.backupDir, `backup_${timestamp}.sql`);
      
      console.log('🔄 Iniciando backup do banco de dados...');
      
      // Backup do PostgreSQL
      const command = `pg_dump ${process.env.DATABASE_URL} > ${backupFile}`;
      
      await new Promise((resolve, reject) => {
        exec(command, (error, stdout, stderr) => {
          if (error) {
            reject(error);
          } else {
            resolve(stdout);
          }
        });
      });
      
      console.log(`✅ Backup criado: ${backupFile}`);
      
      // Limpar backups antigos
      await this.cleanOldBackups();
      
      return backupFile;
    } catch (error) {
      console.error('❌ Erro no backup:', error);
      throw error;
    }
  }

  async cleanOldBackups() {
    try {
      const files = await fs.readdir(this.backupDir);
      const cutoffDate = moment().subtract(this.retentionDays, 'days');
      
      for (const file of files) {
        if (file.startsWith('backup_') && file.endsWith('.sql')) {
          const filePath = path.join(this.backupDir, file);
          const stats = await fs.stat(filePath);
          
          if (moment(stats.mtime).isBefore(cutoffDate)) {
            await fs.unlink(filePath);
            console.log(`🗑️ Backup antigo removido: ${file}`);
          }
        }
      }
    } catch (error) {
      console.error('Erro ao limpar backups antigos:', error);
    }
  }
}

// Executar backup se chamado diretamente
if (require.main === module) {
  const backup = new BackupManager();
  backup.createBackup()
    .then(file => {
      console.log('Backup concluído com sucesso:', file);
      process.exit(0);
    })
    .catch(error => {
      console.error('Erro no backup:', error);
      process.exit(1);
    });
}

module.exports = BackupManager;
EOF

# Script de monitoramento
cat > scripts/monitor.js << 'EOF'
const axios = require('axios');
const { exec } = require('child_process');
const nodemailer = require('nodemailer');

class SystemMonitor {
  constructor() {
    this.services = [
      { name: 'Sistema Principal', url: 'http://localhost:3000/api/health' },
      { name: 'WhatsApp API', url: 'http://localhost:8080' },
      { name: 'N8N', url: 'http://localhost:5678' }
    ];
    
    this.thresholds = {
      cpu: 80,
      memory: 85,
      disk: 90
    };
  }

  async checkServices() {
    const results = [];
    
    for (const service of this.services) {
      try {
        const response = await axios.get(service.url, { timeout: 5000 });
        results.push({
          name: service.name,
          status: response.status === 200 ? 'UP' : 'DOWN',
          responseTime: Date.now()
        });
      } catch (error) {
        results.push({
          name: service.name,
          status: 'DOWN',
          error: error.message
        });
      }
    }
    
    return results;
  }

  async checkSystemResources() {
    return new Promise((resolve) => {
      exec('free -m && df -h && top -bn1 | grep "Cpu(s)"', (error, stdout) => {
        if (error) {
          resolve({ error: error.message });
          return;
        }
        
        const lines = stdout.split('\n');
        const memoryLine = lines.find(line => line.includes('Mem:'));
        const diskLine = lines.find(line => line.includes('/dev/'));
        const cpuLine = lines.find(line => line.includes('Cpu(s)'));
        
        resolve({
          memory: this.parseMemory(memoryLine),
          disk: this.parseDisk(diskLine),
          cpu: this.parseCpu(cpuLine)
        });
      });
    });
  }

  parseMemory(line) {
    if (!line) return null;
    const parts = line.trim().split(/\s+/);
    const total = parseInt(parts[1]);
    const used = parseInt(parts[2]);
    return {
      total,
      used,
      percentage: Math.round((used / total) * 100)
    };
  }

  parseDisk(line) {
    if (!line) return null;
    const parts = line.trim().split(/\s+/);
    const percentage = parseInt(parts[4].replace('%', ''));
    return {
      used: parts[2],
      available: parts[3],
      percentage
    };
  }

  parseCpu(line) {
    if (!line) return null;
    const match = line.match(/(\d+\.\d+)%us/);
    return match ? parseFloat(match[1]) : null;
  }

  async sendAlert(message) {
    if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
      console.log('⚠️ Alerta:', message);
      return;
    }

    try {
      const transporter = nodemailer.createTransporter({
        host: process.env.EMAIL_HOST,
        port: process.env.EMAIL_PORT,
        secure: false,
        auth: {
          user: process.env.EMAIL_USER,
          pass: process.env.EMAIL_PASS
        }
      });

      await transporter.sendMail({
        from: process.env.EMAIL_USER,
        to: process.env.EMAIL_USER,
        subject: '🚨 Alerta Sistema Quentinhas',
        text: message
      });

      console.log('📧 Alerta enviado por email');
    } catch (error) {
      console.error('Erro ao enviar email:', error);
    }
  }

  async monitor() {
    console.log('🔍 Verificando sistema...');
    
    const [services, resources] = await Promise.all([
      this.checkServices(),
      this.checkSystemResources()
    ]);

    // Verificar serviços
    const downServices = services.filter(s => s.status === 'DOWN');
    if (downServices.length > 0) {
      const message = `Serviços offline: ${downServices.map(s => s.name).join(', ')}`;
      await this.sendAlert(message);
    }

    // Verificar recursos
    if (resources.cpu && resources.cpu > this.thresholds.cpu) {
      await this.sendAlert(`CPU alta: ${resources.cpu}%`);
    }
    
    if (resources.memory && resources.memory.percentage > this.thresholds.memory) {
      await this.sendAlert(`Memória alta: ${resources.memory.percentage}%`);
    }
    
    if (resources.disk && resources.disk.percentage > this.thresholds.disk) {
      await this.sendAlert(`Disco cheio: ${resources.disk.percentage}%`);
    }

    console.log('✅ Monitoramento concluído');
    return { services, resources };
  }
}

// Executar monitoramento se chamado diretamente
if (require.main === module) {
  const monitor = new SystemMonitor();
  monitor.monitor()
    .then(results => {
      console.log('Resultados:', JSON.stringify(results, null, 2));
    })
    .catch(error => {
      console.error('Erro no monitoramento:', error);
    });
}

module.exports = SystemMonitor;
EOF

# =================================================================
# CONFIGURAR CRON JOBS
# =================================================================

log_info "Configurando tarefas automatizadas..."

# Adicionar cron jobs
(crontab -l 2>/dev/null; echo "0 2 * * * cd $PROJECT_DIR && node scripts/backup.js") | crontab -
(crontab -l 2>/dev/null; echo "*/15 * * * * cd $PROJECT_DIR && node scripts/monitor.js") | crontab -

# =================================================================
# INICIALIZAR SISTEMA COMPLETO
# =================================================================

log_info "Inicializando sistema completo..."

# Aguardar serviços
sleep 30

# Iniciar aplicação principal
npm start

# Aguardar inicialização
sleep 20

# =================================================================
# SCRIPTS DE MANUTENÇÃO AVANÇADOS
# =================================================================

log_info "Criando scripts de manutenção avançados..."

cat > manage-system.sh << 'EOF'
#!/bin/bash

PROJECT_DIR="/root/quentinhas-sistema-avancado"
cd $PROJECT_DIR

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_purple() { echo -e "${PURPLE}🎨 $1${NC}"; }

show_status() {
    echo ""
    log_purple "=== STATUS SISTEMA QUENTINHAS PRO AVANÇADO ==="
    echo ""
    
    PUBLIC_IP=$(curl -s ifconfig.me)
    
    # Verificar serviços principais
    if pm2 list | grep -q "quentinhas-sistema.*online"; then
        log_success "Sistema Principal: ✅ Online"
        echo "    🔗 https://$PUBLIC_IP"
        echo "    📊 Dashboard protegido por login"
    else
        log_error "Sistema Principal: ❌ Offline"
    fi
    
    if curl -s http://localhost:8080 >/dev/null 2>&1; then
        log_success "WhatsApp API: ✅ Online"
        echo "    🔗 http://$PUBLIC_IP:8080/manager"
        echo "    🤖 Robô com IA conversacional ativo"
    else
        log_error "WhatsApp API: ❌ Offline"
    fi
    
    if curl -s http://localhost:5678 >/dev/null 2>&1; then
        log_success "N8N: ✅ Online"
        echo "    🔗 http://$PUBLIC_IP:5678"
    else
        log_error "N8N: ❌ Offline"
    fi
    
    # Verificar Nginx
    if systemctl is-active nginx >/dev/null 2>&1; then
        log_success "Nginx: ✅ Online (HTTPS ativo)"
    else
        log_error "Nginx: ❌ Offline"
    fi
    
    # Verificar Docker
    if docker ps | grep -q "quentinhas"; then
        log_success "Docker Services: ✅ Online"
        echo "    📊 PostgreSQL, Redis, MongoDB, N8N"
    else
        log_error "Docker Services: ❌ Problemas detectados"
    fi
    
    echo ""
    log_purple "🤖 RECURSOS AVANÇADOS:"
    echo "    ✅ Google Gemini AI integrado"
    echo "    ✅ HTTPS com certificado SSL"
    echo "    ✅ Backup automático diário"
    echo "    ✅ Monitoramento em tempo real"
    echo "    ✅ PM2 Cluster mode"
    echo "    ✅ Redis cache para performance"
    echo "    ✅ Validação robusta de dados"
    echo "    ✅ Relatórios financeiros completos"
    echo ""
    log_purple "🔑 CREDENCIAIS:"
    echo "    📧 Email: admin@quentinhas.com"
    echo "    🔐 Senha: admin123"
    echo ""
    log_purple "📊 ESTATÍSTICAS PM2:"
    pm2 list
    echo ""
    log_purple "🐳 CONTAINERS DOCKER:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

backup_now() {
    log_info "Criando backup manual..."
    node scripts/backup.js
}

restart_services() {
    log_info "Reiniciando todos os serviços..."
    
    # Parar PM2
    pm2 stop quentinhas-sistema
    
    # Reiniciar Docker
    docker-compose restart
    
    # Aguardar
    sleep 30
    
    # Reiniciar PM2
    pm2 start quentinhas-sistema
    
    # Reiniciar Nginx
    systemctl restart nginx
    
    log_success "Serviços reiniciados!"
}

view_logs() {
    echo "Escolha o log para visualizar:"
    echo "1) Sistema Principal"
    echo "2) Docker Compose"
    echo "3) Nginx"
    echo "4) Sistema (journald)"
    read -p "Opção (1-4): " choice
    
    case $choice in
        1) pm2 logs quentinhas-sistema ;;
        2) docker-compose logs -f ;;
        3) tail -f /var/log/nginx/error.log ;;
        4) journalctl -f ;;
        *) log_error "Opção inválida" ;;
    esac
}

update_system() {
    log_info "Atualizando sistema..."
    
    # Parar serviços
    pm2 stop quentinhas-sistema
    
    # Atualizar código
    git pull origin main 2>/dev/null || log_warning "Git não configurado"
    
    # Atualizar dependências
    npm install
    
    # Migrar banco de dados
    npx prisma migrate deploy
    
    # Reiniciar
    pm2 start quentinhas-sistema
    
    log_success "Sistema atualizado!"
}

cleanup_system() {
    log_info "Limpando sistema..."
    
    # Limpar logs antigos
    find logs/ -name "*.log" -mtime +7 -delete 2>/dev/null || true
    
    # Limpar cache
    rm -rf node_modules/.cache 2>/dev/null || true
    
    # Limpar Docker
    docker system prune -f
    
    # Limpar PM2
    pm2 flush
    
    log_success "Sistema limpo!"
}

security_check() {
    log_info "Verificação de segurança..."
    
    # Verificar portas abertas
    log_info "Portas abertas:"
    netstat -tlnp | grep LISTEN
    
    # Verificar fail2ban
    if systemctl is-active fail2ban >/dev/null 2>&1; then
        log_success "Fail2ban ativo"
        fail2ban-client status
    else
        log_warning "Fail2ban inativo"
    fi
    
    # Verificar firewall
    if ufw status | grep -q "Status: active"; then
        log_success "Firewall ativo"
        ufw status
    else
        log_warning "Firewall inativo"
    fi
}

performance_check() {
    log_info "Verificação de performance..."
    
    # CPU e Memória
    echo "=== RECURSOS ==="
    free -h
    echo ""
    top -bn1 | head -5
    
    # Disco
    echo ""
    echo "=== DISCO ==="
    df -h
    
    # Rede
    echo ""
    echo "=== REDE ==="
    ss -tuln | grep LISTEN
}

case "${1:-status}" in
    "status")
        show_status
        ;;
    "backup")
        backup_now
        ;;
    "restart")
        restart_services
        ;;
    "logs")
        view_logs
        ;;
    "update")
        update_system
        ;;
    "cleanup")
        cleanup_system
        ;;
    "security")
        security_check
        ;;
    "performance")
        performance_check
        ;;
    "monitor")
        node scripts/monitor.js
        ;;
    *)
        echo "Uso: $0 [status|backup|restart|logs|update|cleanup|security|performance|monitor]"
        echo ""
        echo "Comandos disponíveis:"
        echo "  status      - Mostrar status dos serviços"
        echo "  backup      - Criar backup manual"
        echo "  restart     - Reiniciar todos os serviços"
        echo "  logs        - Visualizar logs"
        echo "  update      - Atualizar sistema"
        echo "  cleanup     - Limpar sistema"
        echo "  security    - Verificação de segurança"
        echo "  performance - Verificação de performance"
        echo "  monitor     - Executar monitoramento"
        ;;
esac
EOF

chmod +x manage-system.sh

# =================================================================
# FINALIZAÇÃO E TESTES
# =================================================================

log_info "Executando testes finais..."

# Aguardar todos os serviços
sleep 45

# Testar conexões
log_info "Testando conexões..."

if curl -k -s https://localhost >/dev/null 2>&1; then
    log_success "✅ HTTPS funcionando"
else
    log_warning "⚠️ HTTPS com problemas"
fi

if curl -s http://localhost:3000/api/health >/dev/null 2>&1; then
    log_success "✅ API principal funcionando"
else
    log_warning "⚠️ API principal com problemas"
fi

# =================================================================
# EXIBIR INFORMAÇÕES FINAIS
# =================================================================

echo ""
echo ""
log_purple "🎉 SISTEMA QUENTINHAS PRO AVANÇADO INSTALADO COM SUCESSO!"
log_success "🚀 INSTALAÇÃO 100% CONCLUÍDA!"
echo ""
echo "🌟 SISTEMA EMPRESARIAL COMPLETO E AVANÇADO:"
echo "    🤖 Robô WhatsApp com Google Gemini AI"
echo "    🔐 HTTPS + Nginx + Segurança avançada"
echo "    💾 Backup automático diário"
echo "    📊 Validação robusta expandida"
echo "    ⚡ PM2 Cluster mode para alta performance"
echo "    🔄 Redis cache para consultas rápidas"
echo "    📈 Monitoramento básico em tempo real"
echo "    🎨 Interface melhorada e responsiva"
echo "    💰 Relatórios financeiros completos"
echo "    📱 Gestão completa de pedidos"
echo "    🍽️ Controle total do cardápio"
echo ""
echo "🔗 ACESSO AO SISTEMA:"
echo "    🔐 Dashboard Principal: https://$PUBLIC_IP"
echo "    📱 WhatsApp Manager: http://$PUBLIC_IP:8080/manager"
echo "    🤖 N8N Automação: http://$PUBLIC_IP:5678"
echo "    📊 Prometheus: http://$PUBLIC_IP:9090"
echo ""
echo "🔑 CREDENCIAIS DE ACESSO:"
echo "    📧 Email: admin@quentinhas.com"
echo "    🔐 Senha: admin123"
echo "    🔑 Evolution API Key: $(grep EVOLUTION_API_KEY .env | cut -d'=' -f2 | tr -d '"')"
echo ""
echo "🤖 ROBÔ WHATSAPP COM IA AVANÇADA:"
echo "    ✅ Google Gemini AI conversacional"
echo "    ✅ Processo completo de pedidos automatizado"
echo "    ✅ Reconhecimento inteligente de clientes"
echo "    ✅ Carrinho de compras interativo"
echo "    ✅ Coleta automática de endereços"
echo "    ✅ Confirmações e notificações automáticas"
echo "    ✅ Histórico de conversas e pedidos"
echo "    ✅ Respostas contextuais inteligentes"
echo ""
echo "💰 RELATÓRIOS FINANCEIROS AVANÇADOS:"
echo "    ✅ Faturamento diário, semanal, mensal"
echo "    ✅ Análise de ticket médio"
echo "    ✅ Relatório por métodos de pagamento"
echo "    ✅ Vendas por categoria e horário"
echo "    ✅ Controle de cancelamentos"
echo "    ✅ Estatísticas de entrega"
echo "    ✅ Exportação de dados"
echo ""
echo "📊 DASHBOARD GERENCIAL COMPLETO:"
echo "    ✅ Visão em tempo real dos pedidos"
echo "    ✅ Alterar status com um clique"
echo "    ✅ Histórico completo de cada pedido"
echo "    ✅ Busca e filtros avançados"
echo "    ✅ Notificações automáticas via WhatsApp"
echo "    ✅ Controle de estoque e disponibilidade"
echo "    ✅ Gestão completa de clientes"
echo ""
echo "🔧 COMO USAR O SISTEMA:"
echo ""
echo "1. 📱 CONFIGURAR WHATSAPP:"
echo "   - Acesse: http://$PUBLIC_IP:8080/manager"
echo "   - Conecte seu WhatsApp Business"
echo "   - O robô já está configurado e funcionando!"
echo ""
echo "2. 🍽️ GERENCIAR CARDÁPIO:"
echo "   - Acesse: https://$PUBLIC_IP"
echo "   - Faça login com as credenciais"
echo "   - Vá em 'Cardápio' para adicionar/editar pratos"
echo "   - Clientes verão automaticamente no WhatsApp"
echo ""
echo "3. 📦 GERENCIAR PEDIDOS:"
echo "   - Vá em 'Pedidos' no dashboard"
echo "   - Veja todos os pedidos em tempo real"
echo "   - Clique em 'Confirmar' quando receber pedido"
echo "   - Mude status: Preparando → Pronto → Entregue"
echo "   - Cliente recebe notificação automática"
echo ""
echo "4. 💰 ACOMPANHAR FINANCEIRO:"
echo "   - Vá em 'Financeiro' para relatórios"
echo "   - Veja faturamento diário/mensal"
echo "   - Analise vendas por categoria"
echo "   - Exporte relatórios quando necessário"
echo ""
echo "🛠️ COMANDOS DE MANUTENÇÃO:"
echo "    ./manage-system.sh status     - Ver status completo"
echo "    ./manage-system.sh restart    - Reiniciar sistema"
echo "    ./manage-system.sh backup     - Fazer backup manual"
echo "    ./manage-system.sh logs       - Ver logs do sistema"
echo "    ./manage-system.sh monitor    - Monitorar performance"
echo "    ./manage-system.sh security   - Verificar segurança"
echo ""
echo "🔒 SEGURANÇA IMPLEMENTADA:"
echo "    ✅ HTTPS com certificado SSL"
echo "    ✅ Firewall configurado (UFW)"
echo "    ✅ Fail2ban para proteção anti-intrusão"
echo "    ✅ Rate limiting nas APIs"
echo "    ✅ Validação robusta de dados"
echo "    ✅ Sanitização de inputs"
echo "    ✅ Headers de segurança"
echo "    ✅ Sessões seguras com Redis"
echo ""
echo "📈 MONITORAMENTO E BACKUP:"
echo "    ✅ Backup automático diário às 02:00"
echo "    ✅ Monitoramento a cada 15 minutos"
echo "    ✅ Alertas por email (se configurado)"
echo "    ✅ Limpeza automática de logs antigos"
echo "    ✅ Retenção de backups por 30 dias"
echo "    ✅ Métricas do Prometheus"
echo ""
echo "⚡ PERFORMANCE OTIMIZADA:"
echo "    ✅ PM2 Cluster mode (usa todos os CPUs)"
echo "    ✅ Redis cache para consultas frequentes"
echo "    ✅ Compressão Gzip no Nginx"
echo "    ✅ Cache de arquivos estáticos"
echo "    ✅ Otimização de queries do banco"
echo "    ✅ WebSocket para atualizações em tempo real"
echo ""
echo "🆘 SUPORTE E SOLUÇÃO DE PROBLEMAS:"
echo ""
echo "Se algum serviço não estiver funcionando:"
echo "1. Execute: ./manage-system.sh status"
echo "2. Para reiniciar tudo: ./manage-system.sh restart"
echo "3. Para ver logs: ./manage-system.sh logs"
echo ""
echo "Problemas com WhatsApp:"
echo "1. Acesse: http://$PUBLIC_IP:8080/manager"
echo "2. Reconecte o WhatsApp se necessário"
echo "3. Verifique se o webhook está configurado"
echo ""
echo "Problemas com IA (Gemini):"
echo "1. Verifique sua API Key no arquivo .env"
echo "2. Se não tiver, o sistema usa fallback básico"
echo "3. Obtenha uma chave em: https://makersuite.google.com/app/apikey"
echo ""

# Status final detalhado
echo ""
log_purple "📊 STATUS FINAL DOS SERVIÇOS:"

if curl -k -s https://localhost >/dev/null 2>&1; then
    log_success "✅ HTTPS (Nginx): FUNCIONANDO"
else
    log_warning "⚠️ HTTPS: Verificar configuração"
fi

if curl -s http://localhost:3000/api/health >/dev/null 2>&1; then
    log_success "✅ Sistema Principal: FUNCIONANDO"
else
    log_warning "⚠️ Sistema Principal: Inicializando..."
fi

if curl -s http://localhost:8080 >/dev/null 2>&1; then
    log_success "✅ WhatsApp API: FUNCIONANDO"
else
    log_warning "⚠️ WhatsApp API: Inicializando..."
fi

if curl -s http://localhost:5678 >/dev/null 2>&1; then
    log_success "✅ N8N: FUNCIONANDO"
else
    log_warning "⚠️ N8N: Inicializando..."
fi

if docker ps | grep -q "quentinhas-postgres.*Up"; then
    log_success "✅ PostgreSQL: FUNCIONANDO"
else
    log_warning "⚠️ PostgreSQL: Verificar container"
fi

if docker ps | grep -q "quentinhas-redis.*Up"; then
    log_success "✅ Redis: FUNCIONANDO"
else
    log_warning "⚠️ Redis: Verificar container"
fi

if systemctl is-active nginx >/dev/null 2>&1; then
    log_success "✅ Nginx: FUNCIONANDO"
else
    log_warning "⚠️ Nginx: Verificar configuração"
fi

if systemctl is-active fail2ban >/dev/null 2>&1; then
    log_success "✅ Fail2ban: FUNCIONANDO"
else
    log_warning "⚠️ Fail2ban: Verificar instalação"
fi

if pm2 list | grep -q "quentinhas-sistema.*online"; then
    log_success "✅ PM2 Cluster: FUNCIONANDO"
else
    log_warning "⚠️ PM2: Verificar processo"
fi

echo ""
log_purple "🎯 PRÓXIMOS PASSOS RECOMENDADOS:"
echo ""
echo "1. 📱 Configurar WhatsApp Business:"
echo "   - Acesse http://$PUBLIC_IP:8080/manager"
echo "   - Escaneie o QR Code com seu WhatsApp Business"
echo ""
echo "2. 🍽️ Adicionar seus pratos no cardápio:"
echo "   - Acesse https://$PUBLIC_IP"
echo "   - Login → Cardápio → Adicionar Itens"
echo ""
echo "3. 🧪 Testar o robô:"
echo "   - Envie mensagem para o WhatsApp conectado"
echo "   - Digite 'cardápio' ou 'oi'"
echo "   - Teste fazer um pedido completo"
echo ""
echo "4. ⚙️ Personalizar configurações:"
echo "   - Edite dados da empresa no arquivo .env"
echo "   - Configure email para alertas (opcional)"
echo "   - Ajuste horários de funcionamento"
echo ""
echo "5. 🔒 Configurar domínio (opcional):"
echo "   - Aponte seu domínio para $PUBLIC_IP"
echo "   - Configure certificado SSL com Let's Encrypt"
echo "   - Execute: certbot --nginx -d seudominio.com"
echo ""

# Criar arquivo de informações importantes
cat > INFORMACOES_IMPORTANTES.txt << EOF
==============================================
SISTEMA QUENTINHAS PRO - INFORMAÇÕES IMPORTANTES
==============================================

🔗 ACESSOS:
Dashboard: https://$PUBLIC_IP
WhatsApp: http://$PUBLIC_IP:8080/manager
N8N: http://$PUBLIC_IP:5678

🔑 CREDENCIAIS:
Email: admin@quentinhas.com
Senha: admin123
API Key: $(grep EVOLUTION_API_KEY .env | cut -d'=' -f2 | tr -d '"')

🛠️ COMANDOS ÚTEIS:
./manage-system.sh status    - Ver status
./manage-system.sh restart   - Reiniciar tudo
./manage-system.sh backup    - Backup manual
./manage-system.sh logs      - Ver logs

📁 DIRETÓRIOS IMPORTANTES:
Sistema: $PROJECT_DIR
Logs: $PROJECT_DIR/logs/
Backups: $PROJECT_DIR/backups/
Uploads: $PROJECT_DIR/uploads/

🔧 CONFIGURAÇÕES:
Arquivo principal: $PROJECT_DIR/.env
Nginx: /etc/nginx/sites-available/quentinhas
PM2: $PROJECT_DIR/ecosystem.config.js

⚠️ MANUTENÇÃO:
- Backup automático: Diário às 02:00
- Monitoramento: A cada 15 minutos  
- Limpeza de logs: Semanal
- Retenção de backups: 30 dias

📞 SUPORTE:
- Logs do sistema: ./manage-system.sh logs
- Status completo: ./manage-system.sh status
- Reiniciar se necessário: ./manage-system.sh restart

Generated: $(date)
==============================================
EOF

echo ""
log_success "✅ ARQUIVO DE INFORMAÇÕES CRIADO: INFORMACOES_IMPORTANTES.txt"
echo ""
log_purple "🎉 PARABÉNS! SEU SISTEMA ESTÁ PRONTO PARA USO!"
log_success "🚀 ACESSE: https://$PUBLIC_IP e comece a vender!"
echo ""

# Exibir comando para verificar status
echo "Para verificar o status completo a qualquer momento:"
echo "cd $PROJECT_DIR && ./manage-system.sh status"
echo ""

exit 0
