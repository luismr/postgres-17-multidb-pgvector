FROM postgres:17

ARG POSTGRES_ADMIN=pgadmin
ARG POSTGRES_ADMIN_PASSWORD=mystrongpassword
ARG POSTGRES_USER=pguser
ARG POSTGRES_PASSWORD=pguserstrongpassword
ARG POSTGRES_DB=postgres
ARG POSTGRES_DB_SIDECARS

ENV POSTGRES_ADMIN=${POSTGRES_ADMIN:-pgadmin} 
ENV POSTGRES_ADMIN_PASSWORD=${POSTGRES_ADMIN_PASSWORD:-mystrongpassword} 
ENV POSTGRES_USER=${POSTGRES_USER:-pguser} 
ENV POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-pguserstrongpassword} 
ENV POSTGRES_DB=${POSTGRES_DB:-postgres} 
ENV POSTGRES_DB_SIDECARS=${POSTGRES_DB_SIDECARS}

RUN apt-get update && \
    apt-get install -y build-essential postgresql-server-dev-17 git gettext && \
    git clone --branch v0.7.1 https://github.com/pgvector/pgvector.git && \
    cd pgvector && \
    make && \
    make install

COPY init-multidb.sh /docker-entrypoint-initdb.d/init-multidb.sh
RUN chmod +x /docker-entrypoint-initdb.d/init-multidb.sh

