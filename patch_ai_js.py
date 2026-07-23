import re

with open('functions/src/ai.js', 'r') as f:
    content = f.read()

# I will replace the buildSystemPrompt and the tools array.
# First, let's find the start of buildSystemPrompt and end of tools array.

# We will completely replace from `function buildSystemPrompt` down to the end of `const tools = [...]`

new_system_prompts = """
// ─────────────────────────────────────────────────────────────────────────────
// SYSTEM PROMPT — Modular Architecture
// ─────────────────────────────────────────────────────────────────────────────
function buildCorePrompt(name, jobTitle, role, isFreelancer) {
  return `أنت "Home" — المساعد الذكي لتطبيق سودان فري (SudanFree).
تحذير: أنت مساعد افتراضي ذكي، لستَ إنساناً ولا تنتحل شخصية المؤسس جمال أحمد.

═══ معلومات المستخدم الحالي ═══
- الاسم: ${name}
- المهنة / التخصص: ${jobTitle || 'غير محدد'}
- نوع الحساب: ${role || 'غير محدد'}
قاعدة: نادِ المستخدم باسمه "${name}" في بداية ردك دائماً بأسلوب سوداني دافئ.
${isFreelancer
  ? '→ هذا المستخدم حرفي / صاحب متجر. ساعده في تطوير شغله، إيجاد عملاء، والتواصل مع فرق العمل.'
  : '→ هذا المستخدم زبون. ساعده في إيجاد الخدمة المناسبة، وقارن الخيارات، وأرشده لكيفية التواصل.'}

═══ معلومات المؤسسة (أجب فقط إذا سُئلت) ═══
- المؤسس: جمال أحمد إبراهيم — رئيس تنفيذي ومطور رئيسي.
- المؤسسة: Jhome — أول مشاريعها تطبيق SudanFree.
- الموقع: www.sudanfree.com
- الهدف: ربط الزبائن بالحرفيين ومقدمي الخدمات في السودان.

═══ الموضوعات المسموح بها ═══
١. البحث عن حرفيين، متاجر، مجموعات، وظائف، طلبات خدمة.
٢. تفاصيل ملفات الحرفيين: اسم، تقييم، مهارات، موقع، حالة.
٣. نصائح سوق العمل الحر في السودان.
٤. كيفية استخدام ميزات التطبيق.
٥. معلومات Jhome والمؤسس.

═══ اللغة والأسلوب ═══
- العربية: عامية سودانية دافئة — كلمات مثل (تقدر، شنو، الزول، ما عليك، داير، قدام، بكتب).
- الإنجليزية: احترافية ومبسطة.
- ممنوع الفصحى الثقيلة أو الأسلوب الرسمي البارد.
- ممنوع: حروف صينية أو يابانية أو روسية.`;
}

function buildMemoryPrompt(messages) {
  // Extract SYSTEM_MEMORY from history
  const memories = messages
    .filter(m => m.role === 'assistant' && typeof m.content === 'string' && m.content.includes('SYSTEM_MEMORY'))
    .map(m => {
        try {
            const parsed = JSON.parse(m.content);
            return parsed.SYSTEM_MEMORY;
        } catch(e) { return null; }
    })
    .filter(Boolean);

  if (memories.length === 0) return '';
  
  return `\\n═══ ذاكرة النظام المهيكلة (لا تذكرها للمستخدم مباشرة) ═══\\n` + 
    memories.map(m => JSON.stringify(m, null, 2)).join('\\n');
}

function buildContextPrompt(convState) {
  const activeEntity = convState.activeEntity ? `\\n- الكيان النشط حالياً (ID): ${convState.activeEntity} (نوع: ${convState.activeCategory || 'غير محدد'})` : '';
  const searchState = convState.activeSearch ? `\\n- آخر عملية بحث تمت: ${JSON.stringify(convState.activeSearch)}` : '';
  const intentState = convState.currentIntent ? `\\n- النية الحالية: ${convState.currentIntent}` : '';

  if (!activeEntity && !searchState && !intentState) return '';

  return `\\n═══ حالة المحادثة الحالية (Conversation State) ═══${intentState}${activeEntity}${searchState}`;
}

function buildToolRules() {
  return `\\n═══ قواعد استخدام الأدوات (Reasoning Layer) ═══
الآن جميع أدوات البحث والاستفسار هي أدوات برمجية حقيقية (Native Tools).
لا تستخدم الصيغة النصية [TOOL: name] بعد الآن. استخدم استدعاء الدوال الحقيقي (Tool Call).

قاعدة هامة جداً: كل أداة تحتوي على معطيات إجبارية:
1. thought_process: اشرح تفكيرك الداخلي ولماذا اخترت هذه الأداة بناءً على طلب المستخدم. (هذا لن يراه المستخدم).
2. intent: حدد نية المستخدم (مثلاً: search_freelancer, get_user_details, clarify_request).

إذا كان طلب المستخدم غامضاً أو مختصراً جداً ولا يمكنك تحديد ما يريد بدقة، يجب عليك استدعاء أداة "clarifyUserIntent".`;
}

function buildSystemPrompt(userContext = {}, messages = []) {
  const name     = userContext.name     || 'صاحبي';
  const role     = userContext.role     || '';
  const jobTitle = userContext.jobTitle || '';
  const isFreelancer = /freelancer|shop|privateservice|techservice/i.test(role);
  const convState = userContext.conversationState || {};

  const core = buildCorePrompt(name, jobTitle, role, isFreelancer);
  const memory = buildMemoryPrompt(messages);
  const context = buildContextPrompt(convState);
  const toolsRules = buildToolRules();

  return {
    role: 'system',
    content: core + memory + context + toolsRules
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Tool schemas
// ─────────────────────────────────────────────────────────────────────────────
// Define the tools using JSON schema natively supported by OpenAI/Groq
const tools = [
  {
    type: "function",
    function: {
      name: "searchFreelancers",
      description: "البحث عن حرفيين ومقدمي خدمات (مثل مبرمج، سباك، نجار، صيانة هواتف)",
      parameters: {
        type: "object",
        properties: {
          thought_process: { type: "string", description: "اشرح لماذا اخترت هذه الأداة وكيف ستلبي طلب المستخدم." },
          intent: { type: "string", description: "نية المستخدم الحالية (مثلاً: search_freelancer)" },
          query: { type: "string", description: "كلمة البحث، مثلاً 'مبرمج', 'سباكة', 'صيانة هواتف'" }
        },
        required: ["thought_process", "intent", "query"]
      }
    }
  },
  {
    type: "function",
    function: {
      name: "searchShops",
      description: "البحث عن متاجر أو محلات",
      parameters: {
        type: "object",
        properties: {
          thought_process: { type: "string", description: "اشرح لماذا اخترت هذه الأداة." },
          intent: { type: "string", description: "نية المستخدم الحالية." },
          query: { type: "string", description: "كلمة البحث، مثلاً 'ملابس', 'بقالة', 'أدوات منزلية'" }
        },
        required: ["thought_process", "intent", "query"]
      }
    }
  },
  {
    type: "function",
    function: {
      name: "searchPosts",
      description: "البحث عن منتجات وسلع أو منشورات",
      parameters: {
        type: "object",
        properties: {
          thought_process: { type: "string", description: "اشرح لماذا اخترت هذه الأداة." },
          intent: { type: "string", description: "نية المستخدم الحالية." },
          query: { type: "string", description: "كلمة البحث، مثلاً 'أثاث', 'لابتوب', 'سيارات'" }
        },
        required: ["thought_process", "intent", "query"]
      }
    }
  },
  {
    type: "function",
    function: {
      name: "searchJobs",
      description: "البحث عن وظائف مفتوحة",
      parameters: {
        type: "object",
        properties: {
          thought_process: { type: "string", description: "اشرح لماذا اخترت هذه الأداة." },
          intent: { type: "string", description: "نية المستخدم الحالية." },
          query: { type: "string", description: "المسمى الوظيفي، مثلاً 'محاسب', 'مهندس', 'كاشير'" }
        },
        required: ["thought_process", "intent", "query"]
      }
    }
  },
  {
    type: "function",
    function: {
      name: "getTopRated",
      description: "الحصول على أعلى الحرفيين تقييماً في مجال معين",
      parameters: {
        type: "object",
        properties: {
          thought_process: { type: "string", description: "اشرح لماذا اخترت هذه الأداة." },
          intent: { type: "string", description: "نية المستخدم الحالية." },
          category: { type: "string", description: "اسم المجال، مثلاً 'نجارة', 'برمجة', 'تصميم'" }
        },
        required: ["thought_process", "intent", "category"]
      }
    }
  },
  {
    type: "function",
    function: {
      name: "getUserProfile",
      description: "جلب تفاصيل ملف مستخدم (حرفي أو عادي) باستخدام الـ ID",
      parameters: {
        type: "object",
        properties: {
          thought_process: { type: "string", description: "اشرح لماذا اخترت هذه الأداة." },
          intent: { type: "string", description: "نية المستخدم الحالية." },
          userId: { type: "string", description: "معرف المستخدم (UID)" }
        },
        required: ["thought_process", "intent", "userId"]
      }
    }
  },
  {
    type: "function",
    function: {
      name: "searchSquads",
      description: "البحث عن مجموعات خدمية وفرق عمل",
      parameters: {
        type: "object",
        properties: {
          thought_process: { type: "string", description: "اشرح لماذا اخترت هذه الأداة." },
          intent: { type: "string", description: "نية المستخدم الحالية." },
          query: { type: "string", description: "كلمة البحث" }
        },
        required: ["thought_process", "intent", "query"]
      }
    }
  },
  {
    type: "function",
    function: {
      name: "searchRequests",
      description: "البحث عن طلبات خدمة نشطة (طلبات عمل)",
      parameters: {
        type: "object",
        properties: {
          thought_process: { type: "string", description: "اشرح لماذا اخترت هذه الأداة." },
          intent: { type: "string", description: "نية المستخدم الحالية." },
          query: { type: "string", description: "نوع الطلب، مثلاً 'نظافة', 'نقل', 'صيانة'" }
        },
        required: ["thought_process", "intent", "query"]
      }
    }
  },
  {
    type: "function",
    function: {
      name: "estimateServicePrice",
      description: "تقدير سعر خدمة معينة باستخدام الذكاء الاصطناعي",
      parameters: {
        type: "object",
        properties: {
          thought_process: { type: "string", description: "اشرح لماذا اخترت هذه الأداة." },
          intent: { type: "string", description: "نية المستخدم الحالية." },
          serviceName: { type: "string", description: "اسم الخدمة أو تفاصيلها" }
        },
        required: ["thought_process", "intent", "serviceName"]
      }
    }
  },
  {
    type: "function",
    function: {
      name: "clarifyUserIntent",
      description: "استخدم هذه الأداة إذا كان طلب المستخدم غامضاً أو غير واضح لطلب توضيح",
      parameters: {
        type: "object",
        properties: {
          thought_process: { type: "string", description: "اشرح لماذا تطلب توضيحاً وما هو الغموض في الطلب." },
          intent: { type: "string", description: "النية المفترضة للمستخدم (مثلاً: clarify_ambiguity)" },
          question: { type: "string", description: "السؤال التوضيحي بأسلوب سوداني دافئ، مثلاً 'تقصد شنو تحديداً يا صاحبي؟'" },
          options: {
            type: "array",
            items: { type: "string" },
            description: "قائمة بالخيارات المقترحة للمستخدم، مثلاً ['حرفي أو مقاول', 'متجر أو منتج', 'طلب خدمة']"
          }
        },
        required: ["thought_process", "intent", "question", "options"]
      }
    }
  }
];
"""

