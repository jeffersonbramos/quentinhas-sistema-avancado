#!/bin/bash

# =================================================================
# CORREÇÃO DEFINITIVA EVOLUTION API WHATSAPP
# =================================================================

echo "🔧 DIAGNÓSTICO E CORREÇÃO EVOLUTION API"
echo "======================================="

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

PUBLIC_IP="91.99.155.79"
cd /root/quentinhas-pro

# =================================================================
# 1. DIAGNÓSTICO DETALHADO
# =================================================================

log_info "1. Verificando logs do Evolution atual..."
echo ""
docker logs quentinhas-evolution --tail 30
echo ""

log_info "2. Verificando status dos serviços de apoio..."

# Verificar MongoDB
if docker exec quentinhas-mongo mongosh --eval "db.adminCommand('ping')" >/dev/null 2>&1; then
    log_success "✅ MongoDB: Funcionando"
    docker exec quentinhas-mongo mongosh --eval "db.adminCommand('listDatabases')" 2>/dev/null | head -10
else
    log_error "❌ MongoDB: Com problemas"
    docker logs quentinhas-mongo --tail 10
fi

echo ""

# Verificar Redis
if docker exec quentinhas-redis redis-cli ping >/dev/null 2>&1; then
    log_success "✅ Redis: Funcionando"
    docker exec quentinhas-redis redis-cli info server | head -5
else
    log_error "❌ Redis: Com problemas"
    docker logs quentinhas-redis --tail 10
fi

echo ""

# =================================================================
# 2. REMOVER EVOLUTION PROBLEMÁTICO
# =================================================================

log_info "3. Removendo Evolution problemático..."
docker stop quentinhas-evolution 2>/dev/null || true
docker rm quentinhas-evolution 2>/dev/null || true

# =================================================================
# 3. VERIFICAR CONECTIVIDADE REDE
# =================================================================

log_info "4. Verificando conectividade de rede..."

# Verificar se a rede existe
if docker network ls | grep quentinhas-pro_quentinhas-network >/dev/null; then
    log_success "✅ Rede Docker existe"
else
    log_warning "⚠️ Criando rede Docker..."
    docker network create quentinhas-pro_quentinhas-network
fi

# Testar conectividade entre containers
log_info "Testando conectividade MongoDB..."
docker run --rm --network quentinhas-pro_quentinhas-network alpine:latest \
    sh -c "nc -zv quentinhas-mongo 27017" 2>&1 | head -2

log_info "Testando conectividade Redis..."
docker run --rm --network quentinhas-pro_quentinhas-network alpine:latest \
    sh -c "nc -zv quentinhas-redis 6379" 2>&1 | head -2

# =================================================================
# 4. CRIAR EVOLUTION COM CONFIGURAÇÃO ROBUSTA
# =================================================================

log_info "5. Criando Evolution API com configuração robusta..."

# Aguardar serviços estarem estáveis
sleep 10

# Criar Evolution com configuração mínima e robusta
docker run -d \
  --name quentinhas-evolution \
  --network quentinhas-pro_quentinhas-network \
  -p 8080:8080 \
  -e SERVER_TYPE=http \
  -e SERVER_PORT=8080 \
  -e SERVER_URL=http://localhost:8080 \
  -e DEL_INSTANCE=false \
  -e DATABASE_ENABLED=true \
  -e DATABASE_CONNECTION_URI="mongodb://root:evolution123@quentinhas-mongo:27017/evolution?authSource=admin&retryWrites=true&w=majority" \
  -e DATABASE_CONNECTION_CLIENT_NAME="EvolutionAPI" \
  -e REDIS_ENABLED=true \
  -e REDIS_URI="redis://quentinhas-redis:6379/0" \
  -e REDIS_PREFIX_KEY="evolution_api" \
  -e WEBHOOK_GLOBAL_URL="http://host.docker.internal:3000/api/webhook/whatsapp" \
  -e WEBHOOK_GLOBAL_ENABLED=true \
  -e WEBHOOK_GLOBAL_WEBHOOK_BY_EVENTS=true \
  -e CONFIG_SESSION_PHONE_CLIENT="QuentinhasApp" \
  -e CONFIG_SESSION_PHONE_NAME="Quentinhas System" \
  -e CORS_ORIGIN="*" \
  -e CORS_METHODS="POST,GET,PUT,DELETE,PATCH,OPTIONS" \
  -e CORS_CREDENTIALS=true \
  -e LOG_LEVEL=info \
  -e LOG_COLOR=true \
  -e AUTHENTICATION_TYPE=apikey \
  -e AUTHENTICATION_API_KEY="QUENTINHAS_KEY_2024_SECURE" \
  -e AUTHENTICATION_EXPOSE_IN_FETCH_INSTANCES=true \
  -e QRCODE_LIMIT=30 \
  -e INSTANCE_EXPIRE_TIME=false \
  -e CLEAN_STORE_CLEANING_INTERVAL=7200 \
  -e CLEAN_STORE_MESSAGES=true \
  -e CLEAN_STORE_MESSAGE_UP_TO=false \
  -e CLEAN_STORE_CONTACTS=true \
  -e CLEAN_STORE_CHATS=true \
  --add-host host.docker.internal:host-gateway \
  --restart unless-stopped \
  --memory="512m" \
  --cpus="0.5" \
  atendai/evolution-api:latest

