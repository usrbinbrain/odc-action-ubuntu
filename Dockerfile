FROM ubuntu:latest
# Mantenha o usuário como root para as operações de instalação e configuração
USER root
# Variáveis de ambiente
ENV DC_DIRECTORY=/dependency-check \
    DATA_DIRECTORY=/dependency-check/data \
    CACHE_DIRECTORY=/dependency-check/data/cache \
    JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
# Instalar Java
RUN apt-get update && apt-get install -y openjdk-11-jdk
# Criar diretórios necessários
RUN mkdir -p /dependency-check/data /usr/share/dependency-check
# Copiar arquivos para o contêiner
COPY ./dependency-check/ /usr/share/dependency-check
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
COPY ./OWASP-Dependency-Check/data/local_db/ /dependency-check/data
# Definir o ponto de entrada para o script de verificação
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