# Find start of buildSystemPrompt
start_idx = content.find('function buildSystemPrompt')
if start_idx == -1:
    print("Could not find buildSystemPrompt")
    exit(1)

# Find end of tools array. It's marked by "];" followed by something else.
end_tools_idx = content.find('];', content.find('const tools = ['))
if end_tools_idx == -1:
    print("Could not find end of tools array")
    exit(1)

end_tools_idx += 2 # include "];"

# We also need to update the `ai_chatWithHome` call where buildSystemPrompt is called.
# It currently calls `buildSystemPrompt(userContext);` -> needs to be `buildSystemPrompt(userContext, request.data.messages);`

part1 = content[:start_idx]
part3 = content[end_tools_idx:]

# Let's check part 3 for `buildSystemPrompt(userContext)` and `// ─── طلب توضيح [CLARIFY`

part3 = part3.replace('const systemPromptObj = buildSystemPrompt(userContext);', 
                      'const systemPromptObj = buildSystemPrompt(userContext, request.data.messages || []);')


# We also need to rewrite the choice processing logic in `ai_chatWithHome` for `clarifyUserIntent` tool.

choice_logic_old = """        // ─── أداة أصلية (native tool call) ───
        if (choice.message.tool_calls && choice.message.tool_calls.length > 0) {
            const toolCall = choice.message.tool_calls[0];
            let args = {};
            try { args = JSON.parse(toolCall.function.arguments); } catch (_) {}
            return {
                type:      'tool_call',
                toolName:  toolCall.function.name,
                arguments: args,
            };
        }

        const content = choice.message.content || '';

        // ─── طلب توضيح [CLARIFY: سؤال | خيار1 | خيار2 ...] ───
        const clarifyMatch = content.match(/\\[CLARIFY:\\s*([^\\|]+)\\|([^\\]]+)\\]/);
        if (clarifyMatch) {
            const question = clarifyMatch[1].trim();
            const options  = clarifyMatch[2].split('|').map(s => s.trim()).filter(Boolean);
            // النص قبل [CLARIFY] إن وُجد
            const intro = content.replace(clarifyMatch[0], '').trim();
            return { type: 'clarify', question, options, intro };
        }

        // ─── أداة نصية [TOOL: name | params] ───
        const toolTextMatch = content.match(/\\[TOOL:\\s*([^\\|]+)\\|([^\\]]*)\\]/);
        if (toolTextMatch) {
            return {
                type:      'tool_call',
                toolName:  toolTextMatch[1].trim(),
                arguments: { query: toolTextMatch[2].trim() },
                _textFormat: true,   // أُرسل كنص وليس native tool call
            };
        }

        // ─── رد نصي عادي ───
        return { type: 'text', content };"""