log_info "Aguardando Evolution API inicializar... (2 minutos)"

# Aguardar com feedback
for i in {1..24}; do
    echo -n "."
    sleep 5
done
echo ""

# =================================================================
# 5. TESTE PROGRESSIVO
# =================================================================

log_info "6. Testando Evolution API progressivamente..."

# Teste 1: Container está rodando?
if docker ps | grep quentinhas-evolution | grep -q "Up"; then
    log_success "✅ Container está rodando"
else
    log_error "❌ Container não está rodando"
    docker logs quentinhas-evolution --tail 20
    exit 1
fi

# Teste 2: Porta está aberta?
sleep 10
if docker exec quentinhas-evolution netstat -tulpn | grep :8080; then
    log_success "✅ Porta 8080 está aberta no container"
else
    log_warning "⚠️ Porta 8080 não está aberta ainda"
fi

# Teste 3: Serviço responde internamente?
sleep 20
if docker exec quentinhas-evolution wget -q --spider http://localhost:8080 2>/dev/null; then
    log_success "✅ Serviço responde internamente"
else
    log_warning "⚠️ Serviço ainda não responde internamente"
fi

# Teste 4: Serviço responde externamente?
sleep 10
for i in {1..10}; do
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200\|404\|401"; then
        log_success "✅ Evolution API está respondendo!"
        break
    else
        log_warning "Tentativa $i/10 - Aguardando resposta..."
        sleep 10
    fi
done

# =================================================================
# 6. VERIFICAÇÃO FINAL E INFORMAÇÕES
# =================================================================

echo ""
log_info "7. Verificação final dos serviços..."

# Status final
echo ""
echo "📊 STATUS FINAL:"
echo "==============="

if curl -s http://localhost:3000/api/health >/dev/null 2>&1; then
    log_success "✅ Dashboard: http://$PUBLIC_IP:3000"
else
    log_error "❌ Dashboard: Problema"
fi

if curl -s http://localhost:5678 >/dev/null 2>&1; then
    log_success "✅ N8N: http://$PUBLIC_IP:5678"
else
    log_error "❌ N8N: Problema"
fi

if curl -s http://localhost:8080 >/dev/null 2>&1; then
    log_success "✅ WhatsApp API: http://$PUBLIC_IP:8080"
    
    echo ""
    echo "🎉 EVOLUTION API FUNCIONANDO!"
    echo "============================"
    echo ""
    echo "📱 WhatsApp API:"
    echo "    🔗 URL: http://$PUBLIC_IP:8080"
    echo "    🔑 API Key: QUENTINHAS_KEY_2024_SECURE"
    echo "    📱 Manager: http://$PUBLIC_IP:8080/manager"
    echo "    📋 Instances: http://$PUBLIC_IP:8080/instance/fetchInstances"
    echo ""
    echo "🚀 PRÓXIMOS PASSOS:"
    echo "    1. Acesse: http://$PUBLIC_IP:8080"
    echo "    2. Crie uma nova instância do WhatsApp"
    echo "    3. Conecte seu WhatsApp Business"
    echo "    4. Configure webhooks"
    echo ""
    
else
    log_error "❌ WhatsApp API: Ainda com problemas"
    
    echo ""
    echo "🔍 DIAGNÓSTICO DETALHADO:"
    echo "========================"
    
    # Mostrar logs detalhados
    echo ""
    echo "📋 Logs recentes do Evolution:"
    docker logs quentinhas-evolution --tail 25
    
    echo ""
    echo "🔧 Comandos para debug:"
    echo "    docker logs quentinhas-evolution -f"
    echo "    docker exec quentinhas-evolution ps aux"
    echo "    docker restart quentinhas-evolution"
    
fi

# Status dos containers
echo ""
echo "📦 STATUS DOS CONTAINERS:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
log_info "Diagnóstico concluído!"

# Teste final da API
echo ""
log_info "Teste final da Evolution API:"
curl -v http://localhost:8080 2>&1 | head -10
