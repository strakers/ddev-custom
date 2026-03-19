#!/bin/bash

## Description: Install dependencies, update DB, and import config with error handling.
## Usage: setup
## Example: "ddev setup"

# 1. Install Composer dependencies
echo "📦 Installing Composer dependencies..."
if ! composer install --no-interaction; then
    echo "❌ ERROR: Composer install failed!"
    echo "💡 Try running 'ddev composer install' manually to see the full error log."
    exit 1
fi

# 2. Apply Database Updates
echo "🆙 Applying database updates..."
if ! drush updatedb -y; then
    echo "❌ ERROR: Drush updatedb failed!"
    exit 1
fi

# 3. Import Configuration
echo "⚙️ Importing Drupal configuration..."
if ! drush config:import -y; then
    echo "❌ ERROR: Configuration import failed!"
    exit 1
fi

# 4. Clear Cache
echo "🧹 Clearing Drupal cache..."
drush cache:rebuild

echo "✅ Setup complete!"
