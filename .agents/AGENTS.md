# Custom Rules

## Firebase Deployment
Always use the following command when deploying to Firebase to ensure compatibility with Node.js v22 and to use the saved authenticated connection:
```bash
source ~/.nvm/nvm.sh && nvm use 22 && firebase deploy
```
For specific targets like Firestore Rules, append `--only firestore:rules`, etc.

## AI Chat History
The AI Assistant's chat screen (`AiAssistantScreen`) should NEVER hide or delete the conversation history upon exit during the day. The history must be preserved. It should only be cleared when a new day starts, specifically at 1:00 AM at midnight, to leave room for the new day's data.
