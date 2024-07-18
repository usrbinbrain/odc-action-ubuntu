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
