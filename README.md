# Custom Postgres with Dynamic Multi-Database and pgvector Support

![Docker 21.1.x](https://img.shields.io/badge/Docker-21.1.x-2496ED?logo=docker&logoColor=white&style=for-the-badge)
![Docker Compose 2.37.x](https://img.shields.io/badge/Docker--Compose-2.37.x-2496ED?logo=docker&logoColor=white&style=for-the-badge)
![Postgres 17](https://img.shields.io/badge/Postgres-17-green?logo=postgresql&logoColor=white&style=for-the-badge)
![pgvector 0.7.1](https://img.shields.io/badge/pgvector-0.7.1-green?logo=postgresql&logoColor=white&style=for-the-badge)
![AMD64](https://img.shields.io/badge/Arch-amd64-blue?logo=linux&logoColor=white&style=for-the-badge)
![ARM64](https://img.shields.io/badge/Arch-arm64-blue?logo=linux&logoColor=white&style=for-the-badge)

This image extends the official Postgres image to support:
- Dynamic creation of multiple databases and users at initialization
- Automatic enabling of the `pgvector` extension for databases prefixed with `VECTOR_`
- Admin and user role setup via environment variables
- Use of `gettext`/`envsubst` for dynamic templating

## Table of Contents
- [Features](#features)
- [Project Structure](#project-structure)
- [Requirements](#requirements)
- [Build and Run with Docker](#build-and-run-with-docker)
- [Prebuilt Docker Image](#prebuilt-docker-image)
- [Example Usage](#example-usage)
- [Environment Variables](#environment-variables)
- [Sidecar Database Logic](#sidecar-database-logic)
- [How It Works](#how-it-works)
- [Overriding Defaults](#overriding-defaults)
- [Notes](#notes)
- [Contributing](#contributing)
- [License](#license)
- [References](#references)

## Features

- **Multi-database initialization**: Create any number of databases and users at container startup.
- **pgvector support**: If a database name starts with `VECTOR_`, the `pgvector` extension is enabled in that database.
- **Admin user**: Optionally create a superuser admin role.
- **Sidecar users**: Each sidecar database gets a user with the pattern `<db>_user` (all lowercase) and a default password.

## Project Structure

```
postgres-pgvector-multidatabase/
├── Dockerfile           # Docker build instructions for the custom Postgres image
├── init-multidb.sh      # Initialization script for dynamic multi-database and user setup
├── init.sql.template    # SQL template used for database/user creation and extension enabling
├── LICENSE.md           # Project license (MIT)
├── README.md            # Project documentation and usage instructions
```

## Requirements
- Docker
- Docker Compose (optional, for multi-container setups)

## Build and Run with Docker

### Build the Docker Image

```sh
docker build -t custom-postgres-multidb-pgvector .
```

### Run the Container

```sh
docker run -d \
  --name my-postgres \
  -e POSTGRES_USER=pguser \
  -e POSTGRES_PASSWORD=pguserstrongpassword \
  -e POSTGRES_DB=postgres \
  -e POSTGRES_DB_SIDECARS=db1,db2,VECTOR_db3 \
  -p 5432:5432 \
  custom-postgres-multidb-pgvector
```

You can adjust the environment variables as needed.

## Prebuilt Docker Image

A prebuilt image is available on Docker Hub:

[luismachadoreis/postgres-multidb-pgvector:pg17](https://hub.docker.com/repository/docker/luismachadoreis/postgres-multidb-pgvector/tags/pg17)

- Use the `pg17` tag for AMD64 (x86_64) systems:
  ```sh
  docker pull luismachadoreis/postgres-multidb-pgvector:pg17
  ```
- Use the `pg17-arm64` tag for ARM64 (Apple Silicon, Raspberry Pi, etc):
  ```sh
  docker pull luismachadoreis/postgres-multidb-pgvector:pg17-arm64
  ```

You can use the appropriate image in your `docker run` or `docker-compose.yml` as the base image for your platform.

## Example Usage

### docker-compose.yml
```yaml
version: '3.8'
services:
  postgres:
    build: .
    environment:
      POSTGRES_USER: pguser
      POSTGRES_PASSWORD: pguserstrongpassword
      POSTGRES_DB: postgres
      POSTGRES_DB_SIDECARS: db1,db2,VECTOR_db3
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
volumes:
  pgdata:
```

## Environment Variables
| Variable                  | Default                | Description                                                                 |
|---------------------------|------------------------|-----------------------------------------------------------------------------|
| `POSTGRES_USER`           | `pguser`               | Default user role (as in official image)                                    |
| `POSTGRES_PASSWORD`       | `pguserstrongpassword` | Password for the default user                                               |
| `POSTGRES_DB`             | `postgres`             | Default database (as in official image)                                     |
| `POSTGRES_DB_SIDECARS`    | `db1,db2,VECTOR_db3`   | Comma-separated list of extra databases to create                           |

## Sidecar Database Logic
- For each database in `POSTGRES_DB_SIDECARS`:
  - A database is created (if it doesn't exist)
  - A user is created: `<db>_user` (all lowercase), password: `mydefaultpassword`
  - The user is granted all privileges on their database
  - If the database name starts with `VECTOR_`, the `pgvector` extension is enabled in that database

## How It Works
- On first container startup, the script `init-multidb.sh` runs.
- It reads the environment variables and creates the specified databases and users.
- For any database with a name starting with `VECTOR_`, it enables the `pgvector` extension.
- All sidecar users get the password `mydefaultpassword` (change in script if needed).

## Overriding Defaults
You can override any environment variable at build or runtime. For example, to add more vector-enabled databases:

```yaml
      POSTGRES_DB_SIDECARS: db1,VECTOR_embeddings,VECTOR_analytics
```

## Notes
- The default user and database logic is compatible with the official Postgres image.
- The admin user is optional but recommended for superuser access.
- The `pgvector` extension is built from source at image build time.

## Contributing

### Clone the Repository

```sh
git clone git@github.com:luismr/postgres-17-multidb-pgvector.git
cd postgres-17-multidb-pgvector
```

### Submitting Pull Requests

1. Fork this repository on GitHub.
2. Create a new branch for your feature or fix:
   ```sh
   git checkout -b my-feature-branch
   ```
3. Make your changes and commit them with clear messages.
4. Push your branch to your fork:
   ```sh
   git push origin my-feature-branch
   ```
5. Open a Pull Request on GitHub from your branch to the `main` branch of this repository.
6. Provide a clear description of your changes in the PR.

## License
[MIT License](LICENSE.md)

## References

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [PostgreSQL 17 Documentation](https://www.postgresql.org/docs/17/)
- [pgvector Extension](https://github.com/pgvector/pgvector)
