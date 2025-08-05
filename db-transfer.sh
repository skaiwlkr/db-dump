#!/bin/bash

# Activate strict error handling
set -euo pipefail

# Logging helper
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Usage info
show_usage() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --dump [SOURCE|TARGET]   Create dump only from specified database"
  echo "  --restore                Perform full transfer (default)"
  echo "  --help                   Show help"
  echo ""
  echo "Examples:"
  echo "  $0 --restore"
  echo "  $0 --dump SOURCE"
  echo "  $0 --dump TARGET"
}

# Initialize mode variables
DUMP_MODE=""
DUMP_SOURCE=""
RESTORE_MODE=""

# Parse input arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dump)
      if [[ $# -lt 2 ]]; then
        log "❌ Error: --dump requires argument (SOURCE or TARGET)"
        show_usage
        exit 1
      fi
      DUMP_MODE="true"
      DUMP_SOURCE="$2"
      if [[ "$DUMP_SOURCE" != "SOURCE" && "$DUMP_SOURCE" != "TARGET" ]]; then
        log "❌ Error: --dump argument must be SOURCE or TARGET"
        show_usage
        exit 1
      fi
      shift 2
      ;;
    --restore)
      RESTORE_MODE="true"
      shift
      ;;
    --help)
      show_usage
      exit 0
      ;;
    *)
      log "❌ Error: Unknown option $1"
      show_usage
      exit 1
      ;;
  esac
done

# Require at least one mode
if [[ "$DUMP_MODE" != "true" && "$RESTORE_MODE" != "true" ]]; then
  log "❌ Error: Specify either --dump or --restore"
  show_usage
  exit 1
fi

# Load environment file
ENV_FILE=".env.transfer"
if [[ ! -f "$ENV_FILE" ]]; then
  log "❌ Error: $ENV_FILE not found!"
  exit 1
fi

log "📦 Loading environment variables from $ENV_FILE..."
set -a
source "$ENV_FILE"
set +a

# Validate required variables
if [[ -z "${SOURCE_DB_URL:-}" || -z "${TARGET_DB_URL:-}" ]]; then
  log "❌ Error: SOURCE_DB_URL or TARGET_DB_URL is not set."
  exit 1
fi

log "✅ SOURCE_DB_URL: $SOURCE_DB_URL"
log "✅ TARGET_DB_URL: $TARGET_DB_URL"

# Generate filename
DUMP_FILE="db_transfer_$(date +'%Y%m%d_%H%M%S').sql"
log "📄 Dump file will be: $DUMP_FILE"

# Dump logic
if [[ "$DUMP_MODE" == "true" ]]; then
  if [[ "$DUMP_SOURCE" == "SOURCE" ]]; then
    log "📤 Dumping from SOURCE database..."
    pg_dump "$SOURCE_DB_URL" --no-owner --no-acl > "$DUMP_FILE"
    log "💾 Dump saved: $DUMP_FILE"
    exit 0
  elif [[ "$DUMP_SOURCE" == "TARGET" ]]; then
    log "📤 Dumping from TARGET database..."
    pg_dump "$TARGET_DB_URL" --no-owner --no-acl > "$DUMP_FILE"
    log "💾 Dump saved: $DUMP_FILE"
    exit 0
  fi
fi

# Restore logic
if [[ "$RESTORE_MODE" == "true" ]]; then
  log "📤 Creating dump from SOURCE..."
  pg_dump "$SOURCE_DB_URL" --no-owner --no-acl > "$DUMP_FILE"
  log "💾 Dump saved: $DUMP_FILE"

  # Confirm before dropping schema
  log "⚠️  Ready to reset TARGET schema..."
  dbuser=$(echo "$TARGET_DB_URL" | sed -E 's|.*://([^:/@]+):.*@\S+|\1|')
  dbhost=$(echo "$TARGET_DB_URL" | sed -E 's|.*://[^@]*@([^:/]*).*|\1|')
  read -p "Confirm reset for $dbuser@$dbhost? (Y/N): " confirm && [[ $confirm =~ ^[Yy](es)?$ ]] || {
    log "❌ Reset cancelled. Cleaning up..."
    rm -f "$DUMP_FILE"
    exit 1
  }

  log "🧨 Dropping and recreating public schema in TARGET..."
  psql "$TARGET_DB_URL" -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
  log "✅ Schema reset complete."

  log "📥 Restoring into TARGET..."
  psql "$TARGET_DB_URL" < "$DUMP_FILE"
  log "✅ Restore finished."

  log "🧹 Removing dump file..."
  rm -f "$DUMP_FILE"
  log "✅ Done."

  exit 0
fi
