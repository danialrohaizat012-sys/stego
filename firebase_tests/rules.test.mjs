// Firestore security-rules tests. Run: cd firebase_tests && npm install && npm test
import { readFileSync } from 'node:fs';
import { test, before, after, beforeEach } from 'node:test';
import {
  initializeTestEnvironment, assertSucceeds, assertFails,
} from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, updateDoc, writeBatch, runTransaction, collection, query, where, getDocs, increment,
} from 'firebase/firestore';

let env;
before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-stegoland',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'), host: '127.0.0.1', port: 8080 },
  });
});
after(() => env.cleanup());
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'staff/staff1'), { email: 'staf@stegoland.my' });
    await setDoc(doc(db, 'config/settings'), { slotCapacity: 80 });
    await setDoc(doc(db, 'menu/m1'), { id: 'm1', name: 'Set A', price: 12.9 });
    await setDoc(doc(db, 'deals/LC-1'), { id: 'LC-1', itemId: 'm1', date: '2026-11-27', price: 7.9, qtyLeft: 3 });
    await setDoc(doc(db, 'members/alice'), { id: 'STG-1', name: 'Alice', phone: '0123456789', points: 200, joined: '2026-11-01' });
  });
});

const alice = () => env.authenticatedContext('alice').firestore();
const bob = () => env.authenticatedContext('bob').firestore();
const staff = () => env.authenticatedContext('staff1').firestore();
const anon = () => env.unauthenticatedContext().firestore();

const booking = (id, owner, extra = {}) => ({
  id, kind: 'family', date: '2026-11-28', slotId: 's1', children: 2, guardians: 1, total: 43,
  status: 'confirmed', paid: false, contactName: 'Alice', contactPhone: '0123456789',
  createdAt: '2026-11-27T10:00:00.000', ownerUid: owner, ...extra,
});
const entry = (b) => ({ date: b.date, slotId: b.slotId, children: b.children, private: false, active: true });

async function book(db, b) {
  const batch = writeBatch(db);
  batch.set(doc(db, `bookings/${b.id}`), b);
  batch.set(doc(db, `slotEntries/${b.id}`), entry(b));
  return batch.commit();
}

test('anyone can read menu and config; only staff can edit', async () => {
  await assertSucceeds(getDoc(doc(anon(), 'menu/m1')));
  await assertSucceeds(getDoc(doc(anon(), 'config/settings')));
  await assertFails(setDoc(doc(alice(), 'menu/m1'), { price: 1 }));
  await assertSucceeds(setDoc(doc(staff(), 'menu/m1'), { id: 'm1', name: 'Set A', price: 11 }));
});

test('customer books with matching slot entry; cannot fake ownership or status', async () => {
  await assertSucceeds(book(alice(), booking('TKT-1', 'alice')));
  await assertFails(book(alice(), booking('TKT-2', 'bob')));
  await assertFails(book(alice(), booking('TKT-3', 'alice', { paid: true })));
  await assertFails(book(alice(), booking('TKT-4', 'alice', { kind: 'group', status: 'confirmed' })));
  // booking without its slot entry
  await assertFails(setDoc(doc(alice(), 'bookings/TKT-5'), booking('TKT-5', 'alice')));
  // slot entry that understates seats
  const b = booking('TKT-6', 'alice');
  const db = alice();
  const batch = writeBatch(db);
  batch.set(doc(db, 'bookings/TKT-6'), b);
  batch.set(doc(db, 'slotEntries/TKT-6'), { ...entry(b), children: 1 });
  await assertFails(batch.commit());
});

test('bookings are private; slot entries are public', async () => {
  await book(alice(), booking('TKT-1', 'alice'));
  await assertSucceeds(getDoc(doc(alice(), 'bookings/TKT-1')));
  await assertFails(getDoc(doc(bob(), 'bookings/TKT-1')));
  await assertSucceeds(getDoc(doc(staff(), 'bookings/TKT-1')));
  await assertSucceeds(getDoc(doc(bob(), 'slotEntries/TKT-1')));
  await assertSucceeds(getDocs(query(collection(alice(), 'bookings'), where('ownerUid', '==', 'alice'))));
  await assertFails(getDocs(collection(bob(), 'bookings')));
});

