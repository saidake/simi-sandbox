#!/bin/bash

COMPOSE_DIR="/tmp/simi-aws"
COMPOSE_FILE="$COMPOSE_DIR/docker-compose.yml"

echo "[INFO] Stopping LocalStack services using docker-compose..."

if [[ ! -f "$COMPOSE_FILE" ]]; then
  echo "[ERROR] docker-compose.yml not found at $COMPOSE_FILE"
  exit 1
fi

cd "$COMPOSE_DIR" || {
  echo "[ERROR] Failed to change directory to $COMPOSE_DIR"
  exit 1
}

docker-compose stop localstack
if [[ $? -eq 0 ]]; then
  echo "[INFO] LocalStack stopped successfully."
else
  echo "[WARN] Failed to stop LocalStack, you may want to check manually."
fi
