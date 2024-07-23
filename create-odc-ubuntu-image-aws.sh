#!/usr/bin/env bash

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

build_and_push_docker_image_aws() {
        aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/e8b3z6m5
        docker build -t appsec/odc-action-ubuntu .
        docker tag appsec/odc-action-ubuntu:latest public.ecr.aws/e8b3z6m5/appsec/odc-action-ubuntu:latest
        # Push da imagem Docker
        docker push public.ecr.aws/e8b3z6m5/appsec/odc-action-ubuntu:latest
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
        && build_and_push_docker_image_aws
