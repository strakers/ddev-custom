#!/bin/bash

## Description: Checks if UID 1 is blocked; unblocks if needed, then opens in Chrome.
## Usage: login
## Example: "ddev login"

# 1. Get the status of UID 1 directly as a string (1=active, 0=blocked)
# The --field option returns just the value, and --format=string ensures no table borders.
STATUS=$(ddev drush user:information --uid=1 --field=user_status --format=string 2>/dev/null)

# 2. Check if we need to unblock
if [ "$STATUS" = "0" ]; then
    echo "Superuser (UID 1) is currently blocked. Unblocking..."
    ddev drush user:unblock --uid=1
elif [ "$STATUS" = "1" ]; then
    echo "Superuser (UID 1) is already active."
else
    # Fallback if the command fails or returns unexpected output
    echo "Status unknown (current: '$STATUS'). Attempting unblock just in case..."
    ddev drush user:unblock --uid=1
fi

# 3. Generate the login URL
LOGIN_URL=$(ddev drush uli --uid=1 --no-browser)

echo "Opening login link in Chrome: $LOGIN_URL"

# 4. Open in Chrome based on DDEV_GOOS
case "$DDEV_GOOS" in
    darwin)  open -a "Google Chrome" "$LOGIN_URL" ;;
    windows) start chrome "$LOGIN_URL" ;;
    linux)   google-chrome "$LOGIN_URL" > /dev/null 2>&1 & ;;
    *)       echo "Browser launch not supported on this OS. URL: $LOGIN_URL" ;;
esac
