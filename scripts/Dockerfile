FROM ubuntu:22.04

# Avoid interactive prompts during install
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    awscli \
    bash \
    gzip \
    tar \
    && rm -rf /var/lib/apt/lists/*

# Add official MongoDB repo for tools
RUN curl -fsSL https://pgp.mongodb.com/server-6.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/mongodb.gpg] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list && \
    apt-get update && apt-get install -y mongodb-database-tools && \
    rm -rf /var/lib/apt/lists/*

# Working directory
WORKDIR /app/scripts

# Copy backup scripts
COPY backup.sh aws_backup.sh container_backup.sh ./

# Set permissions
RUN chmod +x /app/scripts/backup.sh /app/scripts/aws_backup.sh /app/scripts/container_backup.sh

# Default command for container execution
ENTRYPOINT []
CMD ["/app/scripts/container_backup.sh"]

# Environment variables (override in K8s)
ENV MONGODB_URI="mongodb://mongo:27017/fileupload"
ENV AWS_BUCKET="datafortress-backups-shrinidhi"
ENV AWS_REGION="ap-south-1"

# Use the container-friendly backup script
CMD ["/app/scripts/container_backup.sh"]
