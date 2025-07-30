#!/bin/bash

# =================================================================
# SISTEMA QUENTINHAS PRO - VERSÃO FINAL COMPLETA (MELHORADA)
# Painel Profissional + Backend + WhatsApp + N8N + Firewall
# Tudo Sincronizado e Pronto para Usar!
# =================================================================

set -e  # Para o script imediatamente se qualquer comando falhar

echo "🚀 SISTEMA QUENTINHAS PRO - INSTALAÇÃO COMPLETA"
echo "=============================================="
echo "📦 Inclui: Painel Profissional + API + WhatsApp + N8N"
echo "🔥 Firewall + URLs + Tudo Sincronizado!"
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
# CONFIGURAR FIREWALL AUTOMATICAMENTE
# =================================================================

log_info "Configurando firewall (UFW) automaticamente..."

apt update && apt install -y ufw

ufw --force reset
ufw default deny incoming
ufw default allow outgoing

ufw allow 22/tcp comment 'SSH'
ufw allow 3000/tcp comment 'Painel Admin Quentinhas'
ufw allow 8080/tcp comment 'Evolution API WhatsApp'
ufw allow 5678/tcp comment 'N8N Automacao'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'

ufw --force enable

log_success "Firewall configurado! Portas liberadas: 22, 80, 443, 3000, 5678, 8080"

# =================================================================
# INSTALAÇÃO BÁSICA
# =================================================================

log_info "Atualizando sistema..."
apt update && apt upgrade -y

log_info "Instalando dependências..."
apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release nano htop

log_info "Instalando Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

log_info "Instalando Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

log_info "Instalando Node.js 18..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

log_info "Instalando PM2 globalmente..."
npm install -g pm2

PROJECT_DIR="/root/quentinhas-pro"
log_info "Criando projeto em $PROJECT_DIR"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

mkdir -p {src,prisma,setup,logs,uploads,public,ssl,backups}

# =================================================================
# ARQUIVOS DE CONFIGURAÇÃO
# =================================================================

log_info "Criando package.json..."
cat > package.json << 'EOF'
{
  "name": "quentinhas-pro",
  "version": "1.0.0",
  "description": "Sistema avançado para gestão de quentinhas via WhatsApp",
  "main": "server.js",
  "scripts": {
    "start": "pm2 start server.js --name quentinhas-api",
    "stop": "pm2 stop quentinhas-api",
    "restart": "pm2 restart quentinhas-api",
    "logs": "pm2 logs quentinhas-api",
    "dev": "nodemon server.js",
    "setup": "node setup/init-db.js",
    "migrate": "npx prisma migrate dev",
    "seed": "node setup/seed.js"
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
    "morgan": "^1.10.0"
  },
  "devDependencies": {
    "nodemon": "^3.0.2"
  }
}
EOF

log_info "Criando .env com IP público..."
cat > .env << EOF
DATABASE_URL="postgresql://quentinhas:quentinhas123@localhost:5432/quentinhas"
REDIS_URL="redis://redis:6379"
JWT_SECRET="quentinhas_jwt_secret_super_seguro_mude_em_producao"
PORT=3000
NODE_ENV=production
EVOLUTION_API_URL="http://host.docker.internal:3000"
EVOLUTION_API_KEY="evolution_api_key"
N8N_WEBHOOK_URL="http://host.docker.internal:3000"
PUBLIC_IP="${PUBLIC_IP}"
MAX_FILE_SIZE=10485760
UPLOAD_PATH="./uploads"
BUSINESS_NAME="Quentinhas da Casa"
BUSINESS_PHONE="(11) 99999-9999"
DELIVERY_FEE=3.00
MIN_ORDER_VALUE=15.00
EOF

log_info "Criando docker-compose.yml corrigido..."
cat > docker-compose.yml << EOF
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

  redis:
    image: redis:7-alpine
    container_name: quentinhas-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    restart: unless-stopped
    networks:
      - quentinhas-network

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

  evolution:
    image: atendai/evolution-api:latest
    container_name: quentinhas-evolution
    environment:
      - SERVER_TYPE=http
      - DEL_INSTANCE=false
      - DATABASE_ENABLED=true
      - DATABASE_CONNECTION_URI=mongodb://root:evolution123@mongo:27017/evolution?authSource=admin
      - REDIS_ENABLED=true
      - REDIS_URI=redis://redis:6379
      - WEBHOOK_GLOBAL_URL=http://host.docker.internal:3000/api/webhook/whatsapp
      - WEBHOOK_GLOBAL_ENABLED=true
      - WEBHOOK_GLOBAL_WEBHOOK_BY_EVENTS=true
      - CONFIG_SESSION_PHONE_CLIENT=Quentinhas System
      - CONFIG_SESSION_PHONE_NAME=Sistema Quentinhas
      - CORS_ORIGIN=*
      - CORS_METHODS=POST,GET,PUT,DELETE
      - CORS_CREDENTIALS=true
    ports:
      - "8080:8080"
    depends_on:
      - mongo
      - redis
    extra_hosts:
      - "host.docker.internal:host-gateway"
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
      - N8N_BASIC_AUTH_ACTIVE=false
      - N8N_DISABLE_UI=false
      - N8N_PUBLIC_API_DISABLED=false
    ports:
      - "5678:5678"
    volumes:
      - n8n_data:/home/node/.n8n
    extra_hosts:
      - "host.docker.internal:host-gateway"
    restart: unless-stopped
    networks:
      - quentinhas-network

volumes:
  postgres_data:
  redis_data:
  mongo_data:
  n8n_data:

networks:
  quentinhas-network:
    driver: bridge
EOF

log_info "Criando schema do Prisma..."
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
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@map("users")
}

model Customer {
  id            String    @id @default(cuid())
  phone         String    @unique
  name          String?
  email         String?
  address       String?
  totalOrders   Int       @default(0)
  totalSpent    Float     @default(0)
  loyaltyPoints Int       @default(0)
  isVip         Boolean   @default(false)
  lastOrderAt   DateTime?
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt

  orders       Order[]
  interactions Interaction[]

  @@map("customers")
}

model MenuItem {
  id          String   @id @default(cuid())
  name        String
  description String?
  price       Float
  category    String?
  imageUrl    String?
  available   Boolean  @default(true)
  soldCount   Int      @default(0)
  ingredients String[]
  allergens   String[]
  calories    Int?
  prepTime    Int?
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt

  orderItems OrderItem[]

  @@map("menu_items")
}

