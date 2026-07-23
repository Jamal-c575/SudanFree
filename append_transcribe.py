helpers = """
exports.transcribeAudio = onCall({ region: 'us-central1' }, async (request) => {
    const { audioBase64, mimeType } = request.data;
    if (!audioBase64) {
        throw new HttpsError('invalid-argument', 'audioBase64 is required.');
    }

    const groqApiKey = process.env.GROQ_API_KEY;
    if (!groqApiKey) {
        throw new HttpsError('internal', 'GROQ_API_KEY is not configured.');
    }

    try {
        const fetch = require('node-fetch');
        const FormData = require('form-data');
        const buffer = Buffer.from(audioBase64, 'base64');
        
        const formData = new FormData();
        formData.append('file', buffer, { filename: 'audio.m4a', contentType: mimeType || 'audio/m4a' });
        formData.append('model', 'whisper-large-v3');
        formData.append('prompt', 'This is an Arabic request for a freelance service. Please transcribe it clearly.');

        const response = await fetch('https://api.groq.com/openai/v1/audio/transcriptions', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${groqApiKey}`,
                ...formData.getHeaders()
            },
            body: formData,
        });

        if (!response.ok) {
            console.error('Groq audio error:', await response.text());
            throw new HttpsError('internal', 'Failed to transcribe audio');
        }

        const data = await response.json();
        return { text: data.text || '' };
    } catch (e) {
        console.error(e);
        throw new HttpsError('internal', 'Error processing audio: ' + e.message);
    }
});
"""

with open('functions/src/ai.js', 'a') as f:
    f.write("\n" + helpers)
