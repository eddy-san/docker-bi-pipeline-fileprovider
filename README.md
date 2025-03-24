# docker-bi-pipeline-fileprovider

This repository provides a **secure and modular Docker-based setup** for building a complete data stack including ETL, DWH, OLAP, and Machine Learning. It uses **Traefik's file provider** instead of the Docker provider to comply with **OWASP Security Rule #1**: **"Do not expose the Docker daemon socket."**

---

## ⚙️ Stack Components

| Component      | Description                                                        |
| -------------- | ------------------------------------------------------------------ |
| **Traefik**    | Reverse proxy with TLS, rate limiting, basic auth, and access logs |
| **PostgreSQL** | Primary relational database and data warehouse                     |
| **ClickHouse** | High-performance OLAP database                                     |
| **Airflow**    | Workflow orchestration for ETL pipelines                           |
| **Metabase**   | BI tool for dashboards and OLAP exploration                        |
| **pgAdmin**    | PostgreSQL web-based administration tool                           |
| **Jupyter**    | Notebook environment for machine learning                          |
| **MediaWiki**  | Optional internal documentation wiki                               |

---

## 🔐 Security Highlights

- ❌ No Docker socket exposed (OWASP Rule #1 compliant)
- ✅ Traefik uses **file-based configuration** instead of Docker provider
- ⚡ TLS via Let's Encrypt
- 🚶 Rate limiting to protect services
- 🔒 Basic authentication middleware for sensitive endpoints
- ⚖ Server hardening headers (STS, XSS, no Server banner, etc.)
- 🛡️ Custom `iptables` firewall and `conntrack` tuning script

---

## 🌐 Reverse Proxy: Traefik (file provider)

Configuration is stored in `traefik/dynamic/traefik_dynamic.yml` and includes:

- Routers for all services (`airflow.your-domain.com`, `jupyter.your-domain.com`, ...)
- TLS certificates via Let's Encrypt (ACME)
- Basic Auth and middleware chains
- Header protection and traffic control

---

## 📁 Project Structure

```bash
.
├── docker-compose.yml
├── .env                         # Credentials and secrets
├── traefik/
│   ├── dynamic/
│   │   ├── traefik_dynamic.yml
│   │   └── traefik_auth_users
│   └── letsencrypt/
├── airflow/dags/
├── jupyter/
├── metabase-data/
├── logs/
└── fix-iptables-conntrack.sh    # Security script
```

---

## 🛡️ `fix-iptables-conntrack.sh`

This script:

- Sets custom `iptables` rules to restrict inbound traffic
- Allows DNS, HTTP(S), SSH, and Docker internal communication
- Clears and optimizes the `conntrack` table
- Increases `nf_conntrack_max` for high-concurrency environments
- Saves rules via `iptables-persistent`

Run it once before launching the stack:

```bash
sudo ./fix-iptables-conntrack.sh
```

---

## 🚀 Quick Start

```bash
# (Optional) Run firewall & conntrack optimization
sudo ./fix-iptables-conntrack.sh
```

### ✅ Before you launch:

1. Make sure your **subdomains** (e.g. `jupyter.your-domain.com`, `airflow.your-domain.com`) point to your **server’s public IP** in your DNS settings.  
2. Rename the file `.env.example` to `.env` and **enter secure, production-ready passwords**.  
3. Rename the file `traefik/dynamic/traefik_auth_users.example` to `traefik/dynamic/traefik_auth_users` and **enter secure, bcrypt-hashed, production-ready password**  
4. Then launch the full stack:

```bash
docker-compose up -d
```

---

## ⚠️ Notes

- Ports 80/443 are handled by Traefik only.
- Services are routed based on subdomains using static file-based rules.
- The file `traefik_auth_users.example` contains a default hash for `admin:admin123`. **Do not use in production!** Replace it with a secure bcrypt hash.
- This setup is intended as a secure base for extensible BI and ML environments.

---

Feel free to fork or adapt this setup to fit your own data pipeline and security requirements.
