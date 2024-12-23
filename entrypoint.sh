#!/bin/sh

set -x
set -e

[ -z "${SIGNAL_CLI_CONFIG_DIR}" ] && echo "SIGNAL_CLI_CONFIG_DIR environmental variable needs to be set! Aborting!" && exit 1;

usermod -u ${SIGNAL_CLI_UID} signal-api
groupmod -o -g ${SIGNAL_CLI_GID} signal-api

# Fix permissions to ensure backward compatibility
chown ${SIGNAL_CLI_UID}:${SIGNAL_CLI_GID} -R ${SIGNAL_CLI_CONFIG_DIR}

# Show warning on docker exec
cat <<EOF >> /root/.bashrc
echo "WARNING: signal-cli-rest-api runs as signal-api (not as root!)" 
echo "Run 'su signal-api' before using signal-cli!"
echo "If you want to use signal-cli directly, don't forget to specify the config directory. e.g: \"signal-cli --config ${SIGNAL_CLI_CONFIG_DIR}\""
EOF

cap_prefix="-cap_"
caps="$cap_prefix$(seq -s ",$cap_prefix" 0 $(cat /proc/sys/kernel/cap_last_cap))"

# TODO: check mode
if [ "$MODE" = "json-rpc" ]
then
/usr/bin/jsonrpc2-helper
if [ -n "$JAVA_OPTS" ] ; then
    echo "export JAVA_OPTS='$JAVA_OPTS'" >> /etc/default/supervisor
fi
service supervisor start
supervisorctl start all
fi

export HOST_IP=$(hostname -I | awk '{print $1}')
# Folders
AVATARS_DIR="./home/.local/share/signal-cli/avatars"
ATTACHMENTS_DIR="/home/.local/share/signal-cli/attachments"

# Function to process files
sync_files() {
  for file in "$AVATARS_DIR"/*; do
    if [ -f "$file" ]; then
      filename=$(basename "$file")
      if [ ! -f "$ATTACHMENTS_DIR/$filename.jpg" ]; then
        cp "$file" "$ATTACHMENTS_DIR/$filename.jpg"
        echo "Copied $filename to $ATTACHMENTS_DIR/$filename.jpg"
      fi
    fi
  done
}

# Run the script in the background
while true; do
  sync_files
  sleep 10
done & exec setpriv --reuid=${SIGNAL_CLI_UID} --regid=${SIGNAL_CLI_GID} --init-groups --inh-caps=$caps signal-cli-rest-api -signal-cli-config=${SIGNAL_CLI_CONFIG_DIR}
# Start API as signal-api user
