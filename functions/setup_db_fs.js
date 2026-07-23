
const admin = require("firebase-admin");
process.env.FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9099";
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";

admin.initializeApp({ projectId: "sudanfree-d04fc" });
const db = admin.firestore();

async function setup() {
    await db.collection("users").doc("admin@sudanfree.com").set({
      email: "admin@sudanfree.com",
      role: "admin",
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log("Firestore User document created/updated.");
}
setup().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
