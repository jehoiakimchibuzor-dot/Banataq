/**
 * Banataq Firestore security-rules tests (Firebase emulator).
 *
 * Run:
 *   npm i -g firebase-tools
 *   firebase emulators:start --only firestore
 *   npx mocha firestore.rules.test.js --timeout 10000
 *
 * Requires: firebase-admin, @firebase/rules-unit-testing, mocha.
 * These tests are NOT part of `flutter test`; they validate firestore.rules
 * against the emulator. The Flutter-side path-scoping checks live in
 * test/firestore_security_test.dart.
 */
const assert = require('assert');

let testEnv;
try {
  const { initializeTestEnvironment } = require('@firebase/rules-unit-testing');
  testEnv = { initializeTestEnvironment };
} catch (e) {
  console.log('SKIP: @firebase/rules-unit-testing not installed. Run `npm i -D @firebase/rules-unit-testing firebase-admin mocha` first.');
  return;
}

const PROJECT_ID = 'banataq-80a9b';
const RULES_PATH = './firestore.rules';

async function main() {
  const { initializeTestEnvironment } = testEnv;
  const env = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules: require('fs').readFileSync(RULES_PATH, 'utf8') },
  });

  const owner = env.authenticatedContext('user-owner');
  const stranger = env.authenticatedContext('user-stranger');
  const anon = env.unauthenticatedContext();

  const wsPath = 'users/user-owner/workspaces/ws-1';
  const sessionPath = `${wsPath}/sessions/s-1`;
  const messagePath = `${sessionPath}/messages/m-1`;
  const taskPath = `${wsPath}/tasks/t-1`;
  const filePath = `${wsPath}/files/f-1`;
  const memoryPath = `${wsPath}/memories/m-1`;

  // Seed owner data as admin.
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await db.doc(wsPath).set({ name: 'WS', ownerId: 'user-owner' });
    await db.doc(sessionPath).set({ title: 'S' });
    await db.doc(messagePath).set({ text: 'hi' });
    await db.doc(taskPath).set({ title: 'T' });
    await db.doc(filePath).set({ name: 'f' });
    await db.doc(memoryPath).set({ title: 'M' });
  });

  // 1. Authenticated owner -> allowed (workspace + nested resources).
  for (const p of [wsPath, sessionPath, messagePath, taskPath, filePath, memoryPath]) {
    await assert.doesNotReject(owner.firestore().doc(p).get(), `owner read ${p}`);
    await assert.doesNotReject(
      owner.firestore().doc(p).set({ probe: 1 }, { merge: true }),
      `owner write ${p}`,
    );
  }

  // 2. Authenticated different user -> denied.
  for (const p of [wsPath, sessionPath, messagePath, taskPath, filePath, memoryPath]) {
    await assert.rejects(stranger.firestore().doc(p).get(), `stranger read ${p} denied`);
    await assert.rejects(stranger.firestore().doc(p).set({ probe: 1 }), `stranger write ${p} denied`);
  }

  // 3. Unauthenticated -> denied.
  for (const p of [wsPath, sessionPath]) {
    await assert.rejects(anon.firestore().doc(p).get(), `anon read ${p} denied`);
    await assert.rejects(anon.firestore().doc(p).set({ probe: 1 }), `anon write ${p} denied`);
  }

  // 4. Cross-user top-level read denied.
  await assert.rejects(
    stranger.firestore().doc('users/user-owner').get(),
    'stranger user doc denied',
  );

  console.log('PASS: all firestore.rules checks passed');
  await env.cleanup();
}

main().catch((e) => {
  console.error('FAIL:', e);
  process.exit(1);
});