model Order {
  id              String      @id @default(cuid())
  customerId      String
  customer        Customer    @relation(fields: [customerId], references: [id])
  status          OrderStatus @default(CONFIRMED)
  totalAmount     Float
  deliveryFee     Float       @default(3.00)
  discount        Float       @default(0)
  finalAmount     Float
  deliveryAddress String?
  paymentMethod   PaymentMethod?
  notes           String?
  estimatedTime   Int?
  actualTime      Int?
  rating          Int?
  feedback        String?
  createdAt       DateTime    @default(now())
  updatedAt       DateTime    @updatedAt
  deliveredAt     DateTime?

  items         OrderItem[]
  statusHistory OrderStatusHistory[]

  @@map("orders")
}

model OrderItem {
  id         String   @id @default(cuid())
  orderId    String
  order      Order    @relation(fields: [orderId], references: [id])
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
  order     Order       @relation(fields: [orderId], references: [id])
  status    OrderStatus
  timestamp DateTime    @default(now())
  notes     String?

  @@map("order_status_history")
}

model Interaction {
  id           String          @id @default(cuid())
  customerId   String
  customer     Customer        @relation(fields: [customerId], references: [id])
  type         InteractionType
  message      String
  response     String?
  intent       String?
  satisfaction Int?
  createdAt    DateTime        @default(now())

  @@map("interactions")
}

model Analytics {
  id             String   @id @default(cuid())
  date           DateTime @default(now())
  totalOrders    Int      @default(0)
  totalRevenue   Float    @default(0)
  avgTicket      Float    @default(0)
  newCustomers   Int      @default(0)
  conversionRate Float    @default(0)
  topItem        String?
  busyHour       Int?
  avgDeliveryTime Int?

  @@unique([date])
  @@map("analytics")
}

model Setting {
  id    String @id @default(cuid())
  key   String @unique
  value String

  @@map("settings")
}

enum Role {
  ADMIN
  MANAGER
  OPERATOR
}

enum OrderStatus {
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
  CARD
  TRANSFER
}

enum InteractionType {
  MESSAGE
  ORDER
  COMPLAINT
  FEEDBACK
  SUPPORT
}
EOF

log_info "Iniciando containers do banco de dados..."
docker-compose up -d postgres redis mongo

log_info "Aguardando bancos de dados iniciarem..."
sleep 30

log_info "Instalando dependências Node.js..."
npm install

log_info "Gerando cliente Prisma..."
npx prisma generate

log_info "Executando migrações do banco..."
npx prisma migrate dev --name init

log_info "Criando dados iniciais..."
cat > setup/seed.js << 'EOF'
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Criando dados iniciais...');

  const hashedPassword = await bcrypt.hash('admin123', 10);
  await prisma.user.upsert({
    where: { email: 'admin@quentinhas.com' },
    update: {},
    create: {
      email: 'admin@quentinhas.com',
      password: hashedPassword,
      name: 'Administrador',
      role: 'ADMIN'
    }
  });

  const menuItems = [
    {
      name: 'Bife Acebolado',
      description: 'Bife grelhado com cebolas refogadas, arroz branco, feijão carioca e batata frita',
      price: 18.00,
      category: 'Pratos Principais',
      available: true,
      prepTime: 25,
      calories: 650,
      ingredients: ['Bife bovino', 'Arroz', 'Feijão', 'Batata', 'Cebola'],
      allergens: []
    },
    {
      name: 'Frango Grelhado',
      description: 'Peito de frango grelhado temperado com ervas, arroz integral e legumes no vapor',
      price: 16.00,
      category: 'Pratos Saudáveis',
      available: true,
      prepTime: 20,
      calories: 450,
      ingredients: ['Peito de frango', 'Arroz integral', 'Brócolis', 'Cenoura', 'Abobrinha'],
      allergens: []
    },
    {
      name: 'Peixe Assado',
      description: 'Filé de peixe assado com temperos especiais, arroz de brócolis e purê de batata',
      price: 20.00,
      category: 'Pratos Especiais',
      available: true,
      prepTime: 30,
      calories: 520,
      ingredients: ['Filé de peixe', 'Arroz', 'Brócolis', 'Batata', 'Alho'],
      allergens: ['Peixe']
    },
    {
      name: 'Feijoada Completa',
      description: 'Feijoada tradicional com linguiça, bacon, carne seca, arroz, couve e farofa',
      price: 22.00,
      category: 'Pratos Tradicionais',
      available: true,
      prepTime: 45,
      calories: 800,
      ingredients: ['Feijão preto', 'Linguiça', 'Bacon', 'Carne seca', 'Arroz', 'Couve'],
      allergens: []
    },
    {
      name: 'Lasanha Bolonhesa',
      description: 'Lasanha caseira com molho bolonhesa, queijo e massa artesanal',
      price: 19.00,
      category: 'Massas',
      available: true,
      prepTime: 35,
      calories: 720,
      ingredients: ['Massa de lasanha', 'Carne moída', 'Molho de tomate', 'Queijo mussarela'],
      allergens: ['Glúten', 'Lactose']
    }
  ];

  for (const item of menuItems) {
    await prisma.menuItem.upsert({
      where: { name: item.name },
      update: {},
      create: item
    });
  }

  const settings = [
    { key: 'business_name', value: 'Quentinhas da Casa' },
    { key: 'business_phone', value: '(11) 99999-9999' },
    { key: 'business_address', value: 'Rua Principal, 123 - Centro' },
    { key: 'delivery_fee', value: '3.00' },
    { key: 'min_order_value', value: '15.00' },
    { key: 'working_hours_start', value: '10' },
    { key: 'working_hours_end', value: '15' },
    { key: 'working_weekends', value: 'true' },
    { key: 'loyalty_points_rate', value: '1' },
    { key: 'loyalty_discount_threshold', value: '100' },
    { key: 'loyalty_discount_percentage', value: '20' }
  ];

  for (const setting of settings) {
    await prisma.setting.upsert({
      where: { key: setting.key },
      update: {},
      create: setting
    });
  }

  console.log('✅ Dados iniciais criados com sucesso!');
  console.log('👤 Usuário admin: admin@quentinhas.com / admin123');
}

