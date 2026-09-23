const express = require('express');
const admin = require('firebase-admin');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

// -------------------------------------------------------------
// Firebase Admin — service account from Render Secret File
// -------------------------------------------------------------
// Render: Add Secret File at /etc/secrets/service-account.json
// Local dev: set GOOGLE_APPLICATION_CREDENTIALS or FIREBASE_SERVICE_ACCOUNT_JSON
(function initAdmin() {
  const secretPath = '/etc/secrets/service-account.json';
  const envJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  const gac = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  let credential;
  try {
    if (fs.existsSync(secretPath)) {
      const data = JSON.parse(fs.readFileSync(secretPath, 'utf8'));
      credential = admin.credential.cert(data);
    } else if (envJson) {
      credential = admin.credential.cert(JSON.parse(envJson));
    } else if (gac && fs.existsSync(gac)) {
      const data = JSON.parse(fs.readFileSync(gac, 'utf8'));
      credential = admin.credential.cert(data);
    }
  } catch (e) {
    console.warn('Service account load failed, falling back to default:', e.message);
  }
  if (credential) {
    admin.initializeApp({ credential });
  } else {
    // Emulator or default ADC (will fail closed for Auth/AppCheck if no credential)
    try { admin.initializeApp(); } catch (_) {}
  }
})();

const app = express();
app.use(cors({ origin: true }));
app.use(express.json({ limit: '1mb' }));

// -------------------------------------------------------------
// Configurable limits — in-memory for private testing
// -------------------------------------------------------------
const LIMITS = {
  MAX_PROMPT_CHARS: 8000,
  MAX_OUTPUT_TOKENS: 2000,
  MAX_REQUESTS_PER_MINUTE: 30,
  MAX_REQUESTS_PER_DAY: 200,
  MAX_CONCURRENT_PER_USER: 3,
  TIMEOUT_MS: 30000,
};

const IS_EMULATOR = !!process.env.FUNCTIONS_EMULATOR;
const REQUIRE_APP_CHECK = process.env.REQUIRE_APP_CHECK
  ? process.env.REQUIRE_APP_CHECK === 'true'
  : !IS_EMULATOR;

const minuteBuckets = new Map();
const concurrent = new Map();

function cleanError(msg) {
  if (!msg) return 'AI temporarily unavailable';
  const s = String(msg);
  if (s.includes('GEMINI_KEY') || s.includes('GROQ_KEY') || s.includes('OPENROUTER_KEY') || s.includes('OPENAI_KEY')) return 'Provider configuration error';
  if (s.includes('Bearer') || s.includes('Authorization')) return 'Authentication error';
  return s.slice(0, 400);
}
function safeModel(model) { return (model || 'gemini-3.7-flash').toString().slice(0, 120); }
function hashUid(uid){ try{let h=0; for(let i=0;i<uid.length;i++) h=((h<<5)-h)+uid.charCodeAt(i); return (h>>>0).toString(16);}catch(_){return 'unknown'} }

function checkFastLimits(uid) {
  const now = Date.now();
  const m = minuteBuckets.get(uid) || {count: 0, windowStart: now};
  if (now - m.windowStart > 60_000) { m.count = 0; m.windowStart = now; }
  if (m.count >= LIMITS.MAX_REQUESTS_PER_MINUTE) return {limited: true, reason: 'Rate limit: too many requests per minute. Please wait.', code: 'rate_limited'};
  const c = concurrent.get(uid) || 0;
  if (c >= LIMITS.MAX_CONCURRENT_PER_USER) return {limited: true, reason: 'Too many concurrent requests. Please wait.', code: 'concurrent_limit'};
  return {limited: false, _m: m};
}
function bumpFast(uid, m) { m.count++; minuteBuckets.set(uid, m); concurrent.set(uid, (concurrent.get(uid)||0)+1); }
function releaseConcurrent(uid){ const c=concurrent.get(uid)||0; concurrent.set(uid, Math.max(0,c-1)); }

// Durable daily — in-memory for private testing (Render instance restarts reset)
// Documented: resets on cold start, acceptable for private testing.
// Production Firebase Functions uses Firestore aiUsage/{uid}.
const dailyBuckets = new Map(); // uid -> {count, day}
function checkDailyLimit(uid) {
  const day = new Date().toISOString().slice(0,10);
  const d = dailyBuckets.get(uid) || {count: 0, day};
  if (d.day !== day) { d.count = 0; d.day = day; }
  if (d.count >= LIMITS.MAX_REQUESTS_PER_DAY) return {limited: true, reason: 'Daily usage limit reached. Please try tomorrow.', code: 'daily_limit'};
  return {limited: false, _d: d};
}
function bumpDaily(uid, d) { d.count++; dailyBuckets.set(uid, d); }

