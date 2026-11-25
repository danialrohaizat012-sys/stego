import 'models.dart';

// ---------------------------------------------------------------------------
// Default business data.
//
// Sources: the previous Stego PWA (prices, cafe menu, school-visit package,
// phone number, social handle) and public Stegoland posts (opened 16 Jan 2026
// in Pasir Tumboh, Kota Bharu; ball pit, slides, climbing, tubing; zones from
// babies to primary-school age). Everything here can be changed by staff in
// Admin → Tetapan / Menu, so values that still need the owner's confirmation
// (opening hours, slot length, capacity) are just sensible defaults.
// ---------------------------------------------------------------------------

const defaultBusiness = BusinessInfo(
  name: 'Stegoland',
  cafeName: 'Jasmine Cafe',
  tagline: 'Taman permainan indoor bertema angkasa untuk seisi keluarga',
  address: 'Stegoland Indoor Playground, Pasir Tumboh, 16150 Kota Bharu, Kelantan',
  mapsQuery: 'Stegoland Indoor Playground Pasir Tumboh Kota Bharu',
  phone: '018-235 1000',
  whatsapp: '60182351000',
  tiktok: '@stegoland.playground',
  facebook: 'https://www.facebook.com/p/Stegoland-Indoor-Playground-61586719495917/',
  openingHours: 'Setiap hari • 10:00 pagi – 10:00 malam',
);

const _defaultSlots = [
  TimeSlot(id: 's1', start: 10 * 60, end: 12 * 60),
  TimeSlot(id: 's2', start: 12 * 60, end: 14 * 60),
  TimeSlot(id: 's3', start: 14 * 60, end: 16 * 60),
  TimeSlot(id: 's4', start: 16 * 60, end: 18 * 60),
  TimeSlot(id: 's5', start: 18 * 60, end: 20 * 60),
  TimeSlot(id: 's6', start: 20 * 60, end: 22 * 60),
];

const defaultSettings = Settings(
  weekdayPrice: 14,
  weekendPrice: 19,
  holidayPrice: 23,
  guardianPrice: 5,
  groupChildPrice: 10,
  freeTeachers: 5,
  extraTeacherPrice: 5,
  kidsMealPrice: 7.90,
  drinkPrice: 1.90,
  privateSessionPrice: 50,
  groupMinimum: 10,
  slotCapacity: 80,
  slots: _defaultSlots,
  weekendDays: [DateTime.friday, DateTime.saturday],
  holidays: ['2026-12-25'],
  fridayPrayerBreak: true,
  adminPin: '1234',
);

