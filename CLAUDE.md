# CLAUDE.md

## Project Overview

Docker-based local development environment for a message-driven architecture with Change Data Capture (CDC) using the Transactional Outbox pattern. Provides a complete infrastructure stack: PostgreSQL, Kafka, Debezium, Liquibase, and WireMock.

Documentation and scripts are written in **Portuguese**.

## Repository Structure

```
├── build.sh                        # Interactive setup menu (Portuguese)
├── dev.sh                          # CLI wrapper for dev commands
├── create_connectors.sh            # Deploys Kafka Connect connectors
├── docker-compose.yaml             # All services (8 containers)
├── kafka-connect/
│   └── connectors/                 # Debezium connector JSON configs
│       └── postgres-connector_myschema-tb_tx_outbox.json
├── liquibase/
│   └── postgres/changelog/
│       ├── db.changelog.yaml       # Root changelog (includes all sub-changelogs)
│       ├── liquibase.properties    # DB connection config
│       ├── schemas/                # Schema creation migrations
│       │   └── changeset/1.0/ddl/schemas.sql
│       └── myschema/               # Application table migrations
│           └── changeset/1.0/ddl/tb_tx_outbox.sql
└── wiremock/                       # Mock server mappings (gitignored)
```

## Technology Stack

| Component        | Technology              | Port  |
|------------------|-------------------------|-------|
| Database         | PostgreSQL 12.5         | 5432  |
| Schema migration | Liquibase 4.23          | —     |
| Message broker   | Kafka (Confluent 7.4.3) | 9092  |
| CDC              | Debezium (latest)       | 8083  |
| Coordination     | Zookeeper 7.4.3         | —     |
| Monitoring       | Control Center 7.4.3    | 9021  |
| Mock server      | WireMock (latest)       | 8000  |

## Commands

### Initial Setup

```bash
./build.sh          # Interactive menu: create env, connectors, alias
```

### Day-to-Day (via `dev` alias or `./dev.sh`)

```bash
dev start           # Start all containers
dev stop            # Stop all containers
dev restart         # Restart all containers
dev drop            # Remove containers and volumes (destructive)
dev logs <service>  # Tail logs for a service (e.g., dev logs connect)
dev update          # Pull changes and run Liquibase migrations
dev connect-update  # Re-deploy Kafka connectors
dev build           # Re-run build.sh
dev compose <args>  # Passthrough to docker-compose
```

### Direct Docker Compose

```bash
docker-compose -f docker-compose.yaml up --build -d
docker-compose -f docker-compose.yaml stop
docker-compose -f docker-compose.yaml logs -f <service>
```

## Service Startup Order

```
postgresdb (health check: SELECT 1)
  ├── liquibase (runs migrations then exits)
  └── zookeeper
        └── broker (kafka)
              ├── connect (debezium, also depends on postgresdb)
              └── control-center
wiremock (independent)
```

## Database

- **Host**: `localhost:5432` (or `postgresdb:5432` from within Docker)
- **Credentials**: `postgres` / `postgres`
- **Database**: `postgres`
- **WAL level**: `logical` (required for CDC)

### Key Table: `myschema.tb_tx_outbox`

Implements the Transactional Outbox pattern for reliable event publishing.

| Column           | Type          | Purpose                    |
|------------------|---------------|----------------------------|
| id               | numeric(49)   | Primary key                |
| nm_topico_saida  | varchar(100)  | Target Kafka topic         |
| dc_body          | bytea         | Event payload              |
| tp_midia         | varchar(100)  | Media type                 |
| nm_topico_ok     | varchar(100)  | Success callback topic     |
| nm_topico_rnna   | varchar(100)  | Error/retry topic          |
| fl_cdc           | bool          | CDC processing flag        |
| dt_operacao      | timestamp     | Operation timestamp        |

## Naming Conventions

- **Tables**: `tb_` prefix, snake_case (e.g., `tb_tx_outbox`)
- **Columns**: type-hint prefix (`nm_` = name, `dc_` = data/content, `fl_` = flag, `tp_` = type, `dt_` = date)
- **Schemas**: lowercase (e.g., `myschema`)
- **Kafka connectors**: `{source}-connector_{schema}-{table}` format
- **Liquibase changeset IDs**: `{version}-{TABLE_NAME}`

## Adding a New Database Migration

1. Create a new version directory under the appropriate schema in `liquibase/postgres/changelog/<schema>/changeset/<version>/`
2. Add DDL SQL file(s) in a `ddl/` subdirectory
3. Create a `<version>-ddl.yaml` changeset referencing the SQL
4. Update the schema's `db.changelog.yaml` to include the new changeset
5. Run `dev update` to apply

## Adding a New Kafka Connector

1. Create a JSON config file in `kafka-connect/connectors/`
2. Follow the naming pattern: `postgres-connector_<schema>-<table>.json`
3. Run `dev connect-update` or `./create_connectors.sh`
4. The script POSTs each JSON to `http://localhost:8083/connectors`

## Key Architecture Decisions

- **Outbox pattern**: Application writes events to `tb_tx_outbox`; Debezium captures changes via CDC and routes them to Kafka topics using the `EventRouter` SMT
- **Logical replication**: PostgreSQL WAL configured with high limits (100 senders/slots) for CDC reliability
- **No authentication on local services**: All services use default/open credentials — this is a local dev environment only
- **Volume persistence**: `postgres-data` and `broker-data` volumes survive container restarts; use `dev drop` to reset

## Gotchas

- The `dev` alias must be created via `build.sh` option 3 (adds to `~/.bashrc`)
- `create_connectors.sh` polls Kafka Connect readiness before deploying — if Connect is slow to start, the script waits
- Connector creation returns 409 if already exists (not an error)
- WireMock directory is gitignored; mappings must be created locally
- Some docker-compose values reference `${USER}` from the host environment
