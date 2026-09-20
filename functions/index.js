const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();
const cors = require('cors')({origin: true});

// Keys in Secret Manager: GEMINI_KEY, GROQ_KEY, OPENROUTER_KEY, OPENAI_KEY
exports.chat = functions.runWith({secrets: ['GEMINI_KEY','GROQ_KEY','OPENROUTER_KEY','OPENAI_KEY']}).https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    if (req.method !== 'POST') return res.status(405).send('POST only');
    // Verify Firebase Auth token — prevents unauthenticated billing abuse
    const authHeader = req.headers.authorization || '';
    const match = authHeader.match(/^Bearer (.+)$/);
    if (!match) return res.status(401).json({error: 'Missing Authorization: Bearer Firebase ID token required'});
    try {
      await admin.auth().verifyIdToken(match[1]);
    } catch (e) {
      return res.status(401).json({error: 'Invalid or expired token'});
    }
    const {prompt, model, history} = req.body;
    // route by model prefix
    try {
      let data, url, key, body;
      if (model.startsWith('gemini')) {
        key = process.env.GEMINI_KEY; url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${key}`;
        body = {contents: [{parts: [{text: prompt}]}], generationConfig: {temperature: 0.7, maxOutputTokens: 2000}};
        const r = await fetch(url, {method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(body)}); data = await r.json(); return res.json({text: data.candidates?.[0]?.content?.parts?.[0]?.text ?? ''});
      } else if (model.includes('qwen') || model.includes('llama') || model.includes('deepseek-r1-distill')) {
        key = process.env.GROQ_KEY; url = 'https://api.groq.com/openai/v1/chat/completions';
        body = {model, messages: [...(history||[]).map(h=>({role:h.role,content:h.content})), {role:'user',content:prompt}], temperature:0.7, max_tokens:2000};
        const r = await fetch(url, {method:'POST', headers:{'Content-Type':'application/json','Authorization':`Bearer ${key}`}, body: JSON.stringify(body)}); data = await r.json(); return res.json({text: data.choices?.[0]?.message?.content ?? ''});
      } else if (model.includes(':free') || model.includes('openai/gpt')) {
        key = process.env.OPENROUTER_KEY; url = 'https://openrouter.ai/api/v1/chat/completions';
        body = {model, messages: [...(history||[]).map(h=>({role:h.role,content:h.content})), {role:'user',content:prompt}]};
        const r = await fetch(url, {method:'POST', headers:{'Content-Type':'application/json','Authorization':`Bearer ${key}`,'HTTP-Referer':'https://banataq.app','X-Title':'Banataq'}, body: JSON.stringify(body)}); data = await r.json(); return res.json({text: data.choices?.[0]?.message?.content ?? ''});
      } else {
        key = process.env.OPENAI_KEY; url = 'https://api.openai.com/v1/chat/completions';
        body = {model: model||'gpt-4o-mini', messages: [...(history||[]).map(h=>({role:h.role,content:h.content})), {role:'user',content:prompt}]};
        const r = await fetch(url, {method:'POST', headers:{'Content-Type':'application/json','Authorization':`Bearer ${key}`}, body: JSON.stringify(body)}); data = await r.json(); return res.json({text: data.choices?.[0]?.message?.content ?? ''});
      }
    } catch(e){ res.status(500).json({error: e.message}); }
  });
});
exports.chatStream = functions.runWith({secrets: ['GEMINI_KEY','GROQ_KEY','OPENROUTER_KEY','OPENAI_KEY']}).https.onRequest(async (req,res)=>{
  cors(req, res, async () => {
    if (req.method !== 'POST') return res.status(405).send('POST only');
    const authHeader = req.headers.authorization || '';
    const match = authHeader.match(/^Bearer (.+)$/);
    if (!match) return res.status(401).send('Missing Authorization');
    try {
      await admin.auth().verifyIdToken(match[1]);
    } catch (e) {
      return res.status(401).send('Invalid token');
    }
    // SSE proxy — pipe provider stream directly (omitted for brevity, same routing)
    res.status(501).send('stream via chat for now');
  });
});
