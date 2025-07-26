FROM postgres:17.5

# Install MinIO Client (mc)
RUN apt-get update && apt-get install -y wget gnupg \
    && wget https://dl.min.io/client/mc/release/linux-amd64/mc \
    && mv mc /usr/local/bin/mc \
    && chmod +x /usr/local/bin/mc \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY backup.sh /usr/local/bin/backup.sh
RUN chmod +x /usr/local/bin/backup.sh

ENTRYPOINT ["/usr/local/bin/backup.sh"]
