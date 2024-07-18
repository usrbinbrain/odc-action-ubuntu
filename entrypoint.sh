#!/bin/sh
# Acessar variáveis de ambiente passadas pelo action.yml
PROJECT=${PROJECT}
SCAN_DIRECTORY=${SCAN_DIRECTORY}
# Caminho do script dependency-check.sh
DC_SCRIPT="/usr/share/dependency-check/bin/dependency-check.sh"
# Função para verificar a instalação do Dependency-Check
check_installation() {
        echo "Verificando a instalação do OWASP Dependency-Check..."
        $DC_SCRIPT --version
        if [ $? -ne 0 ]; then
                echo "Erro: OWASP Dependency-Check não está instalado corretamente."
                exit 1
        fi
        echo "OWASP Dependency-Check instalado com sucesso."
}
# Verificação de instalação
check_installation
# Realizar a varredura no código fonte
#$DC_SCRIPT --scan ${SCAN_DIRECTORY} --data ${DATA_DIRECTORY} -n --format JSON --out ./
