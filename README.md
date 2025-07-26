# pgdump-to-minio

**Containerized PostgreSQL backup tool that uses `pg_dump` (custom format) to back up specified databases and uploads them to a MinIO bucket.**

Ideal for Docker and Kubernetes environments, this image simplifies scheduled backups with minimal configuration via environment variables.

---

## 🔧 Features

- Dumps specific PostgreSQL databases using pg_dump -Fc</code> (custom format with compression).
- Uploads backups directly to a MinIO bucket using the MinIO client (<code>mc</code>).
- Clean, single-entrypoint design for easy automation (e.g. via cron, Kubernetes CronJobs).
- Simple configuration via environment variables.

---

## 🚀 Usage

### Docker Run Example

```bash
docker run --rm \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=yourpassword \
  -e POSTGRES_HOST=your-postgres-host \
  -e POSTGRES_PORT=5432 \
  -e DATABASES=db1,db2 \
  -e MINIO_ENDPOINT=http://minio:9000 \
  -e MINIO_ACCESS_KEY=minio-access-key \
  -e MINIO_SECRET_KEY=minio-secret-key \
  -e MINIO_BUCKET=pgbackups \
  pgdump-to-minio:17.5-RELEASE.2025-05-24T17-08-30Z
```

## 🔐 Optional Encryption

You can enable **GPG encryption** for your PostgreSQL backups by providing a GPG public key. This ensures that backups are encrypted before being uploaded to MinIO.

## 🛠 Environment Variables

| Variable            | Required | Description                                                           |
| ------------------- | -------- | --------------------------------------------------------------------- |
| `POSTGRES_USER`     | ✅       | PostgreSQL user with access to target DBs                             |
| `POSTGRES_PASSWORD` | ✅       | PostgreSQL password                                                   |
| `POSTGRES_HOST`     | ✅       | Hostname of the PostgreSQL server                                     |
| `POSTGRES_PORT`     | ❌       | PostgreSQL port (default: `5432`)                                     |
| `DATABASES`         | ✅       | Comma-separated list of databases to back up                          |
| `MINIO_ENDPOINT`    | ✅       | MinIO/S3-compatible endpoint (e.g., `minio:9000`)                     |
| `MINIO_ACCESS_KEY`  | ✅       | MinIO access key                                                      |
| `MINIO_SECRET_KEY`  | ✅       | MinIO secret key                                                      |
| `MINIO_BUCKET`      | ✅       | MinIO bucket name (auto-created if not present)                       |
| `GPG_PUBLIC_KEY`    | ❌       | Base64-encoded GPG public key for encrypting backups before uploading |

## 📦 Building the Image

```bash
docker build -t Dockerfile .
```

## 📁 Output Format

Each backup file is named as:<br>
`<database_name>_<timestamp>.dump`<br>
Example:<br>
`users_20250618-103015.dump`<br>
The `.dump` files use PostgreSQL's **custom format**, which is compressed and suitable for `pg_restore`.

## 🔄 Backup Retention (Optional)

This image does not handle retention policies by default. You can:

- Add a script or lifecycle rule on MinIO to automatically delete older backups.
- Use `mc` rm with a `--older-than` filter if desired.
- Use the provided `systemd` timer example (in the example/ folder) to schedule backups and implement retention or cleanup scripts as needed.

## ✅ TODO / Improvements

- Add automatic backup retention support

- Optionally encrypt dumps before uploading

- Add logging and health check support for production environments

## 📜 License

This project is released under the Unlicense, which dedicates the work to the public domain.

You can freely copy, modify, publish, use, compile, sell, or distribute this software for any purpose, commercial or non-commercial, without restriction.

For full details, see LICENSE or visit https://unlicense.org/.
