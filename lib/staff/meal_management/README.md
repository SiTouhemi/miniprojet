# Meal Management Feature

## Overview
This feature allows staff members to manage meals (plats) in the restaurant system. Staff can create, read, update, and delete meals with full CRUD operations.

## Features

### 1. **Meal List View**
- Display all meals in a scrollable list
- Each meal card shows:
  - Meal image (or icon if no image)
  - Name
  - Category badge
  - Price
  - Description preview
  - Quick action buttons (Edit/Delete)

### 2. **Search & Filter**
- **Search Bar**: Search meals by name or ingredients
- **Category Filters**: Filter by category (Tous, Entrée, Plat Principal, Dessert, Boisson)
- Real-time filtering as you type

### 3. **Add New Meal**
- Click the "+" button in the app bar
- Fill in meal details:
  - Name (required)
  - Category (required)
  - Description
  - Ingredients
  - Price (required)
  - Image URL
- Validation for required fields

### 4. **Edit Meal**
- Click the edit icon on any meal card
- Modify any meal details
- Changes saved to Firestore immediately

### 5. **Delete Meal**
- Click the delete icon on any meal card
- Confirmation dialog before deletion
- Permanent removal from database

### 6. **View Meal Details**
- Click on any meal card to view full details
- Shows complete information including image

## Navigation

### From Staff Home
1. Navigate to Staff Home (`/staffHome`)
2. Click on "Gérer Menus" card
3. Opens Meal Management page (`/mealManagement`)

### Route Configuration
- **Route Name**: `MealManagement`
- **Route Path**: `/mealManagement`
- **Required Auth**: Yes
- **Allowed Roles**: Staff, Admin

## Data Model

Uses the existing `PlatRecord` schema:
```dart
{
  nom: String,           // Meal name
  categorie: String,     // Category
  description: String,   // Description
  ingredients: String,   // Ingredients list
  prix: double,          // Price in DT
  image: String          // Image URL
}
```

## UI Components

### Colors
- Primary: `#1C1284` (Dark Blue)
- Secondary: `#00A4E4` (Light Blue)
- Success: Green
- Error: Red

### Layout
- Responsive design
- Material Design components
- Smooth animations
- User-friendly dialogs

## Error Handling
- Network error handling
- Invalid input validation
- User-friendly error messages
- Graceful fallbacks for missing images

## Future Enhancements
- Image upload from device
- Bulk operations
- Meal availability toggle
- Nutritional information
- Allergen warnings
- Multi-language support
