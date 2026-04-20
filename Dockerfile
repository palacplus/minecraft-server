FROM eclipse-temurin:25-jre

# UID/GID 1000 are often already taken by a base-image user; use numeric ownership instead of useradd.
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

WORKDIR /opt/minecraft
COPY --chown=1000:1000 server/ /opt/minecraft/

RUN chmod +x /opt/minecraft/startserver.sh 2>/dev/null || true

USER 1000:1000
WORKDIR /data

ENV PACK_DIR=/opt/minecraft \
    DATA_DIR=/data

ENTRYPOINT ["/docker-entrypoint.sh"]
