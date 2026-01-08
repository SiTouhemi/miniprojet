#!/usr/bin/env node

/**
 * Firebase Admin Script to Add Side Dishes
 * Run with: node scripts/add_side_dishes_admin.js
 */

const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin
const serviceAccount = require('../firebase/service-account-key.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Side dishes to add
const sideDishes = [
    {
        nom: "Pita Bread & Hummus",
        categorie: "Side Dish",
        prix: 1.5,
        ingredients: "Fresh pita bread, chickpea hummus, olive oil",
        image: "https://images.unsplash.com/photo-1621955964441-c173e01c135b?w=400",
        disponible: true
    },
    {
        nom: "French Fries",
        categorie: "Side Dish",
        prix: 1.0,
        ingredients: "Crispy golden french fries, sea salt",
        image: "https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=400",
        disponible: true
    },
    {
        nom: "Rice Pilaf",
        categorie: "Side Dish",
        prix: 1.2,
        ingredients: "Basmati rice, butter, herbs, vegetables",
        image: "https://images.unsplash.com/photo-1516684732162-798a0062be99?w=400",
        disponible: true
    },
    {
        nom: "Couscous",
        categorie: "Side Dish",
        prix: 1.5,
        ingredients: "Traditional Tunisian couscous, vegetables",
        image: "https://images.unsplash.com/photo-1645177628172-a94c1f96e6db?w=400",
        disponible: true
    },
    {
        nom: "Grilled Vegetables",
        categorie: "Side Dish",
        prix: 1.8,
        ingredients: "Zucchini, bell peppers, eggplant, olive oil",
        image: "https://images.unsplash.com/photo-1597362925123-77861d3fbac7?w=400",
        disponible: true
    },
    {
        nom: "Garlic Bread",
        categorie: "Side Dish",
        prix: 1.0,
        ingredients: "Baguette, garlic butter, parsley",
        image: "https://images.unsplash.com/photo-1573140401552-388e3c0b1f6e?w=400",
        disponible: true
    },
    {
        nom: "Pasta Salad",
        categorie: "Side Dish",
        prix: 1.5,
        ingredients: "Pasta, vegetables, vinaigrette dressing",
        image: "https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=400",
        disponible: true
    },
    {
        nom: "Mashed Potatoes",
        categorie: "Side Dish",
        prix: 1.2,
        ingredients: "Creamy mashed potatoes, butter, milk",
        image: "https://images.unsplash.com/photo-1585307269-f2d6e2a4d6c7?w=400",
        disponible: true
    },
    {
        nom: "Steamed Vegetables",
        categorie: "Side Dish",
        prix: 1.3,
        ingredients: "Broccoli, carrots, green beans",
        image: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400",
        disponible: true
    },
    {
        nom: "Bread Rolls",
        categorie: "Side Dish",
        prix: 0.8,
        ingredients: "Fresh baked bread rolls, butter",
        image: "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400",
        disponible: true
    }
];

async function addSideDishes() {
    console.log('🍞 Starting to add side dishes to Firestore...\n');

    const platCollection = db.collection('plat');
    let addedCount = 0;
    let skippedCount = 0;
    let errorCount = 0;

    try {
        for (const dish of sideDishes) {
            try {
                // Check if dish already exists
                const existingQuery = await platCollection
                    .where('nom', '==', dish.nom)
                    .limit(1)
                    .get();

                if (existingQuery.empty) {
                    // Add the dish with server timestamp
                    await platCollection.add({
                        ...dish,
                        created_at: admin.firestore.FieldValue.serverTimestamp()
                    });
                    console.log(`✅ Added: ${dish.nom} - ${dish.prix} DT`);
                    addedCount++;
                } else {
                    console.log(`⊘  Skipped (already exists): ${dish.nom}`);
                    skippedCount++;
                }
            } catch (error) {
                console.error(`❌ Error adding ${dish.nom}:`, error.message);
                errorCount++;
            }
        }

        console.log('\n' + '='.repeat(60));
        console.log('📊 Summary:');
        console.log('='.repeat(60));
        console.log(`✅ Successfully added: ${addedCount} side dishes`);
        console.log(`⊘  Already existed: ${skippedCount} side dishes`);
        console.log(`❌ Errors: ${errorCount}`);
        console.log(`📝 Total processed: ${sideDishes.length} side dishes`);
        console.log('='.repeat(60));

        if (addedCount > 0) {
            console.log('\n🎉 Success! You can now:');
            console.log('   1. Open your Flutter app');
            console.log('   2. Go to Daily Menu Management');
            console.log('   3. Edit or create a menu');
            console.log('   4. Select accompaniments from the new side dishes');
            console.log('   5. Students will see these items in their menu view\n');
        } else if (skippedCount === sideDishes.length) {
            console.log('\n✨ All side dishes already exist in the database!');
            console.log('   No changes were needed.\n');
        }

    } catch (error) {
        console.error('\n❌ Fatal error:', error);
        process.exit(1);
    } finally {
        // Close the admin connection
        await admin.app().delete();
        console.log('🔒 Connection closed.\n');
    }
}

// Run the script
console.log('🚀 Firebase Admin - Add Side Dishes Script');
console.log('='.repeat(60) + '\n');

addSideDishes()
    .then(() => {
        console.log('✅ Script completed successfully!');
        process.exit(0);
    })
    .catch((error) => {
        console.error('❌ Script failed:', error);
        process.exit(1);
    });
