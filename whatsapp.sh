#!/bin/bash

# =================================================================
# CORREÇÃO FINAL EVOLUTION API - PROBLEMA DEPENDÊNCIAS
# =================================================================

set -e

echo "🔧 CORREÇÃO FINAL - EVOLUTION API"
echo "================================="

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

PROJECT_DIR="/root/quentinhas-pro"
cd $PROJECT_DIR

PUBLIC_IP=$(curl -s ifconfig.me)

log_info "Parando todos os serviços..."
docker-compose down
pm2 stop quentinhas-api || true

log_info "Removendo containers problemáticos..."
docker rm quentinhas-evolution || true

log_info "Criando docker-compose.yml CORRIGIDO para Evolution..."
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
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    restart: unless-stopped
    networks:
      - quentinhas-network

  redis:
    image: redis:7-alpine
    container_name: quentinhas-redis
    command: redis-server --appendonly yes
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    restart: unless-stopped
    networks:
      - quentinhas-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 3

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
    healthcheck:
      test: echo 'db.runCommand("ping").ok' | mongosh localhost:27017/test --quiet
      interval: 10s
      timeout: 5s
      retries: 3

  evolution:
    image: atendai/evolution-api:latest
    container_name: quentinhas-evolution
    environment:
      - SERVER_TYPE=http
      - SERVER_PORT=8080
      - SERVER_URL=http://localhost:8080
      - DEL_INSTANCE=false
      - DATABASE_ENABLED=true
      - DATABASE_CONNECTION_URI=mongodb://root:evolution123@quentinhas-mongo:27017/evolution?authSource=admin&retryWrites=true&w=majority
      - DATABASE_CONNECTION_CLIENT_NAME=EvolutionAPI
      - REDIS_ENABLED=true
      - REDIS_URI=redis://quentinhas-redis:6379/0
      - REDIS_PREFIX_KEY=evolution_api
      - WEBHOOK_GLOBAL_URL=http://host.docker.internal:3000/api/webhook/whatsapp
      - WEBHOOK_GLOBAL_ENABLED=true
      - WEBHOOK_GLOBAL_WEBHOOK_BY_EVENTS=true
      - CONFIG_SESSION_PHONE_CLIENT=QuentinhasSystem
      - CONFIG_SESSION_PHONE_NAME=Sistema Quentinhas
      - CORS_ORIGIN=*
      - CORS_METHODS=POST,GET,PUT,DELETE,PATCH
      - CORS_CREDENTIALS=true
      - LOG_LEVEL=info
      - LOG_COLOR=true
      - AUTHENTICATION_TYPE=apikey
      - AUTHENTICATION_API_KEY=quentinhas_evolution_key_2024
      - AUTHENTICATION_EXPOSE_IN_FETCH_INSTANCES=true
      - QRCODE_LIMIT=10
      - INSTANCE_EXPIRE_TIME=false
    ports:
      - "8080:8080"
    depends_on:
      mongo:
        condition: service_healthy
      redis:
        condition: service_healthy
    extra_hosts:
      - "host.docker.internal:host-gateway"
    restart: unless-stopped
    networks:
      - quentinhas-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

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

log_info "Configurando memória do sistema..."
# Configurar overcommit memory para evitar problemas
echo 1 > /proc/sys/vm/overcommit_memory

log_info "Iniciando serviços na ordem correta..."

# Iniciar PostgreSQL primeiro
log_info "Iniciando PostgreSQL..."
docker-compose up -d postgres
sleep 20

# Iniciar Redis
log_info "Iniciando Redis..."
docker-compose up -d redis
sleep 15

# Verificar se Redis está funcionando
log_info "Verificando Redis..."
until docker exec quentinhas-redis redis-cli ping >/dev/null 2>&1; do
    log_warning "Aguardando Redis..."
    sleep 5
done
log_success "Redis está funcionando!"

# Iniciar MongoDB
log_info "Iniciando MongoDB..."
docker-compose up -d mongo
sleep 30

# Verificar se MongoDB está funcionando
log_info "Verificando MongoDB..."
until docker exec quentinhas-mongo mongosh --eval "db.adminCommand('ping')" >/dev/null 2>&1; do
    log_warning "Aguardando MongoDB..."
    sleep 10
done
log_success "MongoDB está funcionando!"

# Agora iniciar Evolution API
log_info "Iniciando Evolution API..."
docker-compose up -d evolution

log_info "Aguardando Evolution API inicializar... (2-3 minutos)"
sleep 90

# Verificar Evolution API múltiplas vezes
log_info "Testando Evolution API..."
for i in {1..15}; do
    if curl -s http://localhost:8080 >/dev/null 2>&1; then
        log_success "✅ Evolution API está funcionando!"
        break
    else
        log_warning "Tentativa $i/15 - Aguardando Evolution API..."
        sleep 10
    fi
done

# Iniciar N8N
log_info "Iniciando N8N..."
docker-compose up -d n8n
sleep 30

# Iniciar API principal
log_info "Iniciando API principal..."
pm2 start server.js --name quentinhas-api

sleep 10

echo ""
log_info "STATUS FINAL DOS SERVIÇOS:"
echo ""

# Verificar todos os serviços
if docker exec quentinhas-postgres pg_isready -U quentinhas >/dev/null 2>&1; then
    log_success "✅ PostgreSQL: Funcionando"
else
    log_error "❌ PostgreSQL: Problema"
fi

if docker exec quentinhas-redis redis-cli ping >/dev/null 2>&1; then
    log_success "✅ Redis: Funcionando"
else
    log_error "❌ Redis: Problema"
fi

if docker exec quentinhas-mongo mongosh --eval "db.adminCommand('ping')" >/dev/null 2>&1; then
    log_success "✅ MongoDB: Funcionando"
else
    log_error "❌ MongoDB: Problema"
fi

if curl -s http://localhost:8080 >/dev/null 2>&1; then
    log_success "✅ Evolution API: Funcionando"
else
    log_error "❌ Evolution API: Ainda com problema"
fi

if curl -s http://localhost:3000/api/health >/dev/null 2>&1; then
    log_success "✅ API Principal: Funcionando"
else
    log_error "❌ API Principal: Problema"
fi

if curl -s http://localhost:5678 >/dev/null 2>&1; then
    log_success "✅ N8N: Funcionando"
else
    log_error "❌ N8N: Problema"
fi

echo ""
echo "🌐 ACESSOS DO SISTEMA:"
echo "    📊 Painel Principal: http://$PUBLIC_IP:3000"
echo "    📱 WhatsApp API: http://$PUBLIC_IP:8080"
echo "    🤖 N8N Automação: http://$PUBLIC_IP:5678"
echo ""
echo "🔑 EVOLUTION API:"
echo "    🌐 URL: http://$PUBLIC_IP:8080"
echo "    🔐 API Key: quentinhas_evolution_key_2024"
echo "    📱 Manager: http://$PUBLIC_IP:8080/manager"
echo ""

# Se Evolution ainda não estiver funcionando, mostrar logs
if ! curl -s http://localhost:8080 >/dev/null 2>&1; then
    echo ""
    log_error "Evolution API ainda com problemas. Logs recentes:"
    docker logs quentinhas-evolution --tail 20
    echo ""
    echo "🔄 Para tentar novamente:"
    echo "    docker-compose restart evolution"
    echo "    docker logs quentinhas-evolution -f"
fi

echo ""
log_success "🔧 Correção concluída!"

# Mostrar status dos containers
echo ""
log_info "Status dos containers:"
docker-compose ps