test('owner can cancel and release seats, but not confirm or mark paid', async () => {
  await book(alice(), booking('TKT-1', 'alice', {
    kind: 'group', status: 'pending',
    group: { institution: 'Tadika Ceria', institutionType: 'Tadika', teachers: 4, meals: 0, drinks: 0, privateSession: false, notes: '' },
  }));
  await assertFails(updateDoc(doc(alice(), 'bookings/TKT-1'), { status: 'confirmed' }));
  await assertFails(updateDoc(doc(alice(), 'bookings/TKT-1'), { paid: true }));
  await assertFails(updateDoc(doc(alice(), 'slotEntries/TKT-1'), { active: false })); // not cancelled yet
  const db = alice();
  await assertSucceeds(runTransaction(db, async (tx) => {
    tx.update(doc(db, 'bookings/TKT-1'), { status: 'cancelled' });
    tx.update(doc(db, 'slotEntries/TKT-1'), { active: false });
  }));
  await assertFails(updateDoc(doc(bob(), 'slotEntries/TKT-1'), { active: true }));
  await assertSucceeds(updateDoc(doc(staff(), 'bookings/TKT-1'), { status: 'confirmed', paid: true }));
});

test('orders: owner creates, only staff changes status', async () => {
  const o = { id: 'ORD-1', ownerUid: 'alice', status: 'received', lines: [{ itemId: 'm1', name: 'Set A', price: 12.9, qty: 1 }], total: 12.9 };
  await assertSucceeds(setDoc(doc(alice(), 'orders/ORD-1'), o));
  await assertFails(setDoc(doc(alice(), 'orders/ORD-2'), { ...o, id: 'ORD-2', status: 'completed' }));
  await assertFails(updateDoc(doc(alice(), 'orders/ORD-1'), { status: 'completed' }));
  await assertFails(getDoc(doc(bob(), 'orders/ORD-1')));
  await assertSucceeds(updateDoc(doc(staff(), 'orders/ORD-1'), { status: 'preparing' }));
});

test('last call stock can only go down', async () => {
  await assertSucceeds(updateDoc(doc(alice(), 'deals/LC-1'), { qtyLeft: 1 }));
  await assertFails(updateDoc(doc(alice(), 'deals/LC-1'), { qtyLeft: 5 }));
  await assertFails(updateDoc(doc(alice(), 'deals/LC-1'), { price: 0.1 }));
  await assertFails(updateDoc(doc(alice(), 'deals/LC-1'), { qtyLeft: -1 }));
});

test('members: cannot add own points; vouchers must be paid for', async () => {
  await assertFails(updateDoc(doc(alice(), 'members/alice'), { points: 9999 }));
  await assertSucceeds(updateDoc(doc(alice(), 'members/alice'), { name: 'Alice R' }));
  await assertFails(getDoc(doc(bob(), 'members/alice')));
  await assertFails(setDoc(doc(bob(), 'members/bob'), { id: 'x', name: 'Bob', phone: '1', points: 50, joined: 'x' }));
  await assertSucceeds(setDoc(doc(bob(), 'members/bob'), { id: 'x', name: 'Bob', phone: '1', points: 0, joined: 'x' }));

  // free voucher (no points spent) is rejected
  await assertFails(setDoc(doc(alice(), 'members/alice/vouchers/RWD-1'), { code: 'RWD-1', title: 'x', cost: 50, used: false, createdAt: 'x' }));
  const db = alice();
  await assertSucceeds(runTransaction(db, async (tx) => {
    tx.update(doc(db, 'members/alice'), { points: 150 });
    tx.set(doc(db, 'members/alice/vouchers/RWD-2'), { code: 'RWD-2', title: 'x', cost: 50, used: false, createdAt: 'x' });
  }));
  // staff awards points
  await assertSucceeds(updateDoc(doc(staff(), 'members/alice'), { points: increment(43) }));
});

test('private session flag must match the booking', async () => {
  const b = booking('GRP-1', 'alice', {
    kind: 'group', status: 'pending', children: 30,
    group: { institution: 'SK X', institutionType: 'Sekolah Rendah', teachers: 3, meals: 0, drinks: 0, privateSession: true, notes: '' },
  });
  const db = alice();
  const lie = writeBatch(db);
  lie.set(doc(db, 'bookings/GRP-1'), b);
  lie.set(doc(db, 'slotEntries/GRP-1'), { ...entry(b), private: false });
  await assertFails(lie.commit());
  const ok = writeBatch(db);
  ok.set(doc(db, 'bookings/GRP-1'), b);
  ok.set(doc(db, 'slotEntries/GRP-1'), { ...entry(b), private: true });
  await assertSucceeds(ok.commit());
});

test('staff docs cannot be self-created', async () => {
  await assertFails(setDoc(doc(alice(), 'staff/alice'), { email: 'a@b.c' }));
});
