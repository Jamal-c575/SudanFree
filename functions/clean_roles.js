const admin = require('firebase-admin');

// تهيئة Firebase Admin
// تأكد من تعيين GOOGLE_APPLICATION_CREDENTIALS أو تشغيل السكربت في بيئة مسجلة
admin.initializeApp();

const db = admin.firestore();

async function cleanRoles() {
  console.log('Starting role cleanup...');
  const usersRef = db.collection('users');
  const snapshot = await usersRef.get();
  
  let updatedCount = 0;
  const batch = db.batch();

  snapshot.forEach((doc) => {
    const data = doc.data();
    if (!data.role) return;

    const originalRole = data.role;
    let newRole = null;

    // تنظيف أدوار المستقلين
    if (['Freelancer', 'FREELANCER', 'freelancer ', 'Freelancer '].includes(originalRole)) {
      newRole = 'freelancer';
    } 
    // تنظيف أدوار المتاجر
    else if (['Shop', 'SHOP', 'shop ', 'Shop '].includes(originalRole)) {
      newRole = 'shop';
    }

    if (newRole) {
      batch.update(doc.ref, { role: newRole });
      updatedCount++;
      console.log(`Prepared update for ${doc.id}: ${originalRole} -> ${newRole}`);
    }
  });

  if (updatedCount > 0) {
    await batch.commit();
    console.log(`✅ Successfully updated ${updatedCount} users.`);
  } else {
    console.log('✨ No dirty roles found. Everything is clean!');
  }
}

cleanRoles().catch(console.error);
