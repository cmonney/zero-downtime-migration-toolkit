# infra/docker — TODO

## What this folder will contain

Supplementary Docker assets that are too large or too specific to include in `docker-compose.yml`
directly. This will include:

- `Dockerfile.sqlserver-init`: a base image layer that adds the `sqlcmd` healthcheck script and
  the init script runner, used by all three database service definitions.
- `healthcheck.sh`: a shell script that uses `sqlcmd` to verify a SQL Server instance is ready
  to accept connections, used as the Docker healthcheck for each database service.
- `wait-for-db.sh`: a utility script for the strangler API container to wait for all three
  database healthchecks to pass before starting the ASP.NET Core process.

## Acceptance criteria

- `docker compose up --wait` completes without error and the strangler API's `/health` endpoint
  returns 200 within 60 seconds on a machine with a local Docker daemon.
- The healthcheck scripts handle SQL Server's typical 30–45 second cold-start time without
  false-failing.

## Build order

Build alongside the Docker Compose wiring, after the init scripts in `tools/seed/` are written.
This is infrastructure plumbing; implement it as part of the same sprint as the seed scripts.
