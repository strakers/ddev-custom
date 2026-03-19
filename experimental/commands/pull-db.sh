#!/bin/bash

## Description: Pull DB from Pantheon with sync/backup options and token validation.
## Usage: pull-db [environment] [--fresh] [--sync]

# Default values
PANTHEON_ENV="live"
FRESH_BACKUP=false
USE_SYNC=false

# 1. Parse Arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --fresh) FRESH_BACKUP=true ;;
        --sync)  USE_SYNC=true ;;
        *)       PANTHEON_ENV="$1" ;;
    esac
    shift
done

# 2. Get project name from local config
PROJECT_NAME=$(grep '^name: ' .ddev/config.yaml | sed 's/name: //')

# 3. Check for TERMINUS_MACHINE_TOKEN if --sync is requested
if [ "$USE_SYNC" = true ]; then
    GLOBAL_CONFIG="$HOME/.ddev/global_config.yaml"
    # Check if the token exists in the global config file
    if ! grep -q "TERMINUS_MACHINE_TOKEN" "$GLOBAL_CONFIG" 2>/dev/null; then
        echo "⚠️  WARNING: TERMINUS_MACHINE_TOKEN not found in $GLOBAL_CONFIG."
        read -p "Would you like to proceed with a manual backup download instead? (y/N): " CONFIRM
        if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
            echo "🔄 Switching to manual import..."
            USE_SYNC=false
        else
            echo "❌ Exiting. Please set your token in ddev global_config.yaml to use --sync."
            exit 1
        fi
    fi
fi

# 4. Handle Pantheon Sync
if [ "$USE_SYNC" = true ]; then
    echo "🔄 Running ddev pantheon-sync ($PANTHEON_ENV)..."
    if ddev pantheon-sync --env="$PANTHEON_ENV"; then
        echo "✅ Sync complete!"
        exit 0
    else
        echo "❌ ERROR: pantheon-sync failed."
        exit 1
    fi
fi

# 5. Manual Backup Logic (The Fallback)
if [ "$FRESH_BACKUP" = true ]; then
    echo "🗄️ Creating fresh backup on Pantheon..."
    ddev terminus backup:create "$PROJECT_NAME.$PANTHEON_ENV" --element=db || { echo "❌ Backup failed"; exit 1; }
fi

TMP_DB="./.ddev/.downloads/${PROJECT_NAME}_${PANTHEON_ENV}.sql.gz"
mkdir -p ./.ddev/.downloads

echo "📥 Downloading backup from $PANTHEON_ENV..."
if ! ddev terminus backup:get "$PROJECT_NAME.$PANTHEON_ENV" --element=db --to="$TMP_DB"; then
    echo "❌ ERROR: Download failed. Try adding --fresh if no backups exist."
    exit 1
fi

echo "💾 Importing to DDEV..."
if ddev import-db --file="$TMP_DB"; then
    rm "$TMP_DB"
    echo "✅ Success!"
else
    echo "❌ ERROR: Import failed."
    exit 1
fi
