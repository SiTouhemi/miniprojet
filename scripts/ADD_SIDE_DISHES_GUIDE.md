# How to Add Side Dishes to Your Database

You have **3 easy options** to add side dishes to your `plat` collection:

---

## ✅ **Option 1: Use Your App's Meal Management** (EASIEST)

1. **Open your Flutter app**
2. **Go to Meal Management** (Staff section)
3. **Click "Add Meal"** button
4. **Fill in the form** for each side dish:
   - **Name**: Pita Bread & Hummus
   - **Category**: Side Dish ⚠️ **IMPORTANT: Type exactly "Side Dish"**
   - **Price**: 1.5
   - **Ingredients**: Fresh pita bread, chickpea hummus, olive oil
   - **Image URL**: (optional)
   - **Available**: ✓ Yes
5. **Repeat** for other side dishes (see list below)

---

## 🔥 **Option 2: Firebase Console** (QUICK)

1. **Open Firebase Console**: https://console.firebase.google.com
2. **Select your project**
3. **Go to Firestore Database**
4. **Click on `plat` collection**
5. **Click "Add Document"**
6. **For each side dish, add these fields**:
   - `nom` (string): "Pita Bread & Hummus"
   - `categorie` (string): "Side Dish"
   - `prix` (number): 1.5
   - `ingredients` (string): "Fresh pita bread, chickpea hummus, olive oil"
   - `image` (string): "https://images.unsplash.com/photo-1621955964441-c173e01c135b?w=400"
   - `disponible` (boolean): true
7. **Click "Save"**
8. **Repeat** for other side dishes

---

## 💻 **Option 3: Run JavaScript in Firebase Console**

1. **Open Firebase Console**
2. **Go to Firestore Database**
3. **Open browser console** (F12 or Right-click > Inspect > Console)
4. **Copy and paste** the contents of `add_side_dishes_firebase.js`
5. **Press Enter** to run
6. **Wait** for completion message

---

## 📋 **Side Dishes to Add**

Here are 10 common side dishes for your university restaurant:

| Name | Category | Price (DT) | Ingredients |
|------|----------|------------|-------------|
| Pita Bread & Hummus | Side Dish | 1.5 | Fresh pita bread, chickpea hummus, olive oil |
| French Fries | Side Dish | 1.0 | Crispy golden french fries, sea salt |
| Rice Pilaf | Side Dish | 1.2 | Basmati rice, butter, herbs, vegetables |
| Couscous | Side Dish | 1.5 | Traditional Tunisian couscous, vegetables |
| Grilled Vegetables | Side Dish | 1.8 | Zucchini, bell peppers, eggplant, olive oil |
| Garlic Bread | Side Dish | 1.0 | Baguette, garlic butter, parsley |
| Pasta Salad | Side Dish | 1.5 | Pasta, vegetables, vinaigrette dressing |
| Mashed Potatoes | Side Dish | 1.2 | Creamy mashed potatoes, butter, milk |
| Steamed Vegetables | Side Dish | 1.3 | Broccoli, carrots, green beans |
| Bread Rolls | Side Dish | 0.8 | Fresh baked bread rolls, butter |

---

## ⚠️ **IMPORTANT NOTES**

1. **Category MUST be exactly**: `Side Dish` (capital S, capital D, with space)
2. **Price is in Tunisian Dinars** (DT)
3. **Images are optional** but make the menu look better
4. **After adding**, refresh your Daily Menu Management page

---

## ✅ **Verify It Worked**

1. **Go to Daily Menu Management**
2. **Click "Edit" on any menu**
3. **Scroll down to "Accompaniments (Optional)"**
4. **You should see**:
   - Blue box showing: "Side dishes found: 10"
   - Checkboxes for all your side dishes

---

## 🎉 **What Happens Next**

Once side dishes are added:
- ✅ Staff can select multiple accompaniments when creating/editing menus
- ✅ Students will see these items in their menu view
- ✅ Prices will automatically include selected accompaniments
- ✅ "Pita Bread & Hummus" and other sides will be properly managed

---

## 🆘 **Need Help?**

If you have issues:
1. Check that category is exactly "Side Dish"
2. Verify dishes appear in the `plat` collection in Firebase
3. Refresh your app after adding dishes
4. Check the debug panel in the edit menu dialog
