const admin = require('firebase-admin');
const serviceAccount = require('../google-services (3).json');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
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
