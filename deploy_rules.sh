#!/bin/bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm use 20.11.1
export GOOGLE_APPLICATION_CREDENTIALS="/home/jamal/Projects/SUDAN-App/key.json"
npx -y firebase-tools@latest deploy --only firestore:rules --project sudanfree-d04fc --non-interactive --force --debug
