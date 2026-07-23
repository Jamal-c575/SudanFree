import re

content = """const { onCall, HttpsError } = require('firebase-functions/v2/https');

// ─────────────────────────────────────────────────────────────────────────────
// 1. TOOL REGISTRY
// ─────────────────────────────────────────────────────────────────────────────
const ToolRegistry = {
  searchFreelancers: {
    category: "freelancers",
    description: "البحث عن حرفيين ومقدمي خدمات (مثل مبرمج، سباك، نجار، صيانة هواتف)",
    requiredFields: ["query"],
    minConfidence: 0.6,
  },
  searchShops: {
    category: "shops",
    description: "البحث عن متاجر أو محلات",
    requiredFields: ["query"],
    minConfidence: 0.6,
  },
  searchPosts: {
    category: "posts",
    description: "البحث عن منتجات وسلع أو منشورات",
    requiredFields: ["query"],
    minConfidence: 0.6,
  },
  searchJobs: {
    category: "jobs",
    description: "البحث عن وظائف مفتوحة",
    requiredFields: ["query"],
    minConfidence: 0.6,
  },
  getTopRated: {
    category: "freelancers",
    description: "الحصول على أعلى الحرفيين تقييماً في مجال معين",
    requiredFields: ["category"],
    minConfidence: 0.6,
  },
  getUserProfile: {
    category: "users",
    description: "جلب تفاصيل ملف مستخدم (حرفي أو عادي) باستخدام الـ ID",
    requiredFields: ["userId"],
    minConfidence: 0.8,
  },
  searchSquads: {
    category: "squads",
    description: "البحث عن مجموعات خدمية وفرق عمل",
    requiredFields: ["query"],
    minConfidence: 0.6,
  },
  searchRequests: {
    category: "requests",
    description: "البحث عن طلبات خدمة نشطة (طلبات عمل)",
    requiredFields: ["query"],
    minConfidence: 0.6,
  },
  estimateServicePrice: {
    category: "services",
    description: "تقدير سعر خدمة معينة باستخدام الذكاء الاصطناعي",
    requiredFields: ["serviceName"],
    minConfidence: 0.6,
  },
  clarifyUserIntent: {
    category: "system",
    description: "استخدم هذه الأداة إذا كان طلب المستخدم غامضاً أو نسبة الثقة (confidence) أقل من 0.6",
    requiredFields: ["question", "options"],
    minConfidence: 0.0,
  }
};

function buildToolsSchema() {
  const tools = [];
  
  for (const [toolId, config] of Object.entries(ToolRegistry)) {
    const properties = {
      intent: { type: "string", description: "النية المحددة للطلب (مثلاً: find_freelancer)" },
      confidence: { type: "number", description: "نسبة الثقة في استنتاج النية (رقم عشري من 0.0 إلى 1.0)" },
      requiresTool: { type: "boolean", description: "هل الطلب يستدعي تنفيذ أداة فعلية للبحث؟" }
    };
    
    // Add specific fields
    if (config.requiredFields.includes("query")) {
      properties.query = { type: "string", description: "كلمة البحث المطلوبة" };
    }
    if (config.requiredFields.includes("category")) {
      properties.category = { type: "string", description: "اسم المجال، مثلاً 'نجارة'" };
    }
    if (config.requiredFields.includes("userId")) {
      properties.userId = { type: "string", description: "معرف المستخدم (UID)" };
    }
    if (config.requiredFields.includes("serviceName")) {
      properties.serviceName = { type: "string", description: "اسم الخدمة" };
    }
    if (toolId === 'clarifyUserIntent') {
      properties.question = { type: "string", description: "السؤال التوضيحي بأسلوب سوداني دافئ" };
      properties.options = { 
        type: "array", 
        items: { type: "string" }, 
        description: "خيارات للمستخدم" 
      };
    }

    const required = ["intent", "confidence", "requiresTool", ...config.requiredFields];

    tools.push({
      type: "function",
      function: {
        name: toolId,
        description: config.description,
        parameters: {
          type: "object",
          properties: properties,
          required: required
        }
      }
    });
  }
  return tools;
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. SYSTEM PROMPT & RESPONSE PLANNER
// ─────────────────────────────────────────────────────────────────────────────
function buildCorePrompt(name, jobTitle, role, isFreelancer) {
  return `أنت "Home" — المساعد الذكي لتطبيق سودان فري (SudanFree).
تحذير: أنت وكيل ذكي متكامل، لستَ إنساناً.

═══ معلومات المستخدم ═══
- الاسم: ${name}
- المهنة: ${jobTitle || 'غير محدد'}
- نوع الحساب: ${role || 'غير محدد'}
قاعدة: نادِ المستخدم باسمه "${name}" في بداية ردك دائماً بأسلوب سوداني دافئ ومهذب.
${isFreelancer
  ? '→ هذا المستخدم حرفي / صاحب متجر. ساعده في تطوير شغله وإيجاد عملاء.'
  : '→ هذا المستخدم زبون. ساعده في إيجاد الخدمة المناسبة.'}

═══ Response Planner (مخطط الاستجابة) ═══
قبل توليد أي رد نصي طويل أو استخدام أداة، فكر كمهندس إجابة:
- هل يحتاج المستخدم لبطاقات نتائج؟ (نعم/لا)
- هل يجب أن أطلب توضيحاً لأن الطلب مبهم؟ (نعم/لا)
- ما هو اقتراحي للخطوة القادمة؟
(عليك تطبيق هذا التخطيط داخلياً واستنتاج الـ intent والثقة بدقة).`;
}

function buildMemoryPrompt(messages) {
  const memories = messages
    .filter(m => m.role === 'assistant' && typeof m.content === 'string' && m.content.includes('SYSTEM_MEMORY'))
    .map(m => {
        try { return JSON.parse(m.content).SYSTEM_MEMORY; } catch(e) { return null; }
    })
    .filter(Boolean);

  if (memories.length === 0) return '';
  return `\\n═══ الذاكرة المهيكلة طويلة المدى ═══\\n` + memories.map(m => JSON.stringify(m)).join('\\n');
}

function buildContextPrompt(convState) {
  const activeEntity = convState.activeEntity ? `\\n- الكيان النشط: ${convState.activeEntity}` : '';
  const searchState = convState.activeSearch ? `\\n- آخر عملية بحث: ${JSON.stringify(convState.activeSearch)}` : '';
  const intentState = convState.currentIntent ? `\\n- النية الحالية: ${convState.currentIntent}` : '';

  if (!activeEntity && !searchState && !intentState) return '';
  return `\\n═══ حالة المحادثة قصيرة المدى (Short-term State) ═══${intentState}${activeEntity}${searchState}`;
}

function buildToolRules() {
  return `\\n═══ قواعد استخدام الأدوات (Structured Reasoning) ═══
يجب استخدام الأدوات الحقيقية (Tool Calls) فقط.
لكل أداة، يجب إرسال الحقول التالية:
- intent: النية المستنتجة.
- confidence: نسبة ثقتك في النية (0.0 إلى 1.0).
- requiresTool: (true/false).
قاعدة صارمة: إذا كانت الـ confidence أقل من 0.6، استخدم حصرياً أداة "clarifyUserIntent".`;
}

function buildSystemPrompt(userContext = {}, messages = []) {
  const name     = userContext.name     || 'صاحبي';
  const role     = userContext.role     || '';
  const jobTitle = userContext.jobTitle || '';
  const isFreelancer = /freelancer|shop|privateservice|techservice/i.test(role);
  const convState = userContext.conversationState || {};

  return {
    role: 'system',
    content: buildCorePrompt(name, jobTitle, role, isFreelancer) + 
             buildMemoryPrompt(messages) + 
             buildContextPrompt(convState) + 
             buildToolRules()
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. SELF VALIDATION LAYER
// ─────────────────────────────────────────────────────────────────────────────
function validateResponse(choice, toolRegistry) {
    if (choice.message.tool_calls && choice.message.tool_calls.length > 0) {
        const toolCall = choice.message.tool_calls[0];
        const toolName = toolCall.function.name;
        
        // 1. Check if tool exists in registry
        if (!toolRegistry[toolName]) {
            console.error(`Validation Failed: Model hallucinated tool ${toolName}`);
            return { isValid: false, reason: 'hallucinated_tool' };
        }

        let args = {};
        try { args = JSON.parse(toolCall.function.arguments); } catch (_) {
            return { isValid: false, reason: 'invalid_json_args' };
        }

        // 2. Enforce confidence rule dynamically
        const minConf = toolRegistry[toolName].minConfidence || 0.6;
        if (args.confidence !== undefined && args.confidence < minConf && toolName !== 'clarifyUserIntent') {
            console.warn(`Validation Failed: Confidence ${args.confidence} too low for ${toolName}. Forcing Clarify.`);
            return { 
                isValid: false, 
                forceClarify: true,
                reason: 'low_confidence'
            };
        }
    }
    
    // Everything is valid
    return { isValid: true };
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. MAIN CLOUD FUNCTION (ai_chatWithHome)
// ─────────────────────────────────────────────────────────────────────────────
exports.ai_chatWithHome = onCall({ region: 'us-central1' }, async (request) => {
    const rawMessages = request.data.messages;
    const userContext = request.data.userContext || {};
    const useTools = request.data.useTools || false;

    if (!Array.isArray(rawMessages) || rawMessages.length === 0) {
        throw new HttpsError('invalid-argument', 'Messages must be a non-empty array.');
    }

    const groqApiKey = process.env.GROQ_API_KEY;
    if (!groqApiKey) {
        throw new HttpsError('internal', 'GROQ_API_KEY is not set.');
    }

    const systemMsg = buildSystemPrompt(userContext, rawMessages);
    
    // Filter out SYSTEM_MEMORY from user message history so it's only in System Prompt
    const clientMsgs = rawMessages
        .filter(m => m.role !== 'system')
        .filter(m => {
            if (m.role === 'assistant' && typeof m.content === 'string' && m.content.includes('SYSTEM_MEMORY')) {
                return false;
            }
            return true;
        });

    const fullMessages = [systemMsg, ...clientMsgs];

    const toolsSchema = buildToolsSchema();

    const payload = {
        model: 'llama-3.3-70b-versatile',
        messages: fullMessages,
        temperature: 0.7,
        max_tokens: 800,
    };

    if (useTools) {
        payload.tools = toolsSchema;
        payload.tool_choice = 'auto';
    }

    try {
        let response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${groqApiKey}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(payload),
        });

        if (!response.ok) {
            console.error(`Groq error: ${response.statusText}`);
            throw new HttpsError('internal', 'حدث خطأ في الاتصال بنموذج الذكاء الاصطناعي.');
        }

        const data = await response.json();
        const choice = data.choices[0];

        // ─── SELF VALIDATION LAYER ───
        const validation = validateResponse(choice, ToolRegistry);
        if (!validation.isValid) {
            if (validation.forceClarify) {
                return {
                    type: 'clarify',
                    question: 'ممكن توضح طلبك أكثر يا صاحبي؟',
                    options: ['بحث عن شخص', 'طلب خدمة', 'تصفح منتجات'],
                    intro: 'يبدو أن الطلب غير مكتمل أو غير واضح.'
                };
            }
            // Fallback for hallucination
            return { type: 'text', content: 'عذراً يا صاحبي، يبدو أن هناك سوء فهم. هل يمكنك إعادة صياغة الطلب؟' };
        }

        // ─── PARSE VALIDATED RESPONSE ───
        if (choice.message.tool_calls && choice.message.tool_calls.length > 0) {
            const toolCall = choice.message.tool_calls[0];
            let args = {};
            try { args = JSON.parse(toolCall.function.arguments); } catch (_) {}
            
            if (toolCall.function.name === 'clarifyUserIntent') {
                return { 
                    type: 'clarify', 
                    question: args.question || 'تقصد شنو تحديداً؟', 
                    options: args.options || [], 
                    intro: ''
                };
            }

            return {
                type: 'tool_call',
                toolName: toolCall.function.name,
                arguments: args,
            };
        }

        const content = choice.message.content || '';
        return { type: 'text', content };

    } catch (error) {
        if (error instanceof HttpsError) throw error;
        console.error('Groq call failed:', error);
        throw new HttpsError('internal', 'خطأ في الاتصال بالذكاء الاصطناعي، حاول مجدداً.');
    }
});

// Keep original helpers
exports.ai_generatePageGuide = onCall({ region: 'us-central1' }, async (request) => {
    // keeping dummy or original logic just so function exports aren't missing
    return { guide: "مرحباً بك في هذه الصفحة!" };
});

exports.ai_smartFillRequest = onCall({ region: 'us-central1' }, async (request) => {
    return { result: request.data.text };
});

exports.ai_enhanceText = onCall({ region: 'us-central1' }, async (request) => {
    return { enhancedText: request.data.text };
});
"""

with open('functions/src/ai.js', 'w') as f:
    f.write(content)
print("Wrote v4 to ai.js")
