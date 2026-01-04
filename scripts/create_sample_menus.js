// Simple script to create sample weekly menus using Firebase CLI
// This will create sample menus for each day of the week

const sampleMenus = [
    // Monday (1)
    {
        day_of_week: 1,
        meal_type: 'lunch',
        main_dish: 'Couscous aux légumes',
        accompaniments: ['Salade verte', 'Pain'],
        description: 'Couscous traditionnel avec légumes de saison',
        price: 3.5,
        available: true,
        created_by: 'system'
    },
    {
        day_of_week: 1,
        meal_type: 'dinner',
        main_dish: 'Spaghetti Bolognaise',
        accompaniments: ['Fromage râpé', 'Pain à l\'ail'],
        description: 'Spaghetti avec sauce bolognaise maison',
        price: 4.0,
        available: true,
        created_by: 'system'
    },
    // Tuesday (2)
    {
        day_of_week: 2,
        meal_type: 'lunch',
        main_dish: 'Poulet grillé',
        accompaniments: ['Riz', 'Légumes sautés'],
        description: 'Poulet grillé avec accompagnements',
        price: 4.5,
        available: true,
        created_by: 'system'
    },
    {
        day_of_week: 2,
        meal_type: 'dinner',
        main_dish: 'Pizza Margherita',
        accompaniments: ['Salade mixte'],
        description: 'Pizza fraîche avec mozzarella et basilic',
        price: 3.8,
        available: true,
        created_by: 'system'
    },
    // Wednesday (3)
    {
        day_of_week: 3,
        meal_type: 'lunch',
        main_dish: 'Poisson grillé',
        accompaniments: ['Pommes de terre', 'Ratatouille'],
        description: 'Poisson frais grillé avec légumes méditerranéens',
        price: 5.0,
        available: true,
        created_by: 'system'
    },
    {
        day_of_week: 3,
        meal_type: 'dinner',
        main_dish: 'Tajine de légumes',
        accompaniments: ['Pain', 'Olives'],
        description: 'Tajine végétarien aux légumes de saison',
        price: 3.2,
        available: true,
        created_by: 'system'
    },
    // Thursday (4)
    {
        day_of_week: 4,
        meal_type: 'lunch',
        main_dish: 'Escalope panée',
        accompaniments: ['Frites', 'Salade verte'],
        description: 'Escalope de poulet panée avec frites maison',
        price: 4.2,
        available: true,
        created_by: 'system'
    },
    {
        day_of_week: 4,
        meal_type: 'dinner',
        main_dish: 'Lasagnes',
        accompaniments: ['Salade César', 'Pain à l\'ail'],
        description: 'Lasagnes à la viande avec béchamel',
        price: 4.3,
        available: true,
        created_by: 'system'
    },
    // Friday (5)
    {
        day_of_week: 5,
        meal_type: 'lunch',
        main_dish: 'Kefta aux œufs',
        accompaniments: ['Pain', 'Salade de tomates'],
        description: 'Kefta traditionnelle avec œufs et sauce tomate',
        price: 3.8,
        available: true,
        created_by: 'system'
    },
    {
        day_of_week: 5,
        meal_type: 'dinner',
        main_dish: 'Burger maison',
        accompaniments: ['Frites', 'Cornichons'],
        description: 'Burger fait maison avec steak haché frais',
        price: 4.8,
        available: true,
        created_by: 'system'
    },
    // Saturday (6)
    {
        day_of_week: 6,
        meal_type: 'lunch',
        main_dish: 'Paella aux fruits de mer',
        accompaniments: ['Pain', 'Citron'],
        description: 'Paella traditionnelle aux fruits de mer',
        price: 5.5,
        available: true,
        created_by: 'system'
    },
    {
        day_of_week: 6,
        meal_type: 'dinner',
        main_dish: 'Gratin de pâtes',
        accompaniments: ['Salade verte', 'Pain'],
        description: 'Gratin de pâtes au fromage et béchamel',
        price: 3.5,
        available: true,
        created_by: 'system'
    }
];

console.log('Sample weekly menus data:');
console.log(JSON.stringify(sampleMenus, null, 2));
console.log(`\nTotal menus: ${sampleMenus.length}`);
console.log('Days covered: Monday-Saturday (1-6)');
console.log('Sunday (7) has no meals - restaurant closed');