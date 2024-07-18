#!/usr/bin/env bash
DOCKERHUB_USERNAME='gagama'
DOCKERHUB_PASSWORD='dckr_pat_Z7qu9tNnz13GwN7mEHlyx678LWs'
DOCKERHUB_REPO='gagama/owasp-dependency-check-ubuntu'
DC_SCRIPT="$PWD/dependency-check/bin/dependency-check.sh"
VALIDATE_INSTALL_CMD="$DC_SCRIPT --version"
ZIP_FILE="dependency-check.zip"
DB_DIR="$PWD/OWASP-Dependency-Check/data/local_db"

install_packages() {
        sudo apt-get update && sudo apt-get install -y \
                curl \
                unzip \
                tar \
                docker \
                docker.io \
                default-jre
}

install_owasp_dependency_check() {
        curl -Ls "https://github.com/jeremylong/DependencyCheck/releases/download/v${VERSION}/dependency-check-${VERSION}-release.zip" --output ${ZIP_FILE}
        unzip ${ZIP_FILE} &&
        bash ${VALIDATE_INSTALL_CMD}
}

update_owasp_dependency_check() {
        mkdir -p ${DB_DIR}
        ${DC_SCRIPT} --data ${DB_DIR} --updateonly --nvdApiKey ${NVD_API_KEY}
}

write_entrypoint() {
        # Criação do Dockerfile
        cat <<EOF > entrypoint.sh
#!/bin/sh
# Acessar variáveis de ambiente passadas pelo action.yml
PROJECT=\${PROJECT}
SCAN_DIRECTORY=\${SCAN_DIRECTORY}
# Caminho do script dependency-check.sh
DC_SCRIPT="/usr/share/dependency-check/bin/dependency-check.sh"
# Função para verificar a instalação do Dependency-Check
check_installation() {
        echo "Verificando a instalação do OWASP Dependency-Check..."
        \$DC_SCRIPT --version
        if [ \$? -ne 0 ]; then
                echo "Erro: OWASP Dependency-Check não está instalado corretamente."
                exit 1
        fi
        echo "OWASP Dependency-Check instalado com sucesso."
}
# Verificação de instalação
check_installation
# Realizar a varredura no código fonte
\$DC_SCRIPT --scan \${SCAN_DIRECTORY} --data \${DATA_DIRECTORY} -n --format JSON --out ./
EOF
                chmod +x entrypoint.sh odc-json-report-to-markdown.py
}

build_and_push_docker_image() {
        # Criação do Dockerfile
        cat <<EOF > Dockerfile
FROM ubuntu:latest
USER root
ENV DC_DIRECTORY=/dependency-check \
        DATA_DIRECTORY=/dependency-check/data \
        CACHE_DIRECTORY=/dependency-check/data/cache
RUN mkdir -p /dependency-check/data
# Copie o script de entrada para o contêiner e ajuste as permissões
COPY ./dependency-check/ /dependency-check
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY odc-json-report-to-markdown.py /usr/local/bin/odc-json-report-to-markdown.py
COPY ./OWASP-Dependency-Check/data/local_db/ /dependency-check/data
# Defina o ponto de entrada para o script de verificação
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
EOF

        # Construir a imagem Docker
        docker build -t ${DOCKERHUB_REPO}:latest .
        # Login no DockerHub
        echo ${DOCKERHUB_PASSWORD} | docker login -u ${DOCKERHUB_USERNAME} --password-stdin
        # Push da imagem Docker
        docker push ${DOCKERHUB_REPO}:latest
}

install_packages

VERSION=$(curl -s https://jeremylong.github.io/DependencyCheck/current.txt)
BYPASS_INSTALL_MSG="Dependency-check ${VERSION} installed, bypass install"
INSTALL_MSG="Installing dependency-check Version ${VERSION}"

v=$(bash ${VALIDATE_INSTALL_CMD} 2>&1) \
        && [[ ${v##* } == ${VERSION} ]] \
        && echo ${BYPASS_INSTALL_MSG} \
        || echo ${INSTALL_MSG} >&2 \
        && install_owasp_dependency_check \
        && update_owasp_dependency_check \
        && write_entrypoint \
        && build_and_push_docker_image
        