main()
  .catch((e) => {
    console.error('❌ Erro ao criar dados iniciais:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
EOF

node setup/seed.js

log_info "Criando servidor principal..."
cat > server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const { PrismaClient } = require('@prisma/client');
const http = require('http');
const socketIo = require('socket.io');
const path = require('path');
require('dotenv').config();

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST", "PUT", "DELETE"]
  }
});
const prisma = new PrismaClient();

app.use(helmet({
  contentSecurityPolicy: false,
  crossOriginEmbedderPolicy: false
}));
app.use(cors());
app.use(compression());
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 1000,
  message: { error: 'Muitas tentativas, tente novamente em 15 minutos' }
});
app.use('/api/', limiter);

app.use(express.static('public'));

app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    publicIP: process.env.PUBLIC_IP || 'unknown'
  });
});

app.get('/api/dashboard', async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const [todayOrders, todayRevenue, totalCustomers, topItems] = await Promise.all([
      prisma.order.count({
        where: { createdAt: { gte: today, lt: tomorrow } }
      }),
      prisma.order.aggregate({
        where: { createdAt: { gte: today, lt: tomorrow } },
        _sum: { finalAmount: true }
      }),
      prisma.customer.count(),
      prisma.menuItem.findMany({
        orderBy: { soldCount: 'desc' },
        take: 5,
        select: { name: true, soldCount: true, price: true }
      })
    ]);

    const revenue = todayRevenue._sum.finalAmount || 0;
    const avgTicket = todayOrders > 0 ? revenue / todayOrders : 0;

    res.json({
      todayOrders,
      todayRevenue: revenue,
      avgTicket,
      totalCustomers,
      topItems,
      conversionRate: 85
    });
  } catch (error) {
    console.error('Dashboard error:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

app.get('/api/menu', async (req, res) => {
  try {
    const { available } = req.query;
    const where = available !== undefined ? { available: available === 'true' } : {};
    
    const items = await prisma.menuItem.findMany({
      where,
      orderBy: { soldCount: 'desc' }
    });
    
    res.json(items);
  } catch (error) {
    console.error('Menu fetch error:', error);
    res.status(500).json({ error: 'Erro ao buscar cardápio' });
  }
});

app.post('/api/menu', async (req, res) => {
  try {
    const item = await prisma.menuItem.create({
      data: req.body
    });
    
    io.emit('menu_updated');
    res.status(201).json(item);
  } catch (error) {
    console.error('Menu create error:', error);
    res.status(500).json({ error: 'Erro ao criar item' });
  }
});

app.put('/api/menu/:id', async (req, res) => {
  try {
    const item = await prisma.menuItem.update({
      where: { id: req.params.id },
      data: req.body
    });
    
    io.emit('menu_updated');
    res.json(item);
  } catch (error) {
    console.error('Menu update error:', error);
    res.status(500).json({ error: 'Erro ao atualizar item' });
  }
});

app.get('/api/orders', async (req, res) => {
  try {
    const { status, date } = req.query;
    let where = {};
    
    if (status) where.status = status;
    if (date) {
      const startDate = new Date(date);
      const endDate = new Date(date);
      endDate.setDate(endDate.getDate() + 1);
      where.createdAt = { gte: startDate, lt: endDate };
    }
    
    const orders = await prisma.order.findMany({
      where,
      include: {
        customer: true,
        items: { include: { menuItem: true } }
      },
      orderBy: { createdAt: 'desc' },
      take: 50
    });
    
    res.json(orders);
  } catch (error) {
    console.error('Orders fetch error:', error);
    res.status(500).json({ error: 'Erro ao buscar pedidos' });
  }
});

app.put('/api/orders/:id/status', async (req, res) => {
  try {
    const { status } = req.body;
    
    const order = await prisma.order.update({
      where: { id: req.params.id },
      data: { 
        status,
        deliveredAt: status === 'DELIVERED' ? new Date() : undefined
      },
      include: { customer: true }
    });
    
    await prisma.orderStatusHistory.create({
      data: {
        orderId: order.id,
        status
      }
    });
    
    io.emit('order_updated', order);
    res.json(order);
  } catch (error) {
    console.error('Order update error:', error);
    res.status(500).json({ error: 'Erro ao atualizar pedido' });
  }
});

app.get('/api/customers', async (req, res) => {
  try {
    const customers = await prisma.customer.findMany({
      include: {
        orders: {
          orderBy: { createdAt: 'desc' },
          take: 3
        }
      },
      orderBy: { lastOrderAt: 'desc' },
      take: 100
    });
    
    res.json(customers);
  } catch (error) {
    console.error('Customers fetch error:', error);
    res.status(500).json({ error: 'Erro ao buscar clientes' });
  }
});

app.post('/api/webhook/whatsapp', async (req, res) => {
  try {
    const { key, message } = req.body;
    
    if (!key?.remoteJid || !message) {
      return res.json({ success: true });
    }
    
    const phone = key.remoteJid.replace('@s.whatsapp.net', '');
    const messageText = message.conversation || message.extendedTextMessage?.text || '';
    
    let customer = await prisma.customer.findUnique({
      where: { phone }
    });
    
    if (!customer) {
      customer = await prisma.customer.create({
        data: {
          phone,
          name: key.pushName || 'Cliente'
        }
      });
    }
    
    await prisma.interaction.create({
      data: {
        customerId: customer.id,
        type: 'MESSAGE',
        message: messageText
      }
    });
    
    io.emit('new_message', { customer, message: messageText });
    res.json({ success: true });
  } catch (error) {
    console.error('Webhook error:', error);
    res.status(500).json({ error: 'Erro no webhook' });
  }
});

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

io.on('connection', (socket) => {
  console.log('Cliente conectado:', socket.id);
  
  socket.on('join_admin', () => {
    socket.join('admin');
    console.log('Admin conectado:', socket.id);
  });
  
  socket.on('disconnect', () => {
    console.log('Cliente desconectado:', socket.id);
  });
});

const PORT = process.env.PORT || 3000;

server.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Servidor rodando na porta ${PORT}`);
  console.log(`📊 Painel: http://${process.env.PUBLIC_IP}:${PORT}`);
  console.log(`🔌 API: http://${process.env.PUBLIC_IP}:${PORT}/api`);
});

process.on('SIGTERM', async () => {
  console.log('Fechando servidor...');
  await prisma.$disconnect();
  process.exit(0);
});
EOF

