const { describe, it } = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const path = require('path');

const src = fs.readFileSync(path.join(__dirname, '../index.js'), 'utf8');

describe('Render gateway — contract', () => {
  it('POST /chat exists', () => assert.match(src, /app\.post\('\/chat'/));
  it('POST /chat/stream exists', () => assert.match(src, /app\.post\('\/chat\/stream'/));
  it('GET / health', () => assert.match(src, /app\.get\('\/'/));
  it('Auth Bearer required', () => assert.match(src, /Authorization/));
  it('AppCheck required', () => assert.match(src, /X-Firebase-AppCheck/));
  it('provider secrets server-only', () => {
    assert.match(src, /process\.env\.GEMINI_KEY/);
    assert.equal(src.includes('String.fromEnvironment'), false);
  });
  it('allowlist routing', () => {
    assert.match(src, /GEMINI_ALLOW/);
    assert.match(src, /GROQ_ALLOW/);
    assert.match(src, /OPENROUTER_ALLOW/);
  });
  it('injection rejected', () => assert.match(src, /Invalid request fields/));
  it('rate limits', () => assert.match(src, /MAX_PROMPT_CHARS/));
  it('secret not in response', () => assert.equal(src.includes('TEST_GEMINI'), false));
  it('health OK', () => assert.match(src, /Banataq AI gateway OK/));
  it('binds 0.0.0.0 PORT', () => assert.match(src, /0\.0\.0\.0/));
  it('no master in Flutter', () => {
    const appKeys = fs.readFileSync(path.join(__dirname, '../../lib/core/constants/app_keys.dart'), 'utf8');
    assert.match(appKeys, /defaultValue: ''/);
  });
});
