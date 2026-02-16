/**
 * Firebase Admin Script to Delete All User Data
 * 
 * This script deletes all data associated with a specific user email
 * across all Firestore collections and Authentication.
 * 
 * Usage: node delete_user_data.js <email>
 * Example: node delete_user_data.js mohitevedant2603@gmail.com
 */

const admin = require('firebase-admin');
const readline = require('readline');

// Initialize Firebase Admin
const serviceAccount = require('../firebase-service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const auth = admin.auth();

const EMAIL_TO_DELETE = process.argv[2];

if (!EMAIL_TO_DELETE) {
  console.error('❌ Error: Please provide an email address');
  console.log('Usage: node delete_user_data.js <email>');
  process.exit(1);
}

// Confirmation prompt
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

async function deleteUserData(email) {
  console.log(`\n🔍 Searching for user: ${email}\n`);

  try {
    // 1. Get user from Authentication
    let userRecord;
    let userId;
    
    try {
      userRecord = await auth.getUserByEmail(email);
      userId = userRecord.uid;
      console.log(`✅ Found user in Authentication: ${userId}`);
    } catch (error) {
      console.log(`⚠️  User not found in Authentication for email: ${email}`);
      
      // Try to find user in Firestore by email
      const emailLookup = await db.collection('email_lookup').doc(email).get();
      if (emailLookup.exists) {
        userId = emailLookup.data().userId;
        console.log(`✅ Found userId from email_lookup: ${userId}`);
      } else {
        // Try searching users collection
        const usersQuery = await db.collection('users').where('email', '==', email).get();
        if (!usersQuery.empty) {
          userId = usersQuery.docs[0].id;
          console.log(`✅ Found userId from users collection: ${userId}`);
        } else {
          console.log('❌ No user found with this email in any system');
          return;
        }
      }
    }

    console.log(`\n📊 Starting comprehensive data deletion for user: ${userId}\n`);

    // 2. Delete from email_lookup collection
    console.log('🗑️  Deleting email lookup...');
    await db.collection('email_lookup').doc(email).delete();
    console.log('✅ Email lookup deleted');

    // 3. Delete user profile and subcollections
    console.log('🗑️  Deleting user profile and subcollections...');
    const userRef = db.collection('users').doc(userId);
    
    // Delete subcollections: friends, friend_requests
    const subcollections = ['friends', 'friend_requests', 'notifications'];
    for (const subcol of subcollections) {
      const subcollectionRef = userRef.collection(subcol);
      await deleteCollection(subcollectionRef, 100);
      console.log(`   ✅ Deleted ${subcol} subcollection`);
    }
    
    // Delete user document
    await userRef.delete();
    console.log('✅ User profile deleted');

    // 4. Delete jobs posted by user
    console.log('🗑️  Deleting jobs posted by user...');
    const jobsQuery = await db.collection('jobs').where('posterId', '==', userId).get();
    let jobsDeleted = 0;
    for (const jobDoc of jobsQuery.docs) {
      // Delete job applications subcollection
      const applicationsRef = jobDoc.ref.collection('applications');
      await deleteCollection(applicationsRef, 100);
      
      await jobDoc.ref.delete();
      jobsDeleted++;
    }
    console.log(`✅ Deleted ${jobsDeleted} jobs`);

    // 5. Delete job applications made by user
    console.log('🗑️  Deleting job applications...');
    let applicationsDeleted = 0;
    const allJobs = await db.collection('jobs').get();
    for (const jobDoc of allJobs.docs) {
      const applicationsQuery = await jobDoc.ref.collection('applications')
        .where('helperId', '==', userId).get();
      
      for (const appDoc of applicationsQuery.docs) {
        await appDoc.ref.delete();
        applicationsDeleted++;
      }
    }
    console.log(`✅ Deleted ${applicationsDeleted} job applications`);

    // 6. Delete chats involving user
    console.log('🗑️  Deleting chats...');
    const chatsQuery = await db.collection('chats').where('participants', 'array-contains', userId).get();
    let chatsDeleted = 0;
    for (const chatDoc of chatsQuery.docs) {
      // Delete messages subcollection
      const messagesRef = chatDoc.ref.collection('messages');
      await deleteCollection(messagesRef, 100);
      
      await chatDoc.ref.delete();
      chatsDeleted++;
    }
    console.log(`✅ Deleted ${chatsDeleted} chats`);

    // 7. Delete notifications sent to user
    console.log('🗑️  Deleting notifications...');
    const notificationsQuery = await db.collection('notifications').where('userId', '==', userId).get();
    let notificationsDeleted = 0;
    for (const notifDoc of notificationsQuery.docs) {
      await notifDoc.ref.delete();
      notificationsDeleted++;
    }
    console.log(`✅ Deleted ${notificationsDeleted} notifications`);

    // 8. Remove user from other users' friends/friend_requests
    console.log('🗑️  Cleaning up friend connections...');
    const allUsers = await db.collection('users').get();
    let friendshipsCleaned = 0;
    for (const otherUserDoc of allUsers.docs) {
      // Delete from friends subcollection
      const friendDoc = await otherUserDoc.ref.collection('friends').doc(userId).get();
      if (friendDoc.exists) {
        await friendDoc.ref.delete();
        friendshipsCleaned++;
      }
      
      // Delete from friend_requests subcollection
      const friendReqDoc = await otherUserDoc.ref.collection('friend_requests').doc(userId).get();
      if (friendReqDoc.exists) {
        await friendReqDoc.ref.delete();
        friendshipsCleaned++;
      }
    }
    console.log(`✅ Cleaned ${friendshipsCleaned} friend connections`);

    // 9. Delete from leaderboard (if exists)
    console.log('🗑️  Checking leaderboard...');
    try {
      await db.collection('leaderboard').doc(userId).delete();
      console.log('✅ Leaderboard entry deleted');
    } catch (err) {
      console.log('   ℹ️  No leaderboard entry found');
    }

    // 10. Delete from Firebase Authentication (final step)
    if (userRecord) {
      console.log('🗑️  Deleting from Firebase Authentication...');
      await auth.deleteUser(userId);
      console.log('✅ User deleted from Authentication');
    }

    console.log(`\n✅ ✅ ✅ All data for ${email} has been successfully deleted! ✅ ✅ ✅\n`);
    
  } catch (error) {
    console.error('\n❌ Error during deletion:', error);
    throw error;
  }
}

// Helper function to delete collections in batches
async function deleteCollection(collectionRef, batchSize) {
  const query = collectionRef.limit(batchSize);

  return new Promise((resolve, reject) => {
    deleteQueryBatch(query, resolve, reject);
  });
}

async function deleteQueryBatch(query, resolve, reject) {
  try {
    const snapshot = await query.get();

    if (snapshot.size === 0) {
      resolve();
      return;
    }

    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();

    // Recurse on the next batch
    process.nextTick(() => {
      deleteQueryBatch(query, resolve, reject);
    });
  } catch (error) {
    reject(error);
  }
}

// Main execution with confirmation
rl.question(
  `⚠️  WARNING: This will permanently delete ALL data for ${EMAIL_TO_DELETE}\n` +
  `Are you absolutely sure? Type "DELETE" to confirm: `,
  async (answer) => {
    if (answer === 'DELETE') {
      try {
        await deleteUserData(EMAIL_TO_DELETE);
        process.exit(0);
      } catch (error) {
        console.error('Failed to delete user data:', error);
        process.exit(1);
      }
    } else {
      console.log('❌ Operation cancelled');
      process.exit(0);
    }
    rl.close();
  }
);
