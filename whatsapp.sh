#!/bin/bash

# =================================================================
# RESOLVER GIT CONFLICT + CRIAR EVOLUTION API
# =================================================================

echo "🔧 RESOLVENDO GIT CONFLICT + EVOLUTION API"
echo "==========================================="

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

PUBLIC_IP=$(curl -s ifconfig.me)

# =================================================================
# 1. RESOLVER CONFLITO DO GIT
# =================================================================

log_info "1. Resolvendo conflito do Git..."

cd /root/quentinhas-sistema-avancado

# Fazer stash das mudanças locais
git stash

# Puxar atualizações
git pull origin main

# Ver arquivos atualizados
log_success "Arquivos no repositório:"
ls -la

echo ""

# =================================================================
# 2. CRIAR EVOLUTION API MANUALMENTE
# =================================================================

log_info "2. Criando Evolution API manualmente..."

cd /root/quentinhas-pro

# Parar Evolution se existir
docker stop quentinhas-evolution 2>/dev/null || true
docker rm quentinhas-evolution 2>/dev/null || true

log_info "Criando container Evolution API..."

# Criar Evolution API com configuração simplificada
docker run -d \
  --name quentinhas-evolution \
  --network quentinhas-pro_quentinhas-network \
  -p 8080:8080 \
  -e SERVER_TYPE=http \
  -e SERVER_PORT=8080 \
  -e DEL_INSTANCE=false \
  -e DATABASE_ENABLED=true \
  -e DATABASE_CONNECTION_URI="mongodb://root:evolution123@quentinhas-mongo:27017/evolution?authSource=admin" \
  -e REDIS_ENABLED=true \
  -e REDIS_URI="redis://quentinhas-redis:6379" \
  -e WEBHOOK_GLOBAL_URL="http://host.docker.internal:3000/api/webhook/whatsapp" \
  -e WEBHOOK_GLOBAL_ENABLED=true \
  -e CONFIG_SESSION_PHONE_CLIENT="QuentinhasSystem" \
  -e CONFIG_SESSION_PHONE_NAME="Sistema Quentinhas" \
  -e CORS_ORIGIN="*" \
  -e CORS_METHODS="POST,GET,PUT,DELETE" \
  -e CORS_CREDENTIALS=true \
  -e LOG_LEVEL=info \
  -e AUTHENTICATION_TYPE=apikey \
  -e AUTHENTICATION_API_KEY="quentinhas_api_key_2024" \
  --add-host host.docker.internal:host-gateway \
  --restart unless-stopped \
  atendai/evolution-api:latest

log_info "Aguardando Evolution API inicializar... (90 segundos)"
sleep 90

# =================================================================
# 3. VERIFICAR STATUS DE TODOS OS SERVIÇOS
# =================================================================

log_info "3. Verificando status de todos os serviços..."

echo ""
echo "📊 STATUS DOS SERVIÇOS:"
echo ""

# PostgreSQL
if docker exec quentinhas-postgres pg_isready -U quentinhas >/dev/null 2>&1; then
    log_success "✅ PostgreSQL: Funcionando"
else
    log_warning "⚠️ PostgreSQL: Verificar"
fi

# Redis
if docker exec quentinhas-redis redis-cli ping >/dev/null 2>&1; then
    log_success "✅ Redis: Funcionando"
else
    log_warning "⚠️ Redis: Verificar"
fi

# MongoDB
if docker exec quentinhas-mongo mongosh --eval "db.adminCommand('ping')" >/dev/null 2>&1; then
    log_success "✅ MongoDB: Funcionando"
else
    log_warning "⚠️ MongoDB: Verificar"
fi

# Evolution API
sleep 30
if curl -s http://localhost:8080 >/dev/null 2>&1; then
    log_success "✅ Evolution API: Funcionando!"
else
    log_warning "⚠️ Evolution API: Ainda inicializando..."
    
    log_info "Testando Evolution API com curl detalhado..."
    curl -v http://localhost:8080 2>&1 | head -10
    
    log_info "Logs recentes do Evolution API:"
    docker logs quentinhas-evolution --tail 15
fi

# API Principal
if curl -s http://localhost:3000/api/health >/dev/null 2>&1; then
    log_success "✅ API Principal: Funcionando"
else
    log_warning "⚠️ API Principal: Verificar"
fi

# N8N
if curl -s http://localhost:5678 >/dev/null 2>&1; then
    log_success "✅ N8N: Funcionando"
else
    log_warning "⚠️ N8N: Verificar"
fi

# =================================================================
# 4. INFORMAÇÕES DE ACESSO
# =================================================================

echo ""
echo "🌐 INFORMAÇÕES DE ACESSO:"
echo "========================="
echo ""
echo "📊 Painel Principal:"
echo "    🔗 http://$PUBLIC_IP:3000"
echo "    📧 Email: admin@quentinhas.com"
echo "    🔐 Senha: admin123"
echo ""
echo "📱 WhatsApp API (Evolution):"
echo "    🔗 http://$PUBLIC_IP:8080"
echo "    🔑 API Key: quentinhas_api_key_2024"
echo "    📱 Manager: http://$PUBLIC_IP:8080/manager"
echo ""
echo "🤖 N8N Automação:"
echo "    🔗 http://$PUBLIC_IP:5678"
echo ""
echo "🔍 APIs de Teste:"
echo "    📊 Health Check: http://$PUBLIC_IP:3000/api/health"
echo "    📱 Evolution Health: http://$PUBLIC_IP:8080"
echo ""

# =================================================================
# 5. COMANDOS ÚTEIS
# =================================================================

echo "🛠️ COMANDOS ÚTEIS:"
echo "=================="
echo ""
echo "# Ver logs do Evolution API:"
echo "docker logs quentinhas-evolution -f"
echo ""
echo "# Reiniciar Evolution API:"
echo "docker restart quentinhas-evolution"
echo ""
echo "# Ver status de todos containers:"
echo "docker ps"
echo ""
echo "# Testar Evolution API:"
echo "curl http://localhost:8080"
echo ""

# Status final dos containers
echo "📦 STATUS DOS CONTAINERS:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
log_success "🎉 Configuração concluída!"
echo ""
echo "🚀 Próximos passos:"
echo "1. ✅ Acesse: http://$PUBLIC_IP:8080"
echo "2. ✅ Configure seu WhatsApp Business"
echo "3. ✅ Teste os webhooks"
echo "4. ✅ Gerencie pelo painel: http://$PUBLIC_IP:3000"
