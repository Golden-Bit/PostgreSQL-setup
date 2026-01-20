# PostgreSQL on Ubuntu/EC2 – Docker Compose + systemd (optional Nginx/TLS)

This repository provides an **opinionated, DevOps-ready** setup to run **PostgreSQL** on an Ubuntu server (e.g., EC2) using **Docker Compose**, with:

- Pinned images (no `:latest`)
- Persistent volumes
- Healthchecks
- Backup/restore scripts
- Optional **systemd** unit to start on boot
- Optional **Nginx stream (TCP)** configuration + **Let's Encrypt** certificates *(advanced / risky if exposed publicly)*

> **Security note (important):**
> PostgreSQL is a **database protocol (TCP/5432), not HTTP**.
> The recommended pattern is **NOT** to expose it publicly.
> Prefer **VPC-only**, **VPN**, or **AWS SSM port-forwarding**.
>
> If you must expose it, do it with **strict IP allowlisting**, TLS, and strong authentication.

---

## 0) Prerequisites

- Ubuntu 22.04/24.04
- Docker + Docker Compose plugin installed
- A security group / firewall policy that matches your exposure model

If Docker is not installed, see `docs/docker-install.md`.

---

## 1) Quick start (local-only binding, recommended)

1. Copy env template and set secrets:

```bash
cd /opt
sudo mkdir -p postgres && sudo chown -R $USER:$USER postgres
cd postgres
cp -n .env.example .env
nano .env
```

2. Start:

```bash
docker compose pull
docker compose up -d
docker compose ps
```

3. Verify health:

```bash
./scripts/healthcheck.sh
```

4. Connect from the server:

```bash
psql "host=127.0.0.1 port=${PG_PORT} dbname=${POSTGRES_DB} user=${POSTGRES_USER} password=${POSTGRES_PASSWORD}" -c "select now();"
```

---

## 2) Directory layout

- `docker-compose.yml` – Postgres service + healthcheck + persistent volumes
- `.env.example` – environment template (copy to `.env`)
- `init/` – init SQL executed once on first boot (optional)
- `scripts/` – operational scripts (up/down/logs/backup/restore/update)
- `systemd/` – `postgres-compose.service` for auto-start
- `nginx/` – optional Nginx configs:
  - `nginx/http/` – HTTP vhost for ACME challenge (Certbot)
  - `nginx/stream/` – TCP proxy for Postgres with optional TLS
- `docs/` – docs (security, exposure options, TLS)

---

## 3) systemd auto-start (optional)

1. Install unit:

```bash
sudo cp systemd/postgres-compose.service /etc/systemd/system/postgres-compose.service
sudo systemctl daemon-reload
sudo systemctl enable --now postgres-compose
sudo systemctl status postgres-compose --no-pager
```

---

## 4) Backups

Create backup:

```bash
./scripts/backup.sh
ls -lh backups/
```

Restore (DANGER: overwrites data):

```bash
./scripts/restore.sh backups/pg_YYYY-MM-DD_HHMMSS.sql.gz
```

---

## 5) Exposure models (choose one)

### A) Recommended: **No public exposure**
- Bind Postgres to localhost (default in compose: `127.0.0.1:${PG_PORT}:5432`)
- Access via:
  - AWS SSM port-forwarding
  - VPN
  - Private subnets / peering

### B) VPC-only
- Bind Postgres to the instance private IP (or 0.0.0.0) **but** restrict inbound to **known security groups/subnets**.

### C) Public exposure (not recommended)
- Must include:
  - Allowlist IPs at Security Group level
  - PostgreSQL `pg_hba.conf` restricted
  - TLS
  - Strong passwords / rotation
  - Monitoring and audit

See: `docs/exposure-and-tls.md`.

---

## 6) Optional: Nginx stream (TCP) + Let's Encrypt (advanced)

Nginx can proxy **TCP** using `stream {}`. Certbot can issue certificates via an **HTTP** vhost.

High-level steps:
1) Point DNS `pg.example.com` -> server public IP
2) Install Nginx + Certbot
3) Enable HTTP vhost for ACME challenge (`nginx/http/pg-acme.conf`)
4) Obtain certificate:

```bash
sudo certbot --nginx -d pg.example.com
```

5) Enable stream proxy with TLS using the issued cert (`nginx/stream/pg-stream-tls.conf`)

See: `docs/exposure-and-tls.md`.

---

## 7) Update

```bash
./scripts/update.sh
```

---

## 8) Troubleshooting

- Logs:

```bash
./scripts/logs.sh
```

- Check ports:

```bash
sudo ss -lntp | egrep ':5432|:80|:443'
```

- Validate Postgres readiness:

```bash
./scripts/healthcheck.sh
```

---

## License
MIT (see `LICENSE`).
