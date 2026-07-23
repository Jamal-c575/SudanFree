const fs = require('fs');

// Simple parse of .env file
const envPath = '.env';
if (fs.existsSync(envPath)) {
    const envFile = fs.readFileSync(envPath, 'utf8');
    envFile.split('\n').forEach(line => {
        const parts = line.split('=');
        if (parts.length >= 2) {
            const key = parts[0].trim();
            const value = parts.slice(1).join('=').trim();
            if (key && !key.startsWith('#')) {
                process.env[key] = value;
            }
        }
    });
}

const groqApiKey = process.env.GROQ_API_KEY;

const tools = [
  {
    type: "function",
    function: {
      name: "searchFreelancers",
      description: "البحث عن حرفيين ومقدمي خدمات (مثل مبرمج، سباك، نجار، صيانة هواتف)",
      parameters: {
        type: "object",
        properties: {
          query: {
            type: "string",
            description: "كلمة البحث، مثلاً 'مبرمج', 'سباكة', 'صيانة هواتف'"
          }
        },
        required: ["query"]
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
          query: {
            type: "string",
            description: "اسم أو تخصص المتجر"
          }
        },
        required: ["query"]
      }
    }
  },
  {
    type: "function",
    function: {
      name: "searchPosts",
      description: "البحث عن منتجات، سلع معروضة، أو ملابس",
      parameters: {
        type: "object",
        properties: {
          query: {
            type: "string",
            description: "اسم المنتج (مثلاً: ملابس، هاتف)"
          }
        },
        required: ["query"]
      }
    }
  },
  {
    type: "function",
    function: {
      name: "estimateServicePrice",
      description: "تقدير سعر خدمة مهنية بناءً على السوق",
      parameters: {
        type: "object",
        properties: {
          serviceName: {
            type: "string",
            description: "اسم الخدمة (مثال: دهان، برمجة موقع)"
          }
        },
        required: ["serviceName"]
      }
    }
  }
];

async function testQuery(prompt) {
    const messages = [
        { role: "system", content: "أنت مساعد ذكي لتطبيق SudanFree، التطبيق مخصص للعمل الحر والمتاجر في السودان. مهمتك فهم طلب المستخدم واختيار الأداة المناسبة إذا كان يبحث عن حرفي أو متجر أو منتج أو يسأل عن سعر." },
        { role: "user", content: prompt }
    ];

    const payload = {
        model: "llama-3.3-70b-versatile",
        messages: messages,
        tools: tools,
        tool_choice: "auto"
    };

    const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${groqApiKey}`,
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload)
    });

    const data = await response.json();
    const choice = data.choices[0];
    
    console.log(`\n🔹 Query: "${prompt}"`);
    if (choice.message.tool_calls && choice.message.tool_calls.length > 0) {
        const toolCall = choice.message.tool_calls[0];
        console.log(`✅ Tool Called: ${toolCall.function.name}`);
        console.log(`🎯 Arguments: ${toolCall.function.arguments}`);
    } else {
        console.log(`💬 Text Reply: ${choice.message.content}`);
    }
}

async function runTests() {
    await testQuery("أبحث عن سباك شاطر يصلح لي المواسير");
    await testQuery("بكم سعر دهان البيت تقريبا؟");
    await testQuery("عايز اشتري ملابس شتوية");
    await testQuery("وين ألقى بقالة قريبة مني؟");
    await testQuery("مرحبا، كيف حالك؟");
}

runTests();
