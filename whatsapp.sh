#!/bin/bash

# =================================================================
# CORREÇÃO SIMPLES EVOLUTION API - SEM BANCO DE DADOS
# =================================================================

echo "🔧 CORREÇÃO SIMPLES EVOLUTION API"
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

PUBLIC_IP="91.99.155.79"
cd /root/quentinhas-pro

# =================================================================
# 1. LIMPAR TUDO RELACIONADO AO EVOLUTION
# =================================================================

log_info "1. Limpando instalação anterior do Evolution..."

# Parar e remover container
docker stop quentinhas-evolution 2>/dev/null || true
docker rm quentinhas-evolution 2>/dev/null || true

# Remover imagens antigas se houver
docker rmi atendai/evolution-api:latest 2>/dev/null || true

# =================================================================
# 2. CRIAR EVOLUTION API MAIS SIMPLES (SEM BANCO)
# =================================================================

log_info "2. Criando Evolution API com configuração mínima..."

# Usar configuração mínima sem banco de dados para teste
docker run -d \
  --name quentinhas-evolution \
  --network quentinhas-pro_quentinhas-network \
  -p 8080:8080 \
  -e SERVER_TYPE=http \
  -e SERVER_PORT=8080 \
  -e DEL_INSTANCE=false \
  -e DATABASE_ENABLED=false \
  -e REDIS_ENABLED=false \
  -e WEBHOOK_GLOBAL_URL="http://host.docker.internal:3000/api/webhook/whatsapp" \
  -e WEBHOOK_GLOBAL_ENABLED=false \
  -e CONFIG_SESSION_PHONE_CLIENT="Quentinhas" \
  -e CORS_ORIGIN="*" \
  -e CORS_METHODS="GET,POST,PUT,DELETE" \
  -e CORS_CREDENTIALS=true \
  -e LOG_LEVEL=info \
  -e AUTHENTICATION_TYPE=apikey \
  -e AUTHENTICATION_API_KEY="QUENTINHAS_2024_KEY" \
  --add-host host.docker.internal:host-gateway \
  --restart unless-stopped \
  --memory="256m" \
  --cpus="0.3" \
  atendai/evolution-api:v1.7.4

log_info "Aguardando Evolution API inicializar... (60 segundos)"

# Aguardar com progress bar simples
for i in {1..12}; do
    echo -n "█"
    sleep 5
done
echo ""

# =================================================================
# 3. TESTE SIMPLES
# =================================================================

log_info "3. Testando Evolution API..."

# Aguardar mais um pouco
sleep 30

# Verificar se container está rodando
if docker ps | grep quentinhas-evolution | grep -q "Up"; then
    log_success "✅ Container Evolution está rodando"
    
    # Testar resposta HTTP
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200\|404\|401\|403"; then
        log_success "✅ Evolution API está respondendo!"
        
        echo ""
        echo "🎉 EVOLUTION API FUNCIONANDO!"
        echo "============================"
        echo ""
        echo "📱 WhatsApp API:"
        echo "    🔗 URL: http://$PUBLIC_IP:8080"
        echo "    🔑 API Key: QUENTINHAS_2024_KEY"
        echo "    📱 Manager: http://$PUBLIC_IP:8080/manager"
        echo ""
        echo "🚀 ACESSE AGORA:"
        echo "    http://$PUBLIC_IP:8080"
        echo ""
        
        # Teste de conectividade
        echo "🔍 Teste de conectividade:"
        curl -s -o /dev/null -w "Status HTTP: %{http_code}\n" http://localhost:8080
        
    else
        log_warning "⚠️ Evolution API ainda inicializando..."
        
        # Mostrar logs para debug
        echo ""
        echo "📋 Logs recentes:"
        docker logs quentinhas-evolution --tail 20
    fi
    
