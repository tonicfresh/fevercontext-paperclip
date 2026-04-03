#!/bin/sh
set -e

# Capture runtime UID/GID from environment variables, defaulting to 1000
PUID=${USER_UID:-1000}
PGID=${USER_GID:-1000}

# Adjust the node user's UID/GID if they differ from the runtime request
# and fix volume ownership only when a remap is needed
changed=0

if [ "$(id -u node)" -ne "$PUID" ]; then
    echo "Updating node UID to $PUID"
    usermod -o -u "$PUID" node
    changed=1
fi

if [ "$(id -g node)" -ne "$PGID" ]; then
    echo "Updating node GID to $PGID"
    groupmod -o -g "$PGID" node
    usermod -g "$PGID" node
    changed=1
fi

# Pre-create directories Claude Code expects (avoids EACCES on first run)
mkdir -p /paperclip/.claude/session-env \
         /paperclip/.claude/sessions \
         /paperclip/.claude/projects \
         /paperclip/.claude/statsig \
         /paperclip/.claude/todos \
         /paperclip/.claude/plans

# Always ensure volume ownership is correct (files may be created as root)
chown -R node:node /paperclip

exec gosu node "$@"
