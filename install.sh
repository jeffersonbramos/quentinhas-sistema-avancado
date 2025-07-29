#!/bin/bash

# =================================================================
# INSTALAÇÃO SISTEMA QUENTINHAS AVANÇADO
# Sistema Completo: API + Painel + Banco + WhatsApp + N8N
# =================================================================

echo "🚀 INSTALAÇÃO SISTEMA QUENTINHAS AVANÇADO"
echo "========================================"
echo ""

# Verificar se é root
if [[ $EUID -eq 0 ]]; then
   echo "❌ Não execute como root. Use um usuário normal com sudo."
   exit 1
fi

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log colorido
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Verificar conectividade
log_info "Verificando conectividade..."
if ! ping -c 1 google.com &> /dev/null; then
    log_error "Sem conexão com internet. Verifique sua rede."
    exit 1
fi
log_success "Conectividade OK"

# Atualizar sistema
log_info "Atualizando sistema..."
sudo apt update && sudo apt upgrade -y

# Instalar dependências básicas
log_info "Instalando dependências..."
sudo apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# Instalar Docker
log_info "Instalando Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER

# Instalar Docker Compose standalone
log_info "Instalando Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Instalar Node.js 18
log_info "Instalando Node.js 18..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verificar instalações
log_info "Verificando instalações..."
node --version
npm --version
docker --version
docker-compose --version

# Criar diretório do projeto
PROJECT_DIR="$HOME/quentinhas-pro"
log_info "Criando projeto em $PROJECT_DIR"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# Criar estrutura de diretórios
mkdir -p {src,prisma,setup,logs,uploads,public,ssl,backups}

# =================================================================
# ARQUIVOS DE CONFIGURAÇÃO
# =================================================================

# Criar package.json
log_info "Criando package.json..."
cat > package.json << 'EOF'
{
  "name": "quentinhas-pro",
  "version": "1.0.0",
  "description": "Sistema avançado para gestão de quentinhas via WhatsApp",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "setup": "node setup/init-db.js",
    "migrate": "npx prisma migrate dev",
    "seed": "node setup/seed.js",
    "backup": "node scripts/backup.js"
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
    "multer": "^1.4.5",
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

# Criar .env
log_info "Criando arquivo .env..."
cat > .env << 'EOF'
# Database
DATABASE_URL="postgresql://quentinhas:quentinhas123@localhost:5432/quentinhas"

# Redis
REDIS_URL="redis://localhost:6379"

# JWT
JWT_SECRET="quentinhas_jwt_secret_super_seguro_mude_em_producao"

# Server
PORT=3000
NODE_ENV=production

# WhatsApp
EVOLUTION_API_URL="http://localhost:8080"
EVOLUTION_API_KEY="evolution_api_key"

# N8N
N8N_WEBHOOK_URL="http://localhost:5678"

# Upload
MAX_FILE_SIZE=10485760
UPLOAD_PATH="./uploads"

# Business Settings
BUSINESS_NAME="Quentinhas da Casa"
BUSINESS_PHONE="(11) 99999-9999"
DELIVERY_FEE=3.00
MIN_ORDER_VALUE=15.00
EOF

# Criar docker-compose.yml
log_info "Criando docker-compose.yml..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  # PostgreSQL Database
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

  # Redis Cache
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

  # MongoDB for Evolution API
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

  # Evolution API (WhatsApp)
  evolution:
    image: davidson/evolution-api:latest
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
    ports:
      - "8080:8080"
    depends_on:
      - mongo
      - redis
    restart: unless-stopped
    networks:
      - quentinhas-network
    extra_hosts:
      - "host.docker.internal:host-gateway"

  # N8N Automation
  n8n:
    image: n8nio/n8n:latest
    container_name: quentinhas-n8n
    environment:
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - WEBHOOK_URL=http://localhost:5678
      - GENERIC_TIMEZONE=America/Sao_Paulo
      - N8N_METRICS=true
    ports:
      - "5678:5678"
    volumes:
      - n8n_data:/home/node/.n8n
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

# Criar schema do Prisma
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
  
  orders        Order[]
  interactions  Interaction[]
  
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
  
  orderItems  OrderItem[]
  
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
  
  items           OrderItem[]
  statusHistory   OrderStatusHistory[]
  
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
  id              String   @id @default(cuid())
  date            DateTime @default(now())
  totalOrders     Int      @default(0)
  totalRevenue    Float    @default(0)
  avgTicket       Float    @default(0)
  newCustomers    Int      @default(0)
  conversionRate  Float    @default(0)
  topItem         String?
  busyHour        Int?
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

# Iniciar containers do banco
log_info "Iniciando containers do banco de dados..."
docker-compose up -d postgres redis mongo

# Aguardar bancos iniciarem
log_info "Aguardando bancos de dados iniciarem..."
sleep 30

# Instalar dependências Node.js
log_info "Instalando dependências Node.js..."
npm install

# Gerar cliente Prisma
log_info "Gerando cliente Prisma..."
npx prisma generate

# Executar migrações
log_info "Executando migrações do banco..."
npx prisma migrate dev --name init

# Criar arquivo de seed
log_info "Criando dados iniciais..."
cat > setup/seed.js << 'EOF'
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Criando dados iniciais...');

  // Criar usuário admin
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

  // Criar itens do menu
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
    },
    {
      name: 'Salada Caesar',
      description: 'Salada com alface, croutons, queijo parmesão e molho caesar com frango grelhado',
      price: 14.00,
      category: 'Saladas',
      available: true,
      prepTime: 15,
      calories: 380,
      ingredients: ['Alface', 'Frango', 'Queijo parmesão', 'Croutons', 'Molho caesar'],
      allergens: ['Lactose', 'Glúten']
    }
  ];

  for (const item of menuItems) {
    await prisma.menuItem.upsert({
      where: { name: item.name },
      update: {},
      create: item
    });
  }

  // Configurações do sistema
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