async function requireAuthenticatedBanataqRequest(req) {
  const authHeader = req.headers.authorization || '';
  const match = authHeader.match(/^Bearer (.+)$/);
  if (!match) return {uid: null, error: {status: 401, body: {error: 'Missing Authorization: Bearer Firebase ID token required', code: 'authentication_required'}}};
  let decoded;
  try { decoded = await admin.auth().verifyIdToken(match[1]); } catch(e){ return {uid: null, error: {status: 401, body: {error: 'Invalid or expired token', code: 'authentication_required'}}}; }
  const appCheckToken = req.headers['x-firebase-appcheck'] || req.headers['X-Firebase-AppCheck'];
  if (REQUIRE_APP_CHECK) {
    if (!appCheckToken) return {uid: null, error: {status: 401, body: {error: 'App Check required. Please update the app.', code: 'app_check_failed'}}};
    try { await admin.appCheck().verifyToken(appCheckToken); } catch(e){ return {uid: null, error: {status: 401, body: {error: 'Invalid App Check token', code: 'app_check_failed'}}}; }
  } else if (appCheckToken) {
    try { await admin.appCheck().verifyToken(appCheckToken); } catch(e){ return {uid: null, error: {status: 401, body: {error: 'Invalid App Check token', code: 'app_check_failed'}}}; }
  }
  return {uid: decoded.uid, decoded};
}

async function fetchWithTimeout(url, opts, ms){
  const ac=new AbortController(); const t=setTimeout(()=>ac.abort(), ms);
  try{ return await fetch(url, {...opts, signal: ac.signal}); } finally{ clearTimeout(t); }
}

// -------------------------------------------------------------
// Health
// -------------------------------------------------------------
app.get('/', (req, res) => {
  res.status(200).send('Banataq AI gateway OK');
});

