const admin = require('firebase-admin');
const serviceAccount = require('./sudan_free/firebase/google-services.json'); // Adjust path
admin.initializeApp({ credential: admin.credential.cert(require('./sudan_free/firebase/google-services.json')) });
const db = admin.firestore();

async function checkAds() {
  const snap = await db.collection('ads').where('placement', '==', 'communityFeed').get();
  console.log(`Found ${snap.size} communityFeed ads.`);
  snap.forEach(doc => {
    const data = doc.data();
    console.log(`- ${doc.id}: isActive=${data.isActive}, placement=${data.placement}, title=${data.title}`);
  });
}
checkAds();