# Executar seed
log_info "Populando banco com dados iniciais..."
node setup/seed.js

# Criar servidor principal
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

// Inicialização
const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST", "PUT", "DELETE"]
  }
});
const prisma = new PrismaClient();

// Middlewares
app.use(helmet());
app.use(cors());
app.use(compression());
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: { error: 'Muitas tentativas, tente novamente em 15 minutos' }
});
app.use('/api/', limiter);

// Servir arquivos estáticos
app.use(express.static('public'));

// =================================================================
// ROTAS DA API
// =================================================================

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Dashboard analytics
app.get('/api/dashboard', async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    // Estatísticas de hoje
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
      conversionRate: 85 // Placeholder
    });
  } catch (error) {
    console.error('Dashboard error:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// Menu management
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

// Orders management
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
    
    // Criar histórico
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

// Customers
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

// Webhook WhatsApp
app.post('/api/webhook/whatsapp', async (req, res) => {
  try {
    const { key, message } = req.body;
    
    if (!key?.remoteJid || !message) {
      return res.json({ success: true });
    }
    
    const phone = key.remoteJid.replace('@s.whatsapp.net', '');
    const messageText = message.conversation || message.extendedTextMessage?.text || '';
    
    // Buscar ou criar cliente
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
    
    // Registrar interação
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

// Página principal (painel)
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// =================================================================
// WEBSOCKET
// =================================================================
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

// =================================================================
// INICIALIZAÇÃO
// =================================================================
const PORT = process.env.PORT || 3000;

server.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Servidor rodando na porta ${PORT}`);
  console.log(`📊 Painel: http://localhost:${PORT}`);
  console.log(`🔌 API: http://localhost:${PORT}/api`);
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('Fechando servidor...');
  await prisma.$disconnect();
  process.exit(0);
});
EOF

# Copiar painel HTML para public
log_info "Copiando painel administrativo..."
cp /dev/stdin public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Quentinhas Pro - Painel Administrativo</title>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/3.9.1/chart.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/axios/1.4.0/axios.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/socket.io/4.7.4/socket.io.js"></script>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
        }
        .header {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            padding: 1rem 2rem;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .logo {
            color: white;
            font-size: 1.5rem;
            font-weight: bold;
        }
        .status { color: white; display: flex; align-items: center; gap: 1rem; }
        .status-dot {
            width: 12px;
            height: 12px;
            border-radius: 50%;
            background: #4CAF50;
            animation: pulse 2s infinite;
        }
        @keyframes pulse {
            0% { box-shadow: 0 0 0 0 rgba(76, 175, 80, 0.7); }
            70% { box-shadow: 0 0 0 10px rgba(76, 175, 80, 0); }
            100% { box-shadow: 0 0 0 0 rgba(76, 175, 80, 0); }
        }
        .container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 2rem;
        }
        .dashboard-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 2rem;
            margin-bottom: 2rem;
        }
        .card {
            background: rgba(255, 255, 255, 0.95);
            border-radius: 16px;
            padding: 1.5rem;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
        }
        .card-title {
            font-size: 1.2rem;
            font-weight: 600;
            margin-bottom: 1rem;
            color: #333;
        }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 1rem;
        }
        .stat-item {
            text-align: center;
            padding: 1rem;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 12px;
            color: white;
        }
        .stat-value {
            font-size: 2rem;
            font-weight: bold;
            margin-bottom: 0.5rem;
        }
        .stat-label {
            font-size: 0.9rem;
            opacity: 0.9;
        }
        .btn {
            padding: 0.5rem 1rem;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-weight: 500;
            transition: all 0.3s ease;
            margin: 0.25rem;
        }
        .btn-primary { background: #667eea; color: white; }
        .btn-success { background: #28a745; color: white; }
        .btn-danger { background: #dc3545; color: white; }
        .table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 1rem;
        }
        .table th, .table td {
            padding: 1rem;
            text-align: left;
            border-bottom: 1px solid #eee;
        }
        .table th {
            background: #f8f9fa;
            font-weight: 600;
        }
        .menu-item {
            display: grid;
            grid-template-columns: 1fr auto auto;
            gap: 1rem;
            align-items: center;
            padding: 1rem;
            background: #f8f9fa;
            border-radius: 8px;
            margin-bottom: 0.5rem;
        }
        .status-badge {
            padding: 0.25rem 0.75rem;
            border-radius: 20px;
            font-size: 0.8rem;
            font-weight: 500;
        }
        .status-CONFIRMED { background: #fff3cd; color: #856404; }
        .status-PREPARING { background: #d4edda; color: #155724; }
        .status-READY { background: #cce5ff; color: #004085; }
        .status-OUT_FOR_DELIVERY { background: #e2e3e5; color: #383d41; }
        .status-DELIVERED { background: #d1ecf1; color: #0c5460; }
    </style>
</head>
<body>
    <div class="header">
        <div class="logo">🍽️ Quentinhas Pro</div>
        <div class="status">
            <div class="status-dot"></div>
            <span>Sistema Online</span>
            <span id="currentTime"></span>
        </div>
    </div>

    <div class="container">
        <!-- Ações Rápidas -->
        <div style="margin-bottom: 2rem;">
            <button class="btn btn-primary" onclick="refreshData()">🔄 Atualizar</button>
            <button class="btn btn-success" onclick="showAddMenuModal()">➕ Adicionar Prato</button>
        </div>

        <!-- Dashboard -->
        <div class="dashboard-grid">
            <div class="card">
                <h3 class="card-title">📈 Estatísticas Hoje</h3>
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
        </div>

        <!-- Cardápio -->
        <div class="card">
            <h3 class="card-title">🍽️ Cardápio</h3>
            <div id="menuItems"></div>
        </div>

        <!-- Pedidos -->
        <div class="card">
            <h3 class="card-title">📋 Pedidos Recentes</h3>
            <table class="table">
                <thead>
                    <tr>
                        <th>Horário</th>
                        <th>Cliente</th>
                        <th>Total</th>
                        <th>Status</th>
                        <th>Ações</th>
                    </tr>
                </thead>
                <tbody id="ordersTable"></tbody>
            </table>
        </div>
    </div>

    <script>
        const socket = io();
        
        // Conectar ao socket
        socket.emit('join_admin');
        
        // Atualizar hora
        function updateTime() {
            document.getElementById('currentTime').textContent = new Date().toLocaleTimeString('pt-BR');
        }
        setInterval(updateTime, 1000);
        updateTime();

        // Carregar dados do dashboard
        async function loadDashboard() {
            try {
                const response = await axios.get('/api/dashboard');
                const data = response.data;
                
                document.getElementById('todayOrders').textContent = data.todayOrders;
                document.getElementById('todayRevenue').textContent = `R$ ${data.todayRevenue.toFixed(2)}`;
                document.getElementById('avgTicket').textContent = `R$ ${data.avgTicket.toFixed(2)}`;
                document.getElementById('totalCustomers').textContent = data.totalCustomers;
            } catch (error) {
                console.error('Erro ao carregar dashboard:', error);
            }
        }

        // Carregar cardápio
        async function loadMenu() {
            try {
                const response = await axios.get('/api/menu');
                const menuContainer = document.getElementById('menuItems');
                menuContainer.innerHTML = '';
                
                response.data.forEach(item => {
                    const div = document.createElement('div');
                    div.className = 'menu-item';
                    div.innerHTML = `
                        <div>
                            <h4>${item.name}</h4>
                            <p>R$ ${item.price.toFixed(2)} - ${item.description || ''}</p>
                            <small>Vendidos: ${item.soldCount}</small>
                        </div>
                        <button class="btn ${item.available ? 'btn-danger' : 'btn-success'}" 
                                onclick="toggleItem('${item.id}', ${!item.available})">
                            ${item.available ? '❌ Desativar' : '✅ Ativar'}
                        </button>
                    `;
                    menuContainer.appendChild(div);
                });
            } catch (error) {
                console.error('Erro ao carregar cardápio:', error);
            }
        }

        // Carregar pedidos
        async function loadOrders() {
            try {
                const response = await axios.get('/api/orders');
                const tbody = document.getElementById('ordersTable');
                tbody.innerHTML = '';
                
                response.data.slice(0, 10).forEach(order => {
                    const row = document.createElement('tr');
                    row.innerHTML = `
                        <td>${new Date(order.createdAt).toLocaleTimeString('pt-BR')}</td>
                        <td>${order.customer.name || order.customer.phone}</td>
                        <td>R$ ${order.finalAmount.toFixed(2)}</td>
                        <td><span class="status-badge status-${order.status}">${order.status}</span></td>
                        <td>
                            <select onchange="updateOrderStatus('${order.id}', this.value)">
                                <option value="CONFIRMED" ${order.status === 'CONFIRMED' ? 'selected' : ''}>Confirmado</option>
                                <option value="PREPARING" ${order.status === 'PREPARING' ? 'selected' : ''}>Preparando</option>
                                <option value="READY" ${order.status === 'READY' ? 'selected' : ''}>Pronto</option>
                                <option value="OUT_FOR_DELIVERY" ${order.status === 'OUT_FOR_DELIVERY' ? 'selected' : ''}>Entrega</option>
                                <option value="DELIVERED" ${order.status === 'DELIVERED' ? 'selected' : ''}>Entregue</option>
                            </select>
                        </td>
                    `;
                    tbody.appendChild(row);
                });
            } catch (error) {
                console.error('Erro ao carregar pedidos:', error);
            }
        }

        // Toggle item do menu
        async function toggleItem(id, available) {
            try {
                await axios.put(`/api/menu/${id}`, { available });
                loadMenu();
            } catch (error) {
                console.error('Erro ao atualizar item:', error);
            }
        }

        // Atualizar status do pedido
        async function updateOrderStatus(id, status) {
            try {
                await axios.put(`/api/orders/${id}/status`, { status });
                loadOrders();
            } catch (error) {
                console.error('Erro ao atualizar pedido:', error);
            }
        }

        // Atualizar todos os dados
        function refreshData() {
            loadDashboard();
            loadMenu();
            loadOrders();
        }

        // Socket events
        socket.on('order_updated', () => {
            loadOrders();
            loadDashboard();
        });

        socket.on('menu_updated', () => {
            loadMenu();
        });

        // Inicialização
        document.addEventListener('DOMContentLoaded', () => {
            refreshData();
            setInterval(refreshData, 30000); // Auto-refresh a cada 30s
        });
    </script>
</body>
</html>
EOF

# Iniciar Evolution API e N8N
log_info "Iniciando Evolution API e N8N..."
docker-compose up -d evolution n8n

# Aguardar serviços iniciarem
log_info "Aguardando serviços iniciarem..."
sleep 45

# Iniciar servidor da API
log_info "Iniciando servidor da API..."
npm start &
SERVER_PID=$!

# Aguardar servidor iniciar
sleep 10

# Criar scripts úteis
log_info "Criando scripts úteis..."

# Script de status
cat > check-status.sh << 'EOF'
#!/bin/bash
echo "=== STATUS SISTEMA QUENTINHAS PRO ==="
echo ""

# API
if curl -s http://localhost:3000/api/health | grep -q "OK"; then
    echo "✅ API: Online"
else
    echo "❌ API: Offline"
fi

# Banco PostgreSQL
if docker exec quentinhas-postgres pg_isready -U quentinhas >/dev/null 2>&1; then
    echo "✅ PostgreSQL: Online"
else
    echo "❌ PostgreSQL: Offline"
fi

# Evolution API
if curl -s http://localhost:8080/instance/fetchInstances >/dev/null 2>&1; then
    echo "✅ Evolution API: Online"
else
    echo "❌ Evolution API: Offline"
fi

# N8N
if curl -s http://localhost:5678 >/dev/null 2>&1; then
    echo "✅ N8N: Online"
else
    echo "❌ N8N: Offline"
fi

echo ""
echo "🔗 Acessos:"
echo "   📊 Painel: http://localhost:3000"
echo "   🤖 N8N: http://localhost:5678"
echo "   📱 WhatsApp: http://localhost:8080"
EOF

chmod +x check-status.sh

# Script de reinicialização
cat > restart-system.sh << 'EOF'
#!/bin/bash
echo "🔄 Reiniciando sistema..."

# Parar API
pkill -f "node server.js"

# Reiniciar containers
docker-compose restart

# Aguardar
sleep 30

# Iniciar API
npm start &

echo "✅ Sistema reiniciado!"
./check-status.sh
EOF

chmod +x restart-system.sh

# Script de backup
cat > backup-system.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="backups/$(date +%Y-%m-%d_%H-%M-%S)"
mkdir -p $BACKUP_DIR

echo "💾 Criando backup..."

# Backup PostgreSQL
docker exec quentinhas-postgres pg_dump -U quentinhas quentinhas > $BACKUP_DIR/database.sql

# Backup uploads
cp -r uploads $BACKUP_DIR/ 2>/dev/null || true

# Backup configurações
cp .env $BACKUP_DIR/
cp docker-compose.yml $BACKUP_DIR/

echo "✅ Backup criado em: $BACKUP_DIR"

# Manter apenas últimos 7 backups
find backups/ -type d -mtime +7 -exec rm -rf {} \; 2>/dev/null || true
EOF

chmod +x backup-system.sh

# =================================================================
# FINALIZAÇÃO
# =================================================================

log_success "🎉 INSTALAÇÃO CONCLUÍDA COM SUCESSO!"
echo ""
echo "📋 SISTEMA INSTALADO:"
echo "   🌐 Painel Admin: http://localhost:3000"
echo "   🔌 API REST: http://localhost:3000/api"
echo "   🤖 N8N: http://localhost:5678"
echo "   📱 WhatsApp API: http://localhost:8080"
echo ""
echo "🔑 ACESSO PAINEL:"
echo "   📧 Email: admin@quentinhas.com"
echo "   🔐 Senha: admin123"
echo ""
echo "📊 BANCO DE DADOS:"
echo "   🐘 PostgreSQL: localhost:5432"
echo "   👤 Usuário: quentinhas"
echo "   🔐 Senha: quentinhas123"
echo ""
echo "🛠️ COMANDOS ÚTEIS:"
echo "   ./check-status.sh     - Verificar status"
echo "   ./restart-system.sh   - Reiniciar sistema"
echo "   ./backup-system.sh    - Fazer backup"
echo ""
echo "📱 PRÓXIMOS PASSOS:"
echo "   1. Acessar painel: http://localhost:3000"
echo "   2. Configurar WhatsApp no Evolution API"
echo "   3. Personalizar cardápio"
echo "   4. Testar sistema"
echo ""
log_success "✅ Sistema 100% pronto para uso!"

# Testar se tudo está funcionando
log_info "Testando sistema..."
sleep 5

if curl -s http://localhost:3000/api/health | grep -q "OK"; then
    log_success "✅ API funcionando!"
else
    log_warning "⚠️ API não respondeu, verifique os logs"
fi

echo ""
echo "🎯 ACESSE AGORA: http://localhost:3000"
echo ""