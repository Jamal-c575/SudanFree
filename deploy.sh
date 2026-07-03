#!/bin/bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm use 20.11.1
export GOOGLE_APPLICATION_CREDENTIALS="/home/jamal/Projects/SUDAN-App/key.json"

MAX_RETRIES=10
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  echo "Attempt $((RETRY_COUNT+1)) of $MAX_RETRIES..."
  # Added --force to bypass the interactive prompt for deleting missing functions
  npx -y firebase-tools@latest deploy --only functions --project sudanfree-d04fc --non-interactive --force --debug
  EXIT_CODE=$?
  if [ $EXIT_CODE -eq 0 ]; then
    echo "Deployment successful!"
    exit 0
  else
    echo "Deployment failed with exit code $EXIT_CODE. Retrying in 5 seconds..."
    RETRY_COUNT=$((RETRY_COUNT+1))
    sleep 5
  fi
done

echo "Deployment failed after $MAX_RETRIES attempts."
exit 1
