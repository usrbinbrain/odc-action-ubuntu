#!/usr/bin/env bash

DOCKERHUB_USERNAME="gagama"
DOCKERHUB_PASSWORD="dckr_pat_Z7qu9tNnz13GwN7mEHlyx678LWs"
DOCKERHUB_REPO="gagama/owasp-dependency-check-ubuntu"
NVD_API_KEY="996fb0ac-b8ff-44f1-9193-11bf30ef5a50"
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

build_and_push_docker_image() {
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
        && build_and_push_docker_image \
	&& rm -rf ./dependency-check*