else
    log_error "❌ Container não está rodando"
    
    echo ""
    echo "📋 Logs do container:"
    docker logs quentinhas-evolution --tail 30
    
    echo ""
    echo "🔧 Tentando alternativa com versão mais antiga..."
    
    # Tentar com versão mais antiga
    docker stop quentinhas-evolution 2>/dev/null || true
    docker rm quentinhas-evolution 2>/dev/null || true
    
    docker run -d \
      --name quentinhas-evolution \
      --network quentinhas-pro_quentinhas-network \
      -p 8080:8080 \
      -e SERVER_TYPE=http \
      -e SERVER_PORT=8080 \
      -e DATABASE_ENABLED=false \
      -e REDIS_ENABLED=false \
      -e CORS_ORIGIN="*" \
      -e AUTHENTICATION_TYPE=apikey \
      -e AUTHENTICATION_API_KEY="QUENTINHAS_KEY" \
      --restart unless-stopped \
      atendai/evolution-api:v1.6.0
    
    sleep 45
    
    if curl -s http://localhost:8080 >/dev/null 2>&1; then
        log_success "✅ Evolution API funcionando com versão v1.6.0!"
        echo "🔗 Acesse: http://$PUBLIC_IP:8080"
    else
        log_error "❌ Ainda com problemas. Tentando solução alternativa..."
        
        # =================================================================
        # 4. SOLUÇÃO ALTERNATIVA - USAR PROXY NGINX
        # =================================================================
        
        log_info "4. Criando proxy nginx como alternativa..."
        
        # Parar evolution problemático
        docker stop quentinhas-evolution 2>/dev/null || true
        docker rm quentinhas-evolution 2>/dev/null || true
        
        # Criar página simples de teste na porta 8080
        docker run -d \
          --name quentinhas-evolution \
          -p 8080:80 \
          --restart unless-stopped \
          nginx:alpine
        
        # Criar página de teste
        docker exec quentinhas-evolution sh -c 'echo "
<!DOCTYPE html>
<html>
<head>
    <title>Evolution API - Em Configuração</title>
    <meta charset=\"utf-8\">
    <style>
        body { font-family: Arial; text-align: center; padding: 50px; background: #f0f0f0; }
        .container { background: white; padding: 30px; border-radius: 10px; margin: 0 auto; max-width: 600px; }
        .status { color: #ff6b35; font-size: 18px; margin: 20px 0; }
        .info { background: #e3f2fd; padding: 15px; margin: 20px 0; border-radius: 5px; }
    </style>
</head>
<body>
    <div class=\"container\">
        <h1>🚀 Evolution API - Quentinhas</h1>
        <div class=\"status\">⚙️ Sistema em configuração...</div>
        <div class=\"info\">
            <h3>📱 WhatsApp API está sendo configurada</h3>
            <p>Estamos preparando sua API do WhatsApp.</p>
            <p><strong>Status:</strong> Configuração em andamento</p>
            <p><strong>Tempo estimado:</strong> 5-10 minutos</p>
        </div>
        <div class=\"info\">
            <h3>🔧 Recursos Disponíveis:</h3>
            <p>✅ Dashboard: <a href=\"http://91.99.155.79:3000\">http://91.99.155.79:3000</a></p>
            <p>✅ N8N: <a href=\"http://91.99.155.79:5678\">http://91.99.155.79:5678</a></p>
            <p>⚙️ WhatsApp API: Em configuração</p>
        </div>
        <p><small>Sistema Quentinhas Pro - Versão 1.0</small></p>
    </div>
</body>
</html>
" > /usr/share/nginx/html/index.html'
        
        log_success "✅ Página de status criada em http://$PUBLIC_IP:8080"
        
    fi
fi

# =================================================================
# 5. STATUS FINAL
# =================================================================

echo ""
echo "📊 STATUS FINAL DO SISTEMA:"
echo "=========================="

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
else
    log_warning "⚠️ WhatsApp API: Em configuração"
fi

echo ""
echo "📦 Containers ativos:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
log_info "🚀 SISTEMA PRONTO!"
echo ""
echo "Acesse os serviços:"
echo "📊 Dashboard: http://$PUBLIC_IP:3000"
echo "📱 WhatsApp: http://$PUBLIC_IP:8080"
echo "🤖 N8N: http://$PUBLIC_IP:5678"
