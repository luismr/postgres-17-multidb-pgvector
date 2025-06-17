#!/bin/bash
set -e

# Wait for postgres to be ready
function wait_for_postgres() {
  until pg_isready -U "$POSTGRES_USER"; do
    echo "Waiting for postgres..."
    sleep 1
  done
}

# Only run on first init
if [ "$1" = "postgres" ]; then
  # Create sidecar DBs and users
  IFS=',' read -ra DBS <<< "$POSTGRES_DB_SIDECARS"
  for DB in "${DBS[@]}"; do
    DB_TRIMMED=$(echo "$DB" | xargs)
    if [ -z "$DB_TRIMMED" ]; then continue; fi
    DB_LOWER=$(echo "$DB_TRIMMED" | tr '[:upper:]' '[:lower:]')
    USER="${DB_LOWER}_user"
    PASS="mydefaultpassword"
    echo "Creating sidecar DB: $DB_TRIMMED and user: $USER"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
      DO
      $$
      BEGIN
        IF NOT EXISTS (SELECT FROM pg_database WHERE datname = '$DB_TRIMMED') THEN
          CREATE DATABASE "$DB_TRIMMED";
        END IF;
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$USER') THEN
          CREATE ROLE "$USER" WITH LOGIN PASSWORD '$PASS';
        END IF;
        GRANT ALL PRIVILEGES ON DATABASE "$DB_TRIMMED" TO "$USER";
      END
      $$;
EOSQL
    # Enable pgvector if VECTOR_ prefix
    if [[ "$DB_TRIMMED" =~ ^VECTOR_ ]]; then
      echo "Enabling pgvector on $DB_TRIMMED"
      psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname="$DB_TRIMMED" -c "CREATE EXTENSION IF NOT EXISTS vector;"
    fi
  done
fi 