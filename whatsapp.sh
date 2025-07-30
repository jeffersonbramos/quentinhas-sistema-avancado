#!/bin/bash

# =================================================================
# CORREÇÃO WHATSAPP EVOLUTION API
# Script para diagnosticar e corrigir problemas do Evolution API
# =================================================================

set -e

echo "🔧 DIAGNÓSTICO E CORREÇÃO - EVOLUTION API"
echo "========================================"

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

# Verificar se é root
if [[ $EUID -ne 0 ]]; then
    log_error "Execute como root: sudo su -"
    exit 1
fi

PROJECT_DIR="/root/quentinhas-pro"
cd $PROJECT_DIR

PUBLIC_IP=$(curl -s ifconfig.me)

log_info "Verificando status dos containers..."

echo "Status do Docker Compose:"
docker-compose ps

echo ""
log_info "Verificando logs do Evolution API..."
docker logs quentinhas-evolution --tail 20

echo ""
log_info "Verificando logs do MongoDB..."
docker logs quentinhas-mongo --tail 10

echo ""
log_info "Verificando logs do Redis..."
docker logs quentinhas-redis --tail 10

echo ""
log_info "Parando e recriando Evolution API..."

# Parar apenas o Evolution API
docker-compose stop evolution

# Remover container do Evolution API
docker rm quentinhas-evolution || true

log_info "Aguardando MongoDB e Redis estarem prontos..."
sleep 10

# Verificar se MongoDB está funcionando
if ! docker exec quentinhas-mongo mongosh --eval "db.adminCommand('ping')" >/dev/null 2>&1; then
    log_warning "MongoDB não está respondendo, reiniciando..."
    docker-compose restart mongo
    sleep 20
fi

# Verificar se Redis está funcionando
if ! docker exec quentinhas-redis redis-cli ping >/dev/null 2>&1; then
    log_warning "Redis não está respondendo, reiniciando..."
    docker-compose restart redis
    sleep 10
fi

log_info "Criando nova configuração do Evolution API..."

# Criar configuração otimizada do Evolution API
cat > docker-compose-evolution.yml << EOF
version: '3.8'

services:
  evolution:
    image: atendai/evolution-api:latest
    container_name: quentinhas-evolution-new
    environment:
      - SERVER_TYPE=http
      - SERVER_PORT=8080
      - DEL_INSTANCE=false
      - DATABASE_ENABLED=true
      - DATABASE_CONNECTION_URI=mongodb://root:evolution123@quentinhas-mongo:27017/evolution?authSource=admin
      - REDIS_ENABLED=true
      - REDIS_URI=redis://quentinhas-redis:6379
      - WEBHOOK_GLOBAL_URL=http://host.docker.internal:3000/api/webhook/whatsapp
      - WEBHOOK_GLOBAL_ENABLED=true
      - WEBHOOK_GLOBAL_WEBHOOK_BY_EVENTS=true
      - CONFIG_SESSION_PHONE_CLIENT=Quentinhas System
      - CONFIG_SESSION_PHONE_NAME=Sistema Quentinhas
      - CORS_ORIGIN=*
      - CORS_METHODS=POST,GET,PUT,DELETE
      - CORS_CREDENTIALS=true
      - LOG_LEVEL=DEBUG
      - LOG_COLOR=true
      - AUTHENTICATION_TYPE=apikey
      - AUTHENTICATION_API_KEY=evolution_api_key_quentinhas_2024
    ports:
      - "8080:8080"
    extra_hosts:
      - "host.docker.internal:host-gateway"
    restart: unless-stopped
    networks:
      - quentinhas-pro_quentinhas-network
    depends_on:
      - mongo
      - redis

networks:
  quentinhas-pro_quentinhas-network:
    external: true

volumes:
  quentinhas-pro_mongo_data:
    external: true
  quentinhas-pro_redis_data:
    external: true
EOF

log_info "Iniciando Evolution API com nova configuração..."
docker-compose -f docker-compose-evolution.yml up -d

log_info "Aguardando Evolution API inicializar... (pode levar até 2 minutos)"
sleep 60

# Testar Evolution API
log_info "Testando Evolution API..."
for i in {1..12}; do
    if curl -s http://localhost:8080 >/dev/null 2>&1; then
        log_success "Evolution API está respondendo!"
        break
    else
        log_warning "Tentativa $i/12 - Evolution API ainda não está pronto..."
        sleep 10
    fi
done

echo ""
log_info "Status final dos serviços:"

# Verificar PostgreSQL
if docker exec quentinhas-postgres pg_isready -U quentinhas >/dev/null 2>&1; then
    log_success "✅ PostgreSQL: Funcionando"
else
    log_error "❌ PostgreSQL: Com problemas"
fi

# Verificar MongoDB
if docker exec quentinhas-mongo mongosh --eval "db.adminCommand('ping')" >/dev/null 2>&1; then
    log_success "✅ MongoDB: Funcionando"
else
    log_error "❌ MongoDB: Com problemas"
fi

# Verificar Redis
if docker exec quentinhas-redis redis-cli ping >/dev/null 2>&1; then
    log_success "✅ Redis: Funcionando"
else
    log_error "❌ Redis: Com problemas"
fi

# Verificar Evolution API
if curl -s http://localhost:8080 >/dev/null 2>&1; then
    log_success "✅ Evolution API: Funcionando"
    echo ""
    echo "🌐 ACESSOS:"
    echo "    📱 WhatsApp API: http://$PUBLIC_IP:8080"
    echo "    📊 Manager: http://$PUBLIC_IP:8080/manager" 
    echo "    🔍 Health Check: http://$PUBLIC_IP:8080"
    echo ""
    echo "🔑 API Key: evolution_api_key_quentinhas_2024"
    echo ""
    echo "📱 PRÓXIMOS PASSOS:"
    echo "    1. Acesse: http://$PUBLIC_IP:8080"
    echo "    2. Crie uma instância do WhatsApp"
    echo "    3. Conecte seu WhatsApp Business"
    echo "    4. Configure os webhooks"
else
    log_error "❌ Evolution API: Ainda com problemas"
    echo ""
    echo "🔍 VERIFICAR LOGS:"
    echo "    docker logs quentinhas-evolution-new"
    echo ""
    echo "🔄 TENTAR RESTART:"
    echo "    docker-compose -f docker-compose-evolution.yml restart"
fi

echo ""
log_info "Verificando logs recentes do Evolution API..."
docker logs quentinhas-evolution-new --tail 15

echo ""
log_success "🔧 Diagnóstico e correção concluído!"
echo ""
echo "Se ainda houver problemas:"
echo "1. Verifique os logs: docker logs quentinhas-evolution-new"
echo "2. Reinicie: docker-compose -f docker-compose-evolution.yml restart"
echo "3. Execute este script novamente"
