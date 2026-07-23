#!/bin/bash
npx firebase emulators:start --only auth,firestore,functions --project sudanfree-d04fc > emulator.log 2>&1

