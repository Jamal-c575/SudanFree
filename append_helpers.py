import os

helpers = """
exports.ai_generatePageGuide = onCall({ region: 'us-central1' }, async (request) => {
    const { pageName, userName, pageContext } = request.data;
    if (!pageName || !userName || !pageContext) {
        throw new HttpsError('invalid-argument', 'pageName, userName, and pageContext are required.');
    }

    const groqApiKey = process.env.GROQ_API_KEY;
    if (!groqApiKey) {
        throw new HttpsError('internal', 'GROQ_API_KEY is not configured.');
    }

    const systemPrompt = `أنت "Home" — المساعد الذكي لتطبيق سودان فري.
اكتب رسالة ترحيبية قصيرة جداً (سطر واحد بالكثير 120 حرف) للمستخدم لما يدخل الصفحة.

قواعد صارمة:
١. ابني رسالتك فقط على وصف الصفحة اللي هيجي ليك — ما تخترع أي معلومة.
٢. نادي المستخدم بإسمه في البداية.
٣. اشرح فايدة الصفحة في جملة واحدة ذكية وودودة.`;

    const userPrompt = `اسم المستخدم: ${userName}\\nاسم الصفحة: ${pageName}\\nوصف ووظيفة الصفحة: ${pageContext}`;

    try {
        let response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${groqApiKey}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                model: 'llama-3.3-70b-versatile',
                messages: [
                    { role: 'system', content: systemPrompt },
                    { role: 'user', content: userPrompt }
                ],
                temperature: 0.7,
                max_tokens: 150,
            }),
        });
        
        if (!response.ok) {
            throw new HttpsError('internal', 'Failed to generate guide');
        }
        
        const data = await response.json();
        const content = data.choices[0].message.content || '';
        return { guide: content };
    } catch (e) {
        throw new HttpsError('internal', 'Error: ' + e.message);
    }
});

exports.ai_smartFillRequest = onCall({ region: 'us-central1' }, async (request) => {
    const { text } = request.data;
    const groqApiKey = process.env.GROQ_API_KEY;
    if (!groqApiKey) throw new HttpsError('internal', 'GROQ_API_KEY missing.');

    const prompt = `أنت مساعد ذكي. قم بتحسين وصياغة النص التالي ليكون طلباً احترافياً لخدمة أو وظيفة باللغة العربية.\\nالنص: ${text}`;
    
    try {
        let response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${groqApiKey}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                model: 'llama-3.3-70b-versatile',
                messages: [{ role: 'user', content: prompt }],
                temperature: 0.7,
            }),
        });
        const data = await response.json();
        return { result: data.choices[0].message.content || text };
    } catch (e) {
        return { result: text };
    }
});

exports.ai_enhanceText = onCall({ region: 'us-central1' }, async (request) => {
    const { text } = request.data;
    const groqApiKey = process.env.GROQ_API_KEY;
    if (!groqApiKey) throw new HttpsError('internal', 'GROQ_API_KEY missing.');

    const prompt = `حسن النص التالي باللغة العربية مع إصلاح الأخطاء الإملائية وجعله احترافياً وواضحاً (أعد النص فقط بدون مقدمات):\\n${text}`;
    
    try {
        let response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${groqApiKey}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                model: 'llama-3.3-70b-versatile',
                messages: [{ role: 'user', content: prompt }],
                temperature: 0.7,
            }),
        });
        const data = await response.json();
        return { enhancedText: data.choices[0].message.content || text };
    } catch (e) {
        return { enhancedText: text };
    }
});
"""

with open('functions/src/ai.js', 'r') as f:
    content = f.read()

# Remove the dummy functions from the end
content = content.split('// Keep original helpers')[0]

with open('functions/src/ai.js', 'w') as f:
    f.write(content + "\n// ─────────────────────────────────────────────────────────────────────────────\n// Original Helpers\n// ─────────────────────────────────────────────────────────────────────────────\n" + helpers)

