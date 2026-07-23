const admin = require('firebase-admin');
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';

const sudanApp = admin.initializeApp({ projectId: 'sudanfree-d04fc' }, 'sudanApp');
const jhomeApp = admin.initializeApp({ projectId: 'jhomeweb-9ee56' }, 'jhomeApp');

async function seed() {
    let uid;
    try {
        const cred = await sudanApp.auth().createUser({
            email: 'admin@sudanfree.com',
            password: 'admin123',
            displayName: 'Admin User'
        });
        uid = cred.uid;
        console.log("Admin user created.");
    } catch(e) {
        if (e.code === 'auth/email-already-exists') {
            console.log("User already exists, updating password.");
            const user = await sudanApp.auth().getUserByEmail('admin@sudanfree.com');
            uid = user.uid;
            await sudanApp.auth().updateUser(uid, { password: 'admin123' });
        } else {
            console.error(e);
            return;
        }
    }
    
    // Seed Firestore
    const data = {
        name: 'Admin User',
        email: 'admin@sudanfree.com',
        role: 'admin'
    };
    await sudanApp.firestore().collection('users').doc(uid).set(data);
    await jhomeApp.firestore().collection('users').doc(uid).set(data);
    console.log("Firestore admin record seeded to both projects.");
}
seed();
