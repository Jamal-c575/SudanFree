const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

initializeApp();

const db = getFirestore();

async function testQuery() {
    try {
        let usersQuery = db.collection('users');
        usersQuery = usersQuery.where('role', '==', 'freelancer');
        usersQuery = usersQuery.where('state', '==', 'الخرطوم');
        usersQuery = usersQuery.where('locality', '==', 'محلية الخرطوم');
        
        console.log("Running query...");
        const snapshot = await usersQuery.get();
        console.log("Query successful! Docs found:", snapshot.size);
    } catch (error) {
        console.error("Query failed with error:", error.message);
    }
}

testQuery();