const defaultMenu = <MenuItem>[
  // Sarapan
  MenuItem(
    id: 'm01',
    name: 'Roti Bakar Kaya Butter',
    category: 'Sarapan',
    price: 5.30,
    description: 'Roti bakar rangup dengan kaya & butter',
    available: true,
  ),
  MenuItem(
    id: 'm02',
    name: 'Big Breakfast',
    category: 'Sarapan',
    price: 9.90,
    description: 'Set sarapan lengkap',
    available: true,
  ),
  MenuItem(
    id: 'm03',
    name: 'Telur Separuh Masak',
    category: 'Sarapan',
    price: 3.50,
    description: '2 biji telur separuh masak',
    available: true,
  ),
  MenuItem(
    id: 'm04',
    name: 'Nasi Bungkus',
    category: 'Sarapan',
    price: 5.00,
    description: 'Pilihan harian (RM5.00 – RM5.50)',
    available: true,
  ),
  MenuItem(
    id: 'm05',
    name: 'Kuih-Muih',
    category: 'Sarapan',
    price: 2.50,
    description: 'Kuih tradisional pilihan',
    available: true,
  ),
  // Ayam Goreng
  MenuItem(
    id: 'm10',
    name: 'Ayam Goreng 1 Ketul',
    category: 'Ayam Goreng',
    price: 4.50,
    description: '1 ketul ayam goreng rangup',
    available: true,
  ),
  MenuItem(
    id: 'm11',
    name: 'Set A',
    category: 'Ayam Goreng',
    price: 12.90,
    description: '1 ketul ayam, kentang goreng, air berkarbonat',
    available: true,
  ),
  MenuItem(
    id: 'm12',
    name: 'Set B',
    category: 'Ayam Goreng',
    price: 17.90,
    description: '2 ketul ayam, kentang goreng, air berkarbonat',
    available: true,
  ),
  MenuItem(
    id: 'm13',
    name: 'Family Fiesta',
    category: 'Ayam Goreng',
    price: 39.00,
    description: '5 ketul ayam, kentang goreng besar, 2 air berkarbonat',
    available: true,
  ),
  MenuItem(
    id: 'm14',
    name: 'Tambah Nasi',
    category: 'Ayam Goreng',
    price: 1.00,
    description: 'Nasi putih',
    available: true,
  ),
  // Combo
  MenuItem(
    id: 'm30',
    name: 'Twin Bite',
    category: 'Combo',
    price: 18.00,
    description: 'Burger + chicken tenders + jagung kecil + air',
    available: true,
  ),
  MenuItem(
    id: 'm31',
    name: 'Twin Bite • Cheese Burger',
    category: 'Combo',
    price: 19.00,
    description: 'Twin Bite naik taraf Cheese Burger',
    available: true,
  ),
  MenuItem(
    id: 'm32',
    name: 'Twin Bite • Spicy Chicken',
    category: 'Combo',
    price: 20.00,
    description: 'Twin Bite naik taraf Spicy Chicken Burger',
    available: true,
  ),
  MenuItem(
    id: 'm33',
    name: 'Twin Bite • Biggo',
    category: 'Combo',
    price: 22.00,
    description: 'Twin Bite naik taraf Biggo',
    available: true,
  ),
  MenuItem(
    id: 'm34',
    name: 'Twin Bite • Ziggo',
    category: 'Combo',
    price: 24.00,
    description: 'Twin Bite naik taraf Ziggo',
    available: true,
  ),
  MenuItem(
    id: 'm40',
    name: 'Triple Bite',
    category: 'Combo',
    price: 21.00,
    description: 'Burger + tenders + nugget + jagung kecil + air',
    available: true,
  ),
  MenuItem(
    id: 'm41',
    name: 'Triple Bite • Cheese Burger',
    category: 'Combo',
    price: 22.00,
    description: 'Triple Bite naik taraf Cheese Burger',
    available: true,
  ),
  MenuItem(
    id: 'm42',
    name: 'Triple Bite • Spicy Chicken',
    category: 'Combo',
    price: 23.00,
    description: 'Triple Bite naik taraf Spicy Chicken Burger',
    available: true,
  ),
  MenuItem(
    id: 'm43',
    name: 'Triple Bite • Biggo',
    category: 'Combo',
    price: 24.00,
    description: 'Triple Bite naik taraf Biggo',
    available: true,
  ),
  MenuItem(
    id: 'm44',
    name: 'Triple Bite • Ziggo',
    category: 'Combo',
    price: 25.00,
    description: 'Triple Bite naik taraf Ziggo',
    available: true,
  ),
  MenuItem(
    id: 'm45',
    name: 'Tukar Jagung → Kentang',
    category: 'Combo',
    price: 1.00,
    description: 'Naik taraf jagung kecil kepada kentang goreng',
    available: true,
  ),
  // Snek
  MenuItem(
    id: 'm20',
    name: 'Sausage Bun',
    category: 'Snek',
    price: 8.90,
    description: 'Roti sosej panas',
    available: true,
  ),
  // Kanak-kanak
  MenuItem(
    id: 'm50',
    name: 'Kids Meal',
    category: 'Kanak-kanak',
    price: 7.90,
    description: 'Lemon chicken dengan nasi mentega',
    available: true,
  ),
  MenuItem(
    id: 'm51',
    name: 'Iced Lemon Tea',
    category: 'Minuman',
    price: 1.90,
    description: 'Teh lemon ais',
    available: true,
  ),
];

const menuCategories = ['Sarapan', 'Ayam Goreng', 'Combo', 'Snek', 'Kanak-kanak', 'Minuman'];

const defaultRewards = <Reward>[
  Reward(id: 'r1', title: 'Iced Lemon Tea Percuma', description: 'Tebus di kaunter Jasmine Cafe', cost: 50),
  Reward(id: 'r2', title: 'Diskaun RM5 Tiket', description: 'Untuk satu tempahan tiket kanak-kanak', cost: 150),
  Reward(id: 'r3', title: 'Kids Meal Percuma', description: 'Lemon chicken & nasi mentega', cost: 200),
  Reward(id: 'r4', title: '1 Tiket Kanak-kanak Percuma', description: 'Sah untuk hari biasa sahaja', cost: 400),
];
