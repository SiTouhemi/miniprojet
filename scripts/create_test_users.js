#!/usr/bin/env node

/**
 * Create Test Users Script for ISET Com Restaurant Login Testing
 * Creates 1 admin, 1 staff, and 2 students with the same password
 * 
 * Usage: node scripts/create_test_users.js
 * 
 * Prerequisites:
 * 1. Firebase CLI installed and logged in
 * 2. Firebase project initialized
 * 3. Service account key in scripts/serviceAccountKey.json
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Load service account key
const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');

if (!fs.existsSync(serviceAccountPath)) {
    console.error('❌ serviceAccountKey.json not found in scripts/ folder');
    console.log('Please download it from Firebase Console > Project Settings > Service Accounts');
    process.exit(1);
}

const serviceAccount = require('./serviceAccountKey.json');

// Initialize Firebase Admin SDK
try {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
    console.log(`✅ Firebase Admin SDK initialized for project: ${serviceAccount.project_id}`);
} catch (error) {
    console.error('❌ Failed to initialize Firebase Admin SDK:', error.message);
    process.exit(1);
}

const db = admin.firestore();
const auth = admin.auth();

// Test users configuration
const TEST_PASSWORD = 'Test123!';
const testUsers = [
    {
        id: 'admin_test',
        email: 'admin.test@isetcom.tn',
        displayName: 'Admin Test',
        role: 'admin',
        classe: 'Administration',
        pocket: 100.0,
        tickets: 0,
        cin: null,
        phoneNumber: '+216 71 000 001'
    },
    {
        id: 'staff_test',
        email: 'staff.test@isetcom.tn',
        displayName: 'Staff Test',
        role: 'staff',
        classe: 'Personnel',
        pocket: 50.0,
        tickets: 0,
        cin: null,
        phoneNumber: '+216 71 000 002'
    },
    {
        id: 'student_test1',
        email: 'student1.test@isetcom.tn',
        displayName: 'Ahmed Ben Salem',
        role: 'student',
        classe: 'L3 INFO',
        pocket: 15.0,
        tickets: 2,
        cin: 12345678,
        phoneNumber: '+216 71 000 003'
    },
    {
        id: 'student_test2',
        email: 'student2.test@isetcom.tn',
        displayName: 'Fatma Trabelsi',
        role: 'student',
        classe: 'L2 RESEAUX',
        pocket: 12.5,
        tickets: 1,
        cin: 87654321,
        phoneNumber: '+216 71 000 004'
    }
];

async function createTestUsers() {
    console.log('\n🧪 Creating Test Users for Login Testing');
    console.log('=========================================\n');

    const createdUsers = [];
    const errors = [];

    for (const user of testUsers) {
        try {
            console.log(`Creating ${user.role}: ${user.email}...`);

            // 1. Create Firebase Auth user
            let authUser;
            try {
                // Check if user already exists
                authUser = await auth.getUserByEmail(user.email);
                console.log(`   ⚠️  Auth user already exists, updating...`);

                // Update existing user
                await auth.updateUser(authUser.uid, {
                    displayName: user.displayName,
                    password: TEST_PASSWORD
                });
            } catch (error) {
                if (error.code === 'auth/user-not-found') {
                    // Create new user
                    authUser = await auth.createUser({
                        uid: user.id,
                        email: user.email,
                        password: TEST_PASSWORD,
                        displayName: user.displayName,
                        emailVerified: true
                    });
                    console.log(`   ✅ Created Firebase Auth user`);
                } else {
                    throw error;
                }
            }

            // 2. Set custom claims for role-based access
            await auth.setCustomUserClaims(authUser.uid, {
                role: user.role,
                classe: user.classe
            });
            console.log(`   ✅ Set custom claims (role: ${user.role})`);

            // 3. Create/Update Firestore user document
            const userData = {
                uid: authUser.uid,
                email: user.email,
                displayName: user.displayName,
                nom: user.displayName,
                role: user.role,
                classe: user.classe,
                pocket: user.pocket,
                tickets: user.tickets,
                cin: user.cin,
                phoneNumber: user.phoneNumber,
                language: 'fr',
                notificationsEnabled: true,
                createdTime: admin.firestore.FieldValue.serverTimestamp(),
                lastLogin: null,
                isTestAccount: true
            };

            await db.collection('user').doc(authUser.uid).set(userData, { merge: true });
            console.log(`   ✅ Created/Updated Firestore document`);

            createdUsers.push({
                email: user.email,
                password: TEST_PASSWORD,
                role: user.role,
                displayName: user.displayName,
                classe: user.classe,
                uid: authUser.uid
            });

            console.log(`   🎉 Successfully created ${user.role}: ${user.email}\n`);

        } catch (error) {
            console.error(`   ❌ Failed to create ${user.email}: ${error.message}\n`);
            errors.push({
                email: user.email,
                error: error.message
            });
        }
    }

    // Generate credentials file
    const credentialsContent = generateCredentialsFile(createdUsers, errors);
    const credentialsPath = path.join(__dirname, '..', 'test_credentials.txt');

    fs.writeFileSync(credentialsPath, credentialsContent);
    console.log(`📄 Test credentials saved to: ${credentialsPath}`);

    // Summary
    console.log('\n📊 Summary:');
    console.log(`   ✅ Successfully created: ${createdUsers.length} users`);
    console.log(`   ❌ Failed: ${errors.length} users`);

    if (createdUsers.length > 0) {
        console.log('\n🔐 Test Accounts Created:');
        createdUsers.forEach(user => {
            console.log(`   • ${user.role.toUpperCase()}: ${user.email} (${user.displayName})`);
        });
        console.log(`\n🔑 All accounts use password: ${TEST_PASSWORD}`);
    }

    if (errors.length > 0) {
        console.log('\n❌ Errors:');
        errors.forEach(error => {
            console.log(`   • ${error.email}: ${error.error}`);
        });
    }

    console.log('\n🚀 Ready to test login!');
    console.log('   1. Run your Flutter app: flutter run');
    console.log('   2. Use any of the test accounts above');
    console.log('   3. Check role-based navigation works correctly');
    console.log(`   4. Credentials are saved in: test_credentials.txt`);
}

function generateCredentialsFile(users, errors) {
    const timestamp = new Date().toISOString();

    let content = `ISET COM RESTAURANT - TEST CREDENTIALS
Generated: ${timestamp}
========================================

LOGIN TESTING ACCOUNTS
All accounts use the same password for easy testing.

PASSWORD FOR ALL ACCOUNTS: ${TEST_PASSWORD}

ACCOUNTS:
`;

    users.forEach(user => {
        content += `
${user.role.toUpperCase()} ACCOUNT:
  Email: ${user.email}
  Password: ${user.password}
  Name: ${user.displayName}
  Class: ${user.classe}
  UID: ${user.uid}
  
  Expected Navigation: ${getRoleNavigation(user.role)}
`;
    });

    if (errors.length > 0) {
        content += `\nERRORS DURING CREATION:
`;
        errors.forEach(error => {
            content += `  • ${error.email}: ${error.error}\n`;
        });
    }

    content += `
TESTING INSTRUCTIONS:
1. Open your Flutter app
2. Go to login screen
3. Use any email/password combination above
4. Verify role-based navigation:
   - Admin should go to: /adminDashboard
   - Staff should go to: /monjeyaScan  
   - Student should go to: /home

ROLE PERMISSIONS:
• ADMIN: Full access to all features
• STAFF: QR scanning, occupancy monitoring
• STUDENT: Reservations, profile, menu viewing

TROUBLESHOOTING:
- If login fails, check Firebase Console > Authentication
- Verify custom claims are set in Firebase Console
- Check Firestore user documents exist
- Ensure Cloud Functions are deployed

Generated by: scripts/create_test_users.js
Project: ${serviceAccount.project_id}
`;

    return content;
}

function getRoleNavigation(role) {
    switch (role) {
        case 'admin':
            return '/adminDashboard (Admin Dashboard)';
        case 'staff':
            return '/monjeyaScan (QR Scanner)';
        case 'student':
            return '/home (Student Home)';
        default:
            return '/login (Login Page)';
    }
}

// Run the script
if (require.main === module) {
    createTestUsers().then(() => {
        process.exit(0);
    }).catch(error => {
        console.error('❌ Script failed:', error);
        process.exit(1);
    });
}

module.exports = { createTestUsers, testUsers, TEST_PASSWORD };