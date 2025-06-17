#!/bin/bash
set -e

# Wait for postgres to be ready
function wait_for_postgres() {
  until pg_isready -U "$POSTGRES_USER"; do
    echo "Waiting for postgres..."
    sleep 1
  done
}

# Create sidecar DBs and users
IFS=',' read -ra DBS <<< "$POSTGRES_DB_SIDECARS"
for DB in "${DBS[@]}"; do
  DB_TRIMMED=$(echo "$DB" | xargs)
  if [ -z "$DB_TRIMMED" ]; then continue; fi
  DB_LOWER=$(echo "$DB_TRIMMED" | tr '[:upper:]' '[:lower:]')
  USER="${DB_LOWER}_user"
  PASS="mydefaultpassword"
  echo "Creating sidecar DB: $DB_TRIMMED and user: $USER"

  # Use the template file and envsubst
  export DB_TRIMMED USER PASS
  envsubst < /docker-entrypoint-initdb.d/init-multidb.sql.template > /tmp/init-multidb.sql
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -f /tmp/init-multidb.sql
  rm -f /tmp/init-multidb.sql

  # Enable pgvector if VECTOR_ prefix (case-insensitive)
  if [[ "$DB_TRIMMED" =~ ^[Vv][Ee][Cc][Tt][Oo][Rr]_ ]]; then
    echo "Enabling pgvector on $DB_TRIMMED"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname="$DB_TRIMMED" -c "CREATE EXTENSION IF NOT EXISTS vector;"
  fi
done 