const admin = require('firebase-admin');

// Connect to emulators
process.env.FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9099";
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";

admin.initializeApp({
  projectId: "sudanfree-d04fc"
});

const jhomeAdmin = admin.initializeApp({
  projectId: "jhomeweb-9ee56"
}, "jhome");

const db = admin.firestore();
const auth = admin.auth();
const jhomeDb = jhomeAdmin.firestore();
const jhomeAuth = jhomeAdmin.auth();

async function setup() {
    let user;
    try {
      user = await auth.createUser({
        email: 'admin@sudanfree.com',
        password: '123456',
        emailVerified: true
      });
      console.log("Auth User created:", user.uid);
    } catch (e) {
      if (e.code === "auth/email-already-exists") {
        user = await auth.getUserByEmail('admin@sudanfree.com');
        console.log("Auth User already exists:", user.uid);
      } else {
        throw e;
      }
    }
    
    await db.collection("users").doc(user.uid).set({
      email: "admin@sudanfree.com",
      role: "admin",
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log("Firestore User document created/updated for sudanfree-d04fc.");

    // Setup for Jhome
    let jhomeUser;
    try {
      jhomeUser = await jhomeAuth.createUser({
        uid: user.uid, // Keep the same UID!
        email: 'admin@sudanfree.com',
        password: '123456',
        emailVerified: true
      });
      console.log("Jhome Auth User created:", jhomeUser.uid);
    } catch (e) {
      if (e.code === "auth/email-already-exists" || e.code === "auth/uid-already-exists") {
        jhomeUser = await jhomeAuth.getUserByEmail('admin@sudanfree.com');
        console.log("Jhome Auth User already exists:", jhomeUser.uid);
      } else {
        throw e;
      }
    }

    await jhomeDb.collection("users").doc(jhomeUser.uid).set({
      email: "admin@sudanfree.com",
      role: "admin",
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log("Firestore User document created/updated for jhomeweb-9ee56.");
}

setup().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