// -------------------------------------------------------------
// POST /chat
// -------------------------------------------------------------
app.post('/chat', async (req, res) => {
  const auth = await requireAuthenticatedBanataqRequest(req);
  if (auth.error) return res.status(auth.error.status).json(auth.error.body);
  const uid = auth.uid;

  const fast = checkFastLimits(uid);
  if (fast.limited) return res.status(429).json({error: fast.reason, code: fast.code});
  const {prompt, model, history} = req.body || {};
  const safePrompt = (prompt || '').toString();
  if (safePrompt.length > LIMITS.MAX_PROMPT_CHARS) return res.status(413).json({error: 'Request too large. Please shorten your message.', code: 'request_too_large'});
  if (!safePrompt.trim()) return res.status(400).json({error: 'Missing prompt', code: 'request_invalid'});
  if (history != null && !Array.isArray(history)) return res.status(400).json({error: 'Invalid history format', code: 'request_invalid'});
  if (req.body && (req.body.apiKey || req.body.api_key || req.body.Authorization || req.body.url)) {
    return res.status(400).json({error: 'Invalid request fields', code: 'request_invalid'});
  }
  const safeModelName = safeModel(model);
  const daily = checkDailyLimit(uid);
  if (daily.limited) return res.status(429).json({error: daily.reason, code: daily.code});

  bumpFast(uid, fast._m); bumpDaily(uid, daily._d);
  const t0 = Date.now(); let provider='unknown';
  try{
    const GEMINI_ALLOW = ['gemini-3.7-flash','gemini-3.6-flash','gemini-flash-lite-latest','gemini-2.5-flash-lite','gemini-3.1-flash-lite','gemini-3.1-pro-preview'];
    const GROQ_ALLOW = ['qwen/qwen3.6-27b','openai/gpt-oss-120b','llama-3.3-70b-versatile','llama-3.1-8b-instant','deepseek-r1-distill-llama-70b','allam-2-7b'];
    const OPENROUTER_ALLOW = ['nvidia/nemotron-3-nano-30b-a3b:free','google/gemma-4-31b-it:free','z-ai/glm-5.2:free','nvidia/nemotron-3-super-120b-a12b:free','deepseek/deepseek-r1:free','deepseek/deepseek-chat:free','meta-llama/llama-3.2-3b-instruct:free','meta-llama/llama-3.2-90b-vision-instruct:free','qwen/qwen-2.5-7b-instruct:free','qwen/qwen-2.5-72b-instruct:free','mistralai/mistral-7b-instruct:free','mistralai/mistral-nemo:free','google/gemma-2-9b-it:free'];
    let data, url, key, body;
    if (GEMINI_ALLOW.includes(safeModelName)) {
      provider='gemini'; key=process.env.GEMINI_KEY; if(!key) throw new Error('Provider temporarily unavailable');
      url=`https://generativelanguage.googleapis.com/v1beta/models/${safeModelName}:generateContent?key=${key}`;
      body={contents:[{parts:[{text:safePrompt}]}], generationConfig:{temperature:0.7, maxOutputTokens: LIMITS.MAX_OUTPUT_TOKENS}};
      const r=await fetchWithTimeout(url,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)}, LIMITS.TIMEOUT_MS);
      data=await r.json(); if(!r.ok) throw new Error(data.error?.message||`Gemini ${r.status}`);
      const text=data.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
      console.log(JSON.stringify({event:'chat',uidHash:hashUid(uid),provider,model:safeModelName,latencyMs:Date.now()-t0,promptChars:safePrompt.length,outputChars:text.length}));
      return res.json({text});
    } else if (GROQ_ALLOW.includes(safeModelName)) {
      provider='groq'; key=process.env.GROQ_KEY; if(!key) throw new Error('Provider temporarily unavailable');
      url='https://api.groq.com/openai/v1/chat/completions';
      body={model:safeModelName,messages:[...(history||[]).map(h=>({role:h.role,content:h.content})),{role:'user',content:safePrompt}],temperature:0.7,max_tokens:LIMITS.MAX_OUTPUT_TOKENS};
      const r=await fetchWithTimeout(url,{method:'POST',headers:{'Content-Type':'application/json','Authorization':`Bearer ${key}`},body:JSON.stringify(body)}, LIMITS.TIMEOUT_MS);
      data=await r.json(); if(!r.ok) throw new Error(data.error?.message||`Groq ${r.status}`);
      const text=data.choices?.[0]?.message?.content ?? '';
      console.log(JSON.stringify({event:'chat',uidHash:hashUid(uid),provider,model:safeModelName,latencyMs:Date.now()-t0,promptChars:safePrompt.length,outputChars:text.length}));
      return res.json({text});
    } else if (OPENROUTER_ALLOW.includes(safeModelName)) {
      provider='openrouter'; key=process.env.OPENROUTER_KEY; if(!key) throw new Error('Provider temporarily unavailable');
      url='https://openrouter.ai/api/v1/chat/completions';
      body={model:safeModelName,messages:[...(history||[]).map(h=>({role:h.role,content:h.content})),{role:'user',content:safePrompt}]};
      const r=await fetchWithTimeout(url,{method:'POST',headers:{'Content-Type':'application/json','Authorization':`Bearer ${key}`,'HTTP-Referer':'https://banataq.app','X-Title':'Banataq'},body:JSON.stringify(body)}, LIMITS.TIMEOUT_MS);
      data=await r.json(); if(!r.ok) throw new Error(data.error?.message||`OpenRouter ${r.status}`);
      const text=data.choices?.[0]?.message?.content ?? '';
      console.log(JSON.stringify({event:'chat',uidHash:hashUid(uid),provider,model:safeModelName,latencyMs:Date.now()-t0,promptChars:safePrompt.length,outputChars:text.length}));
      return res.json({text});
    } else if (safeModelName === 'gpt-4o-mini' || safeModelName.startsWith('gpt-')) {
      provider='openai'; key=process.env.OPENAI_KEY; if(!key) throw new Error('Provider temporarily unavailable');
      url='https://api.openai.com/v1/chat/completions';
      body={model:safeModelName,messages:[...(history||[]).map(h=>({role:h.role,content:h.content})),{role:'user',content:safePrompt}]};
      const r=await fetchWithTimeout(url,{method:'POST',headers:{'Content-Type':'application/json','Authorization':`Bearer ${key}`},body:JSON.stringify(body)}, LIMITS.TIMEOUT_MS);
      data=await r.json(); if(!r.ok) throw new Error(data.error?.message||`OpenAI ${r.status}`);
      const text=data.choices?.[0]?.message?.content ?? '';
      console.log(JSON.stringify({event:'chat',uidHash:hashUid(uid),provider,model:safeModelName,latencyMs:Date.now()-t0,promptChars:safePrompt.length,outputChars:text.length}));
      return res.json({text});
    } else {
      return res.status(400).json({error: 'Unknown model. Please select a supported model.', code: 'request_invalid'});
    }
  } catch(e){
    const msg=cleanError(e.message); let userMsg='AI temporarily unavailable. Please try again.'; let code='provider_unavailable'; const low=msg.toLowerCase();
    if (msg.includes('temporarily unavailable')) { userMsg='AI service is not configured yet.'; code='provider_not_configured'; }
    else if (low.includes('rate limit')||msg.includes('429')) { userMsg='Rate limit reached. Please wait a minute.'; code='provider_rate_limited'; }
    else if (low.includes('quota')||low.includes('billing')) { userMsg='Usage limit reached. Please try later.'; code='provider_quota_exceeded'; }
    console.error(JSON.stringify({event:'chat_error',uidHash:hashUid(uid),provider,model:safeModelName,latencyMs:Date.now()-t0,error:msg,code}));
    return res.status(500).json({error:userMsg, code});
  } finally{ releaseConcurrent(uid); }
});