choice_logic_new = """        // ─── أداة أصلية (native tool call) ───
        if (choice.message.tool_calls && choice.message.tool_calls.length > 0) {
            const toolCall = choice.message.tool_calls[0];
            let args = {};
            try { args = JSON.parse(toolCall.function.arguments); } catch (_) {}
            
            // Check if it's the clarify tool
            if (toolCall.function.name === 'clarifyUserIntent') {
                return { 
                    type: 'clarify', 
                    question: args.question || 'تقصد شنو تحديداً؟', 
                    options: args.options || [], 
                    intro: args.thought_process || ''
                };
            }

            return {
                type:      'tool_call',
                toolName:  toolCall.function.name,
                arguments: args,
            };
        }

        const content = choice.message.content || '';

        // ─── Fallback logic just in case the model hallucinates old formats ───
        const clarifyMatch = content.match(/\\[CLARIFY:\\s*([^\\|]+)\\|([^\\]]+)\\]/);
        if (clarifyMatch) {
            const question = clarifyMatch[1].trim();
            const options  = clarifyMatch[2].split('|').map(s => s.trim()).filter(Boolean);
            const intro = content.replace(clarifyMatch[0], '').trim();
            return { type: 'clarify', question, options, intro };
        }

        const toolTextMatch = content.match(/\\[TOOL:\\s*([^\\|]+)\\|([^\\]]*)\\]/);
        if (toolTextMatch) {
            return {
                type:      'tool_call',
                toolName:  toolTextMatch[1].trim(),
                arguments: { query: toolTextMatch[2].trim(), intent: "fallback_text_tool" }
            };
        }

        // ─── رد نصي عادي ───
        return { type: 'text', content };"""

part3 = part3.replace(choice_logic_old, choice_logic_new)

# filter out SYSTEM_MEMORY from user messages inside ai_chatWithHome
# Just to be safe, filter them out before passing to Groq, so Groq only sees them in the system prompt.
filter_system_mem_old = "const filteredMessages = finalMessages.map(m => ({"
filter_system_mem_new = """const filteredMessages = finalMessages
            .filter(m => {
                if (m.role === 'assistant' && typeof m.content === 'string' && m.content.includes('SYSTEM_MEMORY')) {
                    return false; // Skip system memory from regular conversation flow
                }
                return true;
            })
            .map(m => ({"""

part3 = part3.replace(filter_system_mem_old, filter_system_mem_new)

with open('functions/src/ai.js', 'w') as f:
    f.write(part1 + new_system_prompts + part3)

print("Patched functions/src/ai.js")
