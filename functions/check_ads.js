const admin = require('firebase-admin');

// Initialize the app with application default credentials
admin.initializeApp({
  projectId: 'sudanfree-10b27'
});

async function getAds() {
  const db = admin.firestore();
  // Specify default database
  db.settings({ databaseId: '(default)' });

  try {
    const snapshot = await db.collection('ads').get();
    console.log(`Total ads: ${snapshot.size}`);
    snapshot.forEach(doc => {
      const data = doc.data();
      console.log(`Ad ID: ${doc.id}`);
      console.log(`- title: ${data.title}`);
      console.log(`- isActive: ${data.isActive}`);
      console.log(`- placement: ${data.placement}`);
      console.log(`- targetRole: ${data.targetRole}`);
      console.log(`- targetState: ${data.targetState}`);
      if (data.expiryDate) {
        console.log(`- expiryDate: ${data.expiryDate.toDate()}`);
      }
      console.log('---');
    });
  } catch (err) {
    console.error('Error fetching ads:', err);
  }
}

getAds();