// -------------------------------------------------------------
// POST /chat/stream
// -------------------------------------------------------------
app.post('/chat/stream', async (req, res) => {
  const auth = await requireAuthenticatedBanataqRequest(req);
  if (auth.error) return res.status(auth.error.status).json(auth.error.body);
  const uid=auth.uid;
  const fast=checkFastLimits(uid); if(fast.limited) return res.status(429).json({error: fast.reason, code: fast.code});
  const {prompt,model,history}=req.body||{}; const safePrompt=(prompt||'').toString();
  if(safePrompt.length > LIMITS.MAX_PROMPT_CHARS) return res.status(413).json({error: 'Request too large. Please shorten your message.', code: 'request_too_large'});
  if(!safePrompt.trim()) return res.status(400).json({error: 'Missing prompt', code: 'request_invalid'});
  if(req.body && (req.body.apiKey || req.body.api_key || req.body.Authorization || req.body.url)) return res.status(400).json({error: 'Invalid request fields', code: 'request_invalid'});
  const safeModelName=safeModel(model);
  const daily=checkDailyLimit(uid); if(daily.limited) return res.status(429).json({error: daily.reason, code: daily.code});
  bumpFast(uid,fast._m); bumpDaily(uid, daily._d);
  let provider='unknown'; const t0=Date.now();
  res.set('Content-Type','text/event-stream'); res.set('Cache-Control','no-cache'); res.set('Connection','keep-alive'); res.set('X-Accel-Buffering','no');
  const onClose=()=>{ releaseConcurrent(uid); try{res.end();}catch(_){} }; req.on('close',onClose); req.on('aborted',onClose);
  try{
    const GEMINI_ALLOW = ['gemini-3.7-flash','gemini-3.6-flash','gemini-flash-lite-latest','gemini-2.5-flash-lite','gemini-3.1-flash-lite','gemini-3.1-pro-preview'];
    const GROQ_ALLOW = ['qwen/qwen3.6-27b','openai/gpt-oss-120b','llama-3.3-70b-versatile','llama-3.1-8b-instant','deepseek-r1-distill-llama-70b','allam-2-7b'];
    const OPENROUTER_ALLOW = ['nvidia/nemotron-3-nano-30b-a3b:free','google/gemma-4-31b-it:free','z-ai/glm-5.2:free','nvidia/nemotron-3-super-120b-a12b:free','deepseek/deepseek-r1:free','deepseek/deepseek-chat:free','meta-llama/llama-3.2-3b-instruct:free','meta-llama/llama-3.2-90b-vision-instruct:free','qwen/qwen-2.5-7b-instruct:free','qwen/qwen-2.5-72b-instruct:free','mistralai/mistral-7b-instruct:free','mistralai/mistral-nemo:free','google/gemma-2-9b-it:free'];
    let url,key,body,headers;
    if(GEMINI_ALLOW.includes(safeModelName)){
      provider='gemini'; key=process.env.GEMINI_KEY; if(!key) throw new Error('Provider temporarily unavailable');
      url=`https://generativelanguage.googleapis.com/v1beta/models/${safeModelName}:streamGenerateContent?alt=sse&key=${key}`;
      body={contents:[{parts:[{text:safePrompt}]}], generationConfig:{temperature:0.7, maxOutputTokens: LIMITS.MAX_OUTPUT_TOKENS}}; headers={'Content-Type':'application/json'};
    } else if(GROQ_ALLOW.includes(safeModelName)){
      provider='groq'; key=process.env.GROQ_KEY; if(!key) throw new Error('Provider temporarily unavailable');
      url='https://api.groq.com/openai/v1/chat/completions';
      body={model:safeModelName,messages:[...(history||[]).map(h=>({role:h.role,content:h.content})),{role:'user',content:safePrompt}],temperature:0.7,max_tokens:LIMITS.MAX_OUTPUT_TOKENS,stream:true}; headers={'Content-Type':'application/json','Authorization':`Bearer ${key}`};
    } else if(OPENROUTER_ALLOW.includes(safeModelName)){
      provider='openrouter'; key=process.env.OPENROUTER_KEY; if(!key) throw new Error('Provider temporarily unavailable');
      url='https://openrouter.ai/api/v1/chat/completions';
      body={model:safeModelName,messages:[...(history||[]).map(h=>({role:h.role,content:h.content})),{role:'user',content:safePrompt}],stream:true}; headers={'Content-Type':'application/json','Authorization':`Bearer ${key}`,'HTTP-Referer':'https://banataq.app','X-Title':'Banataq'};
    } else if(safeModelName === 'gpt-4o-mini' || safeModelName.startsWith('gpt-')){
      provider='openai'; key=process.env.OPENAI_KEY; if(!key) throw new Error('Provider temporarily unavailable');
      url='https://api.openai.com/v1/chat/completions';
      body={model:safeModelName,messages:[...(history||[]).map(h=>({role:h.role,content:h.content})),{role:'user',content:safePrompt}],stream:true}; headers={'Content-Type':'application/json','Authorization':`Bearer ${key}`};
    } else {
      return res.status(400).json({error: 'Unknown model. Please select a supported model.', code: 'request_invalid'});
    }
    const upstream=await fetchWithTimeout(url,{method:'POST',headers,body:JSON.stringify(body)}, LIMITS.TIMEOUT_MS);
    if(!upstream.ok && !upstream.body){ const txt=await upstream.text().catch(()=> ''); throw new Error(cleanError(txt)||`Provider ${upstream.status}`); }
    if(!upstream.body){ res.write(`data: ${JSON.stringify({text:''})}\n\n data: [DONE]\n\n`); return res.end(); }
    const reader=upstream.body.getReader(); const decoder=new TextDecoder(); let buf='';
    while(true){ const {done,value}=await reader.read(); if(done) break; buf+=decoder.decode(value,{stream:true});
      if(provider==='gemini'){ for(const line of buf.split('\n')) if(line.startsWith('data: ')){ try{const j=JSON.parse(line.slice(6)); const t=j.candidates?.[0]?.content?.parts?.[0]?.text; if(t) res.write(`data: ${t}\n\n`);}catch(_){}}
      } else { res.write(buf); buf=''; }
    }
    console.log(JSON.stringify({event:'chat_stream',uidHash:hashUid(uid),provider,model:safeModelName,latencyMs:Date.now()-t0}));
    res.write('data: [DONE]\n\n'); res.end();
  }catch(e){
    const msg=cleanError(e.message); let code='provider_unavailable';
    if (msg.includes('temporarily unavailable')) code='provider_not_configured';
    else if (msg.toLowerCase().includes('rate limit')||msg.includes('429')) code='provider_rate_limited';
    console.error(JSON.stringify({event:'chat_stream_error',uidHash:hashUid(uid),provider,model:safeModelName,error:msg,code}));
    if(!res.headersSent) return res.status(500).json({error:'AI temporarily unavailable. Please try again.', code});
    try{ res.write(`data: ${JSON.stringify({error:'AI temporarily unavailable', code})}\n\n`);}catch(_){}
    res.end();
  }finally{ releaseConcurrent(uid); }
});

const port = process.env.PORT || 10000;
app.listen(port, '0.0.0.0', () => {
  console.log(`Banataq AI gateway listening on 0.0.0.0:${port}`);
});

// Test-only exports
try {
  module.exports._test = {
    LIMITS,
    checkFastLimits,
    bumpFast,
    releaseConcurrent,
    cleanError,
    safeModel,
    hashUid,
    requireAuthenticatedBanataqRequest,
    checkDailyLimit: (uid) => checkDailyLimit(uid),
    REQUIRE_APP_CHECK,
    IS_EMULATOR,
    app,
  };
} catch (_) {}
