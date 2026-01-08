// Firebase Console Script to Add Side Dishes
// Copy and paste this into your Firebase Console > Firestore > Run Query

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

// Function to add dishes to Firestore
async function addSideDishes() {
    console.log('🍞 Adding side dishes to plat collection...');

    const db = firebase.firestore();
    const platCollection = db.collection('plat');

    let addedCount = 0;

    for (const dish of sideDishes) {
        try {
            // Check if dish already exists
            const existingQuery = await platCollection
                .where('nom', '==', dish.nom)
                .limit(1)
                .get();

            if (existingQuery.empty) {
                await platCollection.add({
                    ...dish,
                    created_at: firebase.firestore.FieldValue.serverTimestamp()
                });
                console.log(`✓ Added: ${dish.nom} - ${dish.prix} DT`);
                addedCount++;
            } else {
                console.log(`⊘ Skipped (already exists): ${dish.nom}`);
            }
        } catch (error) {
            console.error(`❌ Error adding ${dish.nom}:`, error);
        }
    }

    console.log(`\n✅ Completed! Added ${addedCount} new side dishes.`);
    console.log('📱 You can now select these as accompaniments in the Daily Menu Management.');
}

// Run the function
addSideDishes();
