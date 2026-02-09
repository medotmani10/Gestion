#!/usr/bin/env bash
set -euo pipefail

DB_URL="${DATABASE_URL:-postgresql://gestion:gestion@localhost:5432/gestion}"

echo "[1/4] Starting postgres via docker compose..."
docker compose up -d postgres

echo "[2/4] Waiting for db health..."
until docker compose exec -T postgres pg_isready -U gestion -d gestion >/dev/null 2>&1; do
  sleep 1
done

echo "[3/4] Applying migrations..."
psql "$DB_URL" -v ON_ERROR_STOP=1 -f database/migrations/001_init_phase1.sql
psql "$DB_URL" -v ON_ERROR_STOP=1 -f database/migrations/002_phase1_views_and_triggers.sql

echo "[4/4] Seeding roles..."
psql "$DB_URL" -v ON_ERROR_STOP=1 -f database/seeds/001_roles_seed.sql

echo "Done."
