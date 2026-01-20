# Exposure + TLS for PostgreSQL

## Recommended patterns

1) **VPC-only** access (private subnets, SG-to-SG rules)
2) **VPN** access (WireGuard/OpenVPN) into the VPC
3) **AWS SSM port forwarding** for operators

## If you must expose publicly

**You should strongly avoid this**, but if required:

- Restrict Security Group inbound to **known IPs only**
- Ensure Postgres auth is strong (`scram-sha-256`, strong passwords)
- Restrict `pg_hba.conf` to allowed CIDRs only
- Enable TLS (native Postgres TLS preferred) OR terminate TLS at Nginx stream
- Monitor logs and set alerts

## Let's Encrypt + Nginx stream caveat

Let's Encrypt / Certbot is designed primarily for HTTP(S). If you terminate TLS at Nginx stream:

- Certbot still needs an **HTTP server block** on port 80 (or DNS challenge) to issue/renew certs.
- Use `nginx/http/pg-acme.conf` as the HTTP vhost for ACME.
- Then use the resulting cert paths inside `nginx/stream/pg-stream-tls.conf`.

## Alternative (better): Postgres native TLS

Postgres can serve TLS natively (server cert + key), and you restrict inbound to trusted networks.

Nginx stream is optional and adds complexity.