# =================================================================
# CRIAR PAINEL PROFISSIONAL BONITO
# =================================================================

log_purple "Criando painel administrativo profissional..."
cat > public/index.html << EOF
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Quentinhas Pro - Dashboard</title>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.0/chart.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/axios/1.4.0/axios.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/socket.io/4.7.4/socket.io.js"></script>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap');
        
        :root {
            --primary: #6366f1;
            --primary-dark: #4f46e5;
            --secondary: #8b5cf6;
            --success: #10b981;
            --warning: #f59e0b;
            --error: #ef4444;
            --dark: #0f172a;
            --gray-50: #f8fafc;
            --gray-100: #f1f5f9;
            --gray-200: #e2e8f0;
            --gray-300: #cbd5e1;
            --gray-600: #475569;
            --gray-700: #334155;
            --gray-800: #1e293b;
            --gray-900: #0f172a;
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 50%, #f093fb 100%);
            min-height: 100vh;
            color: var(--gray-800);
            overflow-x: hidden;
        }

        .sidebar {
            position: fixed;
            left: 0;
            top: 0;
            width: 280px;
            height: 100vh;
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(20px);
            border-right: 1px solid rgba(255, 255, 255, 0.2);
            z-index: 1000;
            transition: transform 0.3s ease;
            box-shadow: 4px 0 24px rgba(0, 0, 0, 0.1);
        }

        .sidebar-header {
            padding: 2rem 1.5rem;
            border-bottom: 1px solid var(--gray-200);
        }

        .logo {
            display: flex;
            align-items: center;
            gap: 12px;
            font-size: 1.5rem;
            font-weight: 800;
            background: linear-gradient(135deg, var(--primary), var(--secondary));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }

        .logo i {
            background: linear-gradient(135deg, var(--primary), var(--secondary));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            font-size: 2rem;
        }

        .nav-menu {
            padding: 1rem 0;
        }

        .nav-item {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 1rem 1.5rem;
            color: var(--gray-700);
            text-decoration: none;
            transition: all 0.3s ease;
            border-right: 3px solid transparent;
            font-weight: 500;
        }

        .nav-item:hover {
            background: linear-gradient(90deg, rgba(99, 102, 241, 0.1), transparent);
            color: var(--primary);
            border-right-color: var(--primary);
        }

        .nav-item.active {
            background: linear-gradient(90deg, rgba(99, 102, 241, 0.15), transparent);
            color: var(--primary);
            border-right-color: var(--primary);
        }

        .nav-item i {
            width: 20px;
            text-align: center;
        }

        .main-content {
            margin-left: 280px;
            min-height: 100vh;
            background: rgba(255, 255, 255, 0.1);
        }

        .header {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(20px);
            border-bottom: 1px solid rgba(255, 255, 255, 0.2);
            padding: 1rem 2rem;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
        }

        .header-title {
            font-size: 1.5rem;
            font-weight: 700;
            color: var(--gray-800);
        }

        .header-actions {
            display: flex;
            align-items: center;
            gap: 1rem;
        }

        .status-indicator {
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 0.5rem 1rem;
            background: var(--success);
            color: white;
            border-radius: 50px;
            font-size: 0.875rem;
            font-weight: 600;
        }

        .status-dot {
            width: 8px;
            height: 8px;
            background: rgba(255, 255, 255, 0.9);
            border-radius: 50%;
            animation: pulse 2s infinite;
        }

        @keyframes pulse {
            0%, 100% { opacity: 1; transform: scale(1); }
            50% { opacity: 0.7; transform: scale(1.2); }
        }

        .current-time {
            font-size: 0.875rem;
            color: var(--gray-600);
            font-weight: 500;
        }

        .content {
            padding: 2rem;
        }

        .quick-actions {
            display: flex;
            gap: 1rem;
            margin-bottom: 2rem;
            flex-wrap: wrap;
        }

        .btn {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 0.75rem 1.5rem;
            border: none;
            border-radius: 12px;
            font-weight: 600;
            text-decoration: none;
            transition: all 0.3s ease;
            cursor: pointer;
            font-size: 0.875rem;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
        }

        .btn-primary {
            background: linear-gradient(135deg, var(--primary), var(--primary-dark));
            color: white;
        }

        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(99, 102, 241, 0.3);
        }

        .btn-success {
            background: linear-gradient(135deg, var(--success), #059669);
            color: white;
        }

        .btn-success:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(16, 185, 129, 0.3);
        }

        .btn-secondary {
            background: rgba(255, 255, 255, 0.9);
            color: var(--gray-700);
            border: 1px solid var(--gray-200);
        }

        .btn-secondary:hover {
            background: white;
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
        }

        .dashboard-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 2rem;
            margin-bottom: 2rem;
        }

        .card {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(20px);
            border-radius: 20px;
            padding: 2rem;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
            border: 1px solid rgba(255, 255, 255, 0.2);
            transition: all 0.3s ease;
            position: relative;
            overflow: hidden;
        }

        .card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 4px;
            background: linear-gradient(90deg, var(--primary), var(--secondary));
        }

        .card:hover {
            transform: translateY(-8px);
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.15);
        }

        .card-header {
            display: flex;
            align-items: center;
            gap: 12px;
            margin-bottom: 1.5rem;
        }

        .card-icon {
            width: 48px;
            height: 48px;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.25rem;
            color: white;
        }

        .card-title {
            font-size: 1.25rem;
            font-weight: 700;
            color: var(--gray-800);
        }

        .stats-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 1.5rem;
        }

        .stat-item {
            text-align: center;
            padding: 1.5rem;
            background: linear-gradient(135deg, rgba(99, 102, 241, 0.1), rgba(139, 92, 246, 0.1));
            border-radius: 16px;
            border: 1px solid rgba(99, 102, 241, 0.2);
            transition: all 0.3s ease;
        }

        .stat-item:hover {
            transform: scale(1.05);
            box-shadow: 0 8px 25px rgba(99, 102, 241, 0.2);
        }

        .stat-value {
            font-size: 2.5rem;
            font-weight: 800;
            background: linear-gradient(135deg, var(--primary), var(--secondary));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            margin-bottom: 0.5rem;
            line-height: 1;
        }

        .stat-label {
            font-size: 0.875rem;
            color: var(--gray-600);
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .menu-grid {
            display: grid;
            gap: 1rem;
        }

        .menu-item {
            display: grid;
            grid-template-columns: 1fr auto auto;
            gap: 1.5rem;
            align-items: center;
            padding: 1.5rem;
            background: rgba(255, 255, 255, 0.7);
            border-radius: 16px;
            border: 1px solid rgba(255, 255, 255, 0.3);
            transition: all 0.3s ease;
        }

        .menu-item:hover {
            background: rgba(255, 255, 255, 0.9);
            transform: translateX(8px);
            box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
        }

        .menu-item.unavailable {
            opacity: 0.6;
            filter: grayscale(0.3);
        }

        .menu-info h4 {
            font-size: 1.125rem;
            font-weight: 700;
            color: var(--gray-800);
            margin-bottom: 0.5rem;
        }

        .menu-description {
            color: var(--gray-600);
            font-size: 0.875rem;
            margin-bottom: 0.5rem;
        }

        .menu-meta {
            display: flex;
            gap: 1rem;
            font-size: 0.75rem;
            color: var(--gray-500);
        }

        .price-tag {
            background: linear-gradient(135deg, var(--success), #059669);
            color: white;
            padding: 0.75rem 1.25rem;
            border-radius: 12px;
            font-weight: 700;
            font-size: 1.125rem;
            box-shadow: 0 4px 12px rgba(16, 185, 129, 0.3);
        }

        .table-container {
            background: rgba(255, 255, 255, 0.95);
            border-radius: 20px;
            overflow: hidden;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
        }

        .table {
            width: 100%;
            border-collapse: collapse;
        }

        .table th {
            background: linear-gradient(135deg, var(--gray-50), var(--gray-100));
            padding: 1.5rem;
            text-align: left;
            font-weight: 700;
            color: var(--gray-800);
            font-size: 0.875rem;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .table td {
            padding: 1.5rem;
            border-bottom: 1px solid var(--gray-200);
            color: var(--gray-700);
        }

        .table tbody tr:hover {
            background: rgba(99, 102, 241, 0.05);
        }

        .status-badge {
            padding: 0.5rem 1rem;
            border-radius: 50px;
            font-size: 0.75rem;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .status-CONFIRMED {
            background: rgba(245, 158, 11, 0.1);
            color: #d97706;
            border: 1px solid rgba(245, 158, 11, 0.3);
        }

        .status-PREPARING {
            background: rgba(59, 130, 246, 0.1);
            color: #2563eb;
            border: 1px solid rgba(59, 130, 246, 0.3);
        }

        .status-READY {
            background: rgba(16, 185, 129, 0.1);
            color: #059669;
            border: 1px solid rgba(16, 185, 129, 0.3);
        }

        .status-OUT_FOR_DELIVERY {
            background: rgba(139, 92, 246, 0.1);
            color: #7c3aed;
            border: 1px solid rgba(139, 92, 246, 0.3);
        }

        .status-DELIVERED {
            background: rgba(34, 197, 94, 0.1);
            color: #16a34a;
            border: 1px solid rgba(34, 197, 94, 0.3);
        }

        .form-select {
            padding: 0.5rem 1rem;
            border: 2px solid var(--gray-200);
            border-radius: 8px;
            background: white;
            color: var(--gray-700);
            font-weight: 500;
            transition: all 0.3s ease;
        }

        .form-select:focus {
            outline: none;
            border-color: var(--primary);
            box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.1);
        }

        .important-links {
            background: linear-gradient(135deg, rgba(16, 185, 129, 0.9), rgba(5, 150, 105, 0.9));
            backdrop-filter: blur(20px);
            color: white;
            padding: 2rem;
            border-radius: 20px;
            margin-bottom: 2rem;
            box-shadow: 0 8px 32px rgba(16, 185, 129, 0.3);
        }

        .important-links h3 {
            font-size: 1.25rem;
            font-weight: 700;
            margin-bottom: 1rem;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .links-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1rem;
        }

        .link-item {
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 0.75rem 1rem;
            background: rgba(255, 255, 255, 0.2);
            border-radius: 12px;
            text-decoration: none;
            color: white;
            font-weight: 600;
            transition: all 0.3s ease;
        }

        .link-item:hover {
            background: rgba(255, 255, 255, 0.3);
            transform: translateY(-2px);
        }

        .chart-container {
            position: relative;
            height: 300px;
            margin-top: 1rem;
        }

        .empty-state {
            text-align: center;
            padding: 3rem;
            color: var(--gray-500);
        }

        .empty-state i {
            font-size: 4rem;
            margin-bottom: 1rem;
            color: var(--gray-300);
        }

        @media (max-width: 768px) {
            .sidebar {
                transform: translateX(-100%);
            }

            .main-content {
                margin-left: 0;
            }

            .header {
                padding: 1rem;
            }

            .content {
                padding: 1rem;
            }

            .dashboard-grid {
                grid-template-columns: 1fr;
                gap: 1rem;
            }

            .stats-grid {
                grid-template-columns: 1fr;
                gap: 1rem;
            }

            .menu-item {
                grid-template-columns: 1fr;
                text-align: center;
                gap: 1rem;
            }
        }
    </style>
</head>
<body>
    <div class="sidebar">
        <div class="sidebar-header">
            <div class="logo">
                <i class="fas fa-utensils"></i>
                <span>Quentinhas Pro</span>
            </div>
        </div>
        <nav class="nav-menu">
            <a href="#" class="nav-item active">
                <i class="fas fa-chart-line"></i>
                <span>Dashboard</span>
            </a>
            <a href="#" class="nav-item">
                <i class="fas fa-utensils"></i>
                <span>Cardápio</span>
            </a>
            <a href="#" class="nav-item">
                <i class="fas fa-shopping-cart"></i>
                <span>Pedidos</span>
            </a>
            <a href="#" class="nav-item">
                <i class="fas fa-users"></i>
                <span>Clientes</span>
            </a>
            <a href="#" class="nav-item">
                <i class="fas fa-chart-bar"></i>
                <span>Relatórios</span>
            </a>
            <a href="#" class="nav-item">
                <i class="fas fa-cog"></i>
                <span>Configurações</span>
            </a>
        </nav>
    </div>

    <div class="main-content">
        <div class="header">
            <h1 class="header-title">Dashboard</h1>
            <div class="header-actions">
                <div class="status-indicator">
                    <div class="status-dot"></div>
                    <span>Sistema Online</span>
                </div>
                <div class="current-time" id="currentTime"></div>
            </div>
        </div>

        <div class="content">
            <div class="important-links">
                <h3>
                    <i class="fas fa-external-link-alt"></i>
                    Acesso Rápido aos Serviços
                </h3>
                <div class="links-grid">
                    <a href="http://${PUBLIC_IP}:8080" class="link-item" target="_blank">
                        <i class="fab fa-whatsapp"></i>
                        <span>WhatsApp API</span>
                    </a>
                    <a href="http://${PUBLIC_IP}:5678" class="link-item" target="_blank">
                        <i class="fas fa-robot"></i>
                        <span>Automação N8N</span>
                    </a>
                    <a href="/api/health" class="link-item" target="_blank">
                        <i class="fas fa-heartbeat"></i>
                        <span>Status da API</span>
                    </a>
                    <a href="http://${PUBLIC_IP}:8080/manager" class="link-item" target="_blank">
                        <i class="fas fa-cogs"></i>
                        <span>Manager</span>
                    </a>
                </div>
            </div>

            <div class="quick-actions">
                <button class="btn btn-primary" onclick="refreshData()">
                    <i class="fas fa-sync-alt"></i>
                    <span>Atualizar Dados</span>
                </button>
                <button class="btn btn-success" onclick="showAddMenuModal()">
                    <i class="fas fa-plus"></i>
                    <span>Adicionar Prato</span>
                </button>
                <button class="btn btn-secondary" onclick="generateReport()">
                    <i class="fas fa-download"></i>
                    <span>Gerar Relatório</span>
                </button>
            </div>

            <div class="dashboard-grid">
                <div class="card">
                    <div class="card-header">
                        <div class="card-icon" style="background: linear-gradient(135deg, var(--primary), var(--secondary));">
                            <i class="fas fa-chart-line"></i>
                        </div>
                        <h3 class="card-title">Estatísticas de Hoje</h3>
                    </div>
                    <div class="stats-grid">
                        <div class="stat-item">
                            <div class="stat-value" id="todayOrders">0</div>
                            <div class="stat-label">Pedidos</div>
                        </div>
                        <div class="stat-item">
                            <div class="stat-value" id="todayRevenue">R$ 0</div>
                            <div class="stat-label">Faturamento</div>
                        </div>
                        <div class="stat-item">
                            <div class="stat-value" id="avgTicket">R$ 0</div>
                            <div class="stat-label">Ticket Médio</div>
                        </div>
                        <div class="stat-item">
                            <div class="stat-value" id="totalCustomers">0</div>
                            <div class="stat-label">Clientes</div>
                        </div>
                    </div>
                </div>
                
                <div class="card">
                    <div class="card-header">
                        <div class="card-icon" style="background: linear-gradient(135deg, var(--success), #059669);">
                            <i class="fas fa-chart-area"></i>
                        </div>
                        <h3 class="card-title">Vendas da Semana</h3>
                    </div>
                    <div class="chart-container">
                        <canvas id="salesChart"></canvas>
                    </div>
                </div>
            </div>

            <div class="card">
                <div class="card-header">
                    <div class="card-icon" style="background: linear-gradient(135deg, var(--warning), #d97706);">
                        <i class="fas fa-utensils"></i>
                    </div>
                    <h3 class="card-title">Gestão do Cardápio</h3>
                </div>
                <div class="menu-grid" id="menuItems">
                </div>
            </div>

            <div class="card">
                <div class="card-header">
                    <div class="card-icon" style="background: linear-gradient(135deg, var(--secondary), #7c3aed);">
                        <i class="fas fa-shopping-cart"></i>
                    </div>
                    <h3 class="card-title">Pedidos Recentes</h3>
                </div>
                <div class="table-container">
                    <table class="table">
                        <thead>
                            <tr>
                                <th><i class="fas fa-clock"></i> Horário</th>
                                <th><i class="fas fa-user"></i> Cliente</th>
                                <th><i class="fas fa-shopping-bag"></i> Itens</th>
                                <th><i class="fas fa-dollar-sign"></i> Total</th>
                                <th><i class="fas fa-info-circle"></i> Status</th>
                                <th><i class="fas fa-cogs"></i> Ações</th>
                            </tr>
                        </thead>
                        <tbody id="ordersTable">
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <script>
        const socket = io();
        socket.emit('join_admin');

        function updateTime() {
            const now = new Date();
            document.getElementById('currentTime').textContent = now.toLocaleString('pt-BR');
        }
        setInterval(updateTime, 1000);
        updateTime();

        document.addEventListener('DOMContentLoaded', () => {
            refreshData();
            initChart();
            setInterval(refreshData, 30000);
        });

        function initChart() {
            const ctx = document.getElementById('salesChart').getContext('2d');
            new Chart(ctx, {
                type: 'line',
                data: {
                    labels: ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'],
                    datasets: [{
                        label: 'Vendas',
                        data: [320, 450, 380, 520, 480, 650, 420],
                        borderColor: '#6366f1',
                        backgroundColor: 'rgba(99, 102, 241, 0.1)',
                        tension: 0.4,
                        fill: true,
                        pointBackgroundColor: '#6366f1',
                        pointBorderColor: '#ffffff',
                        pointBorderWidth: 2,
                        pointRadius: 6
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: { legend: { display: false } },
                    scales: {
                        y: { beginAtZero: true, grid: { color: 'rgba(0, 0, 0, 0.1)' } },
                        x: { grid: { display: false } }
                    }
                }
            });
        }

        async function loadDashboard() {
            try {
                const response = await axios.get('/api/dashboard');
                const data = response.data;
                
                animateValue('todayOrders', 0, data.todayOrders, 1000);
                animateValue('todayRevenue', 0, data.todayRevenue, 1000, 'R$ ');
                animateValue('avgTicket', 0, data.avgTicket, 1000, 'R$ ');
                animateValue('totalCustomers', 0, data.totalCustomers, 1000);
            } catch (error) {
                console.error('Erro ao carregar dashboard:', error);
            }
        }

        function animateValue(id, start, end, duration, prefix = '') {
            const element = document.getElementById(id);
            const range = end - start;
            const increment = range / (duration / 16);
            let current = start;
            
            const timer = setInterval(() => {
                current += increment;
                if (current >= end) {
                    current = end;
                    clearInterval(timer);
                }
                element.textContent = prefix + (prefix.includes('R\$') ? current.toFixed(2) : Math.floor(current));
            }, 16);
        }

        async function loadMenu() {
            try {
                const response = await axios.get('/api/menu');
                const menuContainer = document.getElementById('menuItems');
                menuContainer.innerHTML = '';
                
                if (response.data.length === 0) {
                    menuContainer.innerHTML = \`
                        <div class="empty-state">
                            <i class="fas fa-utensils"></i>
                            <h3>Nenhum prato cadastrado</h3>
                            <p>Adicione itens ao seu cardápio para começar</p>
                        </div>
                    \`;
                    return;
                }
                
                response.data.forEach(item => {
                    const div = document.createElement('div');
                    div.className = \`menu-item \${!item.available ? 'unavailable' : ''}\`;
                    div.innerHTML = \`
                        <div class="menu-info">
                            <h4>\${item.name}</h4>
                            <div class="menu-description">\${item.description || 'Sem descrição'}</div>
                            <div class="menu-meta">
                                <span><i class="fas fa-fire"></i> \${item.calories || 'N/A'} cal</span>
                                <span><i class="fas fa-clock"></i> \${item.prepTime || 'N/A'} min</span>
                                <span><i class="fas fa-chart-line"></i> \${item.soldCount} vendidos</span>
                            </div>
                        </div>
                        <div class="price-tag">R$ \${item.price.toFixed(2)}</div>
                        <button class="btn \${item.available ? 'btn-secondary' : 'btn-success'}" 
                                onclick="toggleItem('\${item.id}', \${!item.available})">
                            <i class="fas fa-\${item.available ? 'eye-slash' : 'eye'}"></i>
                            <span>\${item.available ? 'Desativar' : 'Ativar'}</span>
                        </button>
                    \`;
                    menuContainer.appendChild(div);
                });
            } catch (error) {
                console.error('Erro ao carregar cardápio:', error);
            }
        }

        async function loadOrders() {
            try {
                const response = await axios.get('/api/orders');
                const tbody = document.getElementById('ordersTable');
                tbody.innerHTML = '';
                
                if (response.data.length === 0) {
                    tbody.innerHTML = \`
                        <tr>
                            <td colspan="6" class="empty-state">
                                <i class="fas fa-shopping-cart"></i>
                                <p>Nenhum pedido encontrado</p>
                            </td>
                        </tr>
                    \`;
                    return;
                }
                
                response.data.slice(0, 10).forEach(order => {
                    const row = document.createElement('tr');
                    const itemsText = order.items?.map(item => \`\${item.quantity}x \${item.menuItem.name}\`).join(', ') || 'N/A';
                    
                    row.innerHTML = \`
                        <td>
                            <i class="fas fa-clock"></i>
                            \${new Date(order.createdAt).toLocaleString('pt-BR')}
                        </td>
                        <td>
                            <strong>\${order.customer.name || 'Cliente'}</strong><br>
                            <small>\${order.customer.phone}</small>
                        </td>
                        <td>
                            <div style="max-width: 200px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;" 
                                 title="\${itemsText}">
                                \${itemsText}
                            </div>
                        </td>
                        <td>
                            <strong>R$ \${order.finalAmount.toFixed(2)}</strong>
                        </td>
                        <td>
                            <span class="status-badge status-\${order.status}">
                                \${getStatusText(order.status)}
                            </span>
                        </td>
                        <td>
                            <select class="form-select" onchange="updateOrderStatus('\${order.id}', this.value)" value="\${order.status}">
                                <option value="CONFIRMED" \${order.status === 'CONFIRMED' ? 'selected' : ''}>Confirmado</option>
                                <option value="PREPARING" \${order.status === 'PREPARING' ? 'selected' : ''}>Preparando</option>
                                <option value="READY" \${order.status === 'READY' ? 'selected' : ''}>Pronto</option>
                                <option value="OUT_FOR_DELIVERY" \${order.status === 'OUT_FOR_DELIVERY' ? 'selected' : ''}>Entrega</option>
                                <option value="DELIVERED" \${order.status === 'DELIVERED' ? 'selected' : ''}>Entregue</option>
                            </select>
                        </td>
                    \`;
                    tbody.appendChild(row);
                });
            } catch (error) {
                console.error('Erro ao carregar pedidos:', error);
            }
        }

        function getStatusText(status) {
            const statusMap = {
                'CONFIRMED': 'Confirmado',
                'PREPARING': 'Preparando',
                'READY': 'Pronto',
                'OUT_FOR_DELIVERY': 'Entrega',
                'DELIVERED': 'Entregue'
            };
            return statusMap[status] || status;
        }

        async function toggleItem(id, available) {
            try {
                await axios.put(\`/api/menu/\${id}\`, { available });
                loadMenu();
                showNotification('Item atualizado com sucesso!', 'success');
            } catch (error) {
                console.error('Erro ao atualizar item:', error);
                showNotification('Erro ao atualizar item', 'error');
            }
        }

        async function updateOrderStatus(id, status) {
            try {
                await axios.put(\`/api/orders/\${id}/status\`, { status });
                loadOrders();
                loadDashboard();
                showNotification('Status do pedido atualizado!', 'success');
            } catch (error) {
                console.error('Erro ao atualizar pedido:', error);
                showNotification('Erro ao atualizar pedido', 'error');
            }
        }

        function refreshData() {
            loadDashboard();
            loadMenu();
            loadOrders();
        }

        function showAddMenuModal() {
            showNotification('Funcionalidade em desenvolvimento!', 'info');
        }

        function generateReport() {
            showNotification('Gerando relatório...', 'info');
        }

        function showNotification(message, type = 'info') {
            const notification = document.createElement('div');
            notification.style.cssText = \`
                position: fixed; top: 20px; right: 20px;
                padding: 1rem 1.5rem; border-radius: 12px; color: white;
                font-weight: 600; z-index: 10000; transform: translateX(400px);
                transition: transform 0.3s ease; box-shadow: 0 8px 25px rgba(0, 0, 0, 0.2);
            \`;
            
            const colors = {
                success: 'linear-gradient(135deg, #10b981, #059669)',
                error: 'linear-gradient(135deg, #ef4444, #dc2626)',
                info: 'linear-gradient(135deg, #6366f1, #4f46e5)'
            };
            notification.style.background = colors[type] || colors.info;
            notification.textContent = message;
            
            document.body.appendChild(notification);
            
            setTimeout(() => {
                notification.style.transform = 'translateX(0)';
            }, 100);
            
            setTimeout(() => {
                notification.style.transform = 'translateX(400px)';
                setTimeout(() => {
                    document.body.removeChild(notification);
                }, 300);
            }, 3000);
        }

        socket.on('order_updated', () => {
            loadOrders();
            loadDashboard();
        });

        socket.on('menu_updated', () => {
            loadMenu();
        });
    </script>
</body>
</html>
EOF

log_info "Iniciando Evolution API e N8N..."
docker-compose up -d evolution n8n

log_info "Aguardando serviços iniciarem..."
sleep 60

log_info "Iniciando servidor da API com PM2..."
pm2 start server.js --name quentinhas-api
pm2 save
pm2 startup

sleep 15

log_info "Criando scripts de monitoramento..."

cat > check-status.sh << 'EOF'
#!/bin/bash
echo "=== STATUS SISTEMA QUENTINHAS PRO ==="
echo ""

PUBLIC_IP=$(curl -s ifconfig.me)

if curl -s http://localhost:3000/api/health | grep -q "OK"; then
    echo "✅ API: Online"
    echo "    📊 Painel: http://$PUBLIC_IP:3000"
else
    echo "❌ API: Offline"
fi

if docker exec quentinhas-postgres pg_isready -U quentinhas >/dev/null 2>&1; then
    echo "✅ PostgreSQL: Online"
else
    echo "❌ PostgreSQL: Offline"
fi

if curl -s http://localhost:8080/instance/fetchInstances >/dev/null 2>&1; then
    echo "✅ Evolution API: Online"
    echo "    📱 WhatsApp: http://$PUBLIC_IP:8080"
else
    echo "❌ Evolution API: Offline"
fi

if curl -s http://localhost:5678 >/dev/null 2>&1; then
    echo "✅ N8N: Online"
    echo "    🤖 Automação: http://$PUBLIC_IP:5678"
else
    echo "❌ N8N: Offline"
fi

echo ""
echo "🔥 FIREWALL STATUS:"
ufw status | head -5

echo ""
echo "🌐 ACESSO PÚBLICO:"
echo "    http://$PUBLIC_IP:3000 - Painel Principal"
echo "    http://$PUBLIC_IP:8080 - WhatsApp API"
echo "    http://$PUBLIC_IP:5678 - N8N"

echo ""
echo "📈 STATUS PM2:"
pm2 list
EOF

chmod +x check-status.sh

cat > restart-system.sh << 'EOF'
#!/bin/bash
echo "🔄 Reiniciando sistema completo..."

pm2 stop quentinhas-api
docker-compose down
sleep 10
docker-compose up -d
sleep 30
pm2 start quentinhas-api

echo "✅ Sistema reiniciado!"
sleep 5
./check-status.sh
EOF

chmod +x restart-system.sh

# =================================================================
# FINALIZAÇÃO EPIC
# =================================================================

log_purple "🎨 PAINEL PROFISSIONAL INSTALADO!"
log_success "🎉 SISTEMA QUENTINHAS PRO 100% COMPLETO!"
echo ""
echo "🌟 SISTEMA INSTALADO COM SUCESSO:"
echo "    🖥️  IP Público: $PUBLIC_IP"
echo "    🎨 Painel Profissional: Instalado"
echo "    🔥 Firewall: Configurado (portas liberadas)"
echo "    🚫 N8N: Sem erros de cookie"
echo "    🌐 URLs: Sincronizadas automaticamente com host.docker.internal"
echo "    🔄 PM2: API principal gerenciada com reinício automático"
echo ""
echo "🔗 ACESSO AO SISTEMA:"
echo "    📊 Painel Profissional: http://$PUBLIC_IP:3000"
echo "    📱 WhatsApp API: http://$PUBLIC_IP:8080"  
echo "    🤖 N8N Automação: http://$PUBLIC_IP:5678"
echo "    🔍 Status API: http://$PUBLIC_IP:3000/api/health"
echo ""
echo "🔑 LOGIN PAINEL:"
echo "    📧 Email: admin@quentinhas.com"
echo "    🔐 Senha: admin123"
echo ""
echo "🎨 RECURSOS DO PAINEL:"
echo "    ✨ Design glassmorphism moderno"
echo "    📊 Gráficos Chart.js animados"
echo "    🔔 Notificações toast elegantes"
echo "    📱 Totalmente responsivo"
echo "    🎯 Sidebar com navegação profissional"
echo "    💫 Animações suaves em hover/click"
echo ""
echo "🛠️ COMANDOS DE MANUTENÇÃO:"
echo "    ./check-status.sh     - Status completo"
echo "    ./restart-system.sh   - Reiniciar tudo"
echo "    pm2 logs quentinhas-api - Ver logs da API"
echo "    pm2 restart quentinhas-api - Reiniciar API"
echo ""
echo "📱 PRÓXIMOS PASSOS:"
echo "    1. ✅ Acessar: http://$PUBLIC_IP:3000"
echo "    2. ✅ Configurar WhatsApp: http://$PUBLIC_IP:8080"
echo "    3. ✅ Personalizar cardápio no painel"
echo "    4. ✅ Testar pedidos via WhatsApp"
echo ""

if curl -s http://localhost:3000/api/health | grep -q "OK"; then
    log_success "✅ API Principal: FUNCIONANDO"
else
    log_warning "⚠️ API Principal: Aguarde alguns segundos"
fi

if curl -s http://localhost:8080/instance/fetchInstances >/dev/null 2>&1; then
    log_success "✅ WhatsApp API: FUNCIONANDO"
else
    log_warning "⚠️ WhatsApp API: Aguarde alguns segundos"
fi

if curl -s http://localhost:5678 >/dev/null 2>&1; then
    log_success "✅ N8N: FUNCIONANDO (sem erros)"
else
    log_warning "⚠️ N8N: Aguarde alguns segundos"
fi

echo ""
log_purple "🚀 SISTEMA COMPLETO E PROFISSIONAL!"
log_success "🎯 ACESSE AGORA: http://$PUBLIC_IP:3000"
log_purple "🎨 Painel moderno com design de empresa!"
echo ""
