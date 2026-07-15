from flask import Flask, request, jsonify
from flask_cors import CORS  # نضيف هذه المكتبة لحل CORS نهائياً
from openai import OpenAI
import json

app = Flask(__name__)
CORS(app)  # يسمح لأي تطبيق Flutter بالاتصال بهذا الخادم دون مشاكل

# تعريف النماذج والمفاتيح الخاصة بها (ضع مفاتيحك الحقيقية هنا)
MODELS_CONFIG = {
    "deepseek": {
        "api_key": "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",
        "model_name": "deepseek-ai/deepseek-v4-pro",
        "max_tokens": 1024,
        "temperature": 1.0,
        "extra_body": {"chat_template_kwargs": {"thinking": False}}
    },
    "gemma": {
        "api_key": "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",
        "model_name": "google/gemma-4-31b-it",
        "max_tokens": 1024,
        "temperature": 1.0,
        "extra_body": {"chat_template_kwargs": {"enable_thinking": False}}
    },
    "nemotron": {
        "api_key": "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",
        "model_name": "nvidia/nemotron-3-nano-omni-30b-a3b-reasoning",
        "max_tokens": 2048,
        "temperature": 0.6,
        "extra_body": {"chat_template_kwargs": {"enable_thinking": False}, "reasoning_budget": 16384}
    }
}

SYSTEM_PROMPT = """You are an expert AI Car Diagnostic Assistant for the mobile application "Lakhsly" (لخصلي). 
Your primary role is to assist users in diagnosing car problems and determining if their issue can be fixed on-site based ONLY on the supported car brands and the specific allowed maintenance services provided below. 
Respond ONLY in friendly Egyptian Arabic. Keep responses concise and direct.

SUPPORTED CAR BRANDS: Hyundai, Kia, Toyota, Nissan, Chevrolet, Mitsubishi, Honda, Mazda, Suzuki, Renault, Peugeot, Fiat, Volkswagen, Skoda, Opel, MG, Chery, BYD, Geely, JAC, GAC, Jetour, BMW, Mercedes-Benz, Audi, Lexus, Infiniti, Volvo, MINI, Land Rover, Jaguar, Porsche, Alfa Romeo.

ALLOWED ON-SITE SERVICES: Changing brake pads, changing brake discs, changing brake fluid, bleeding the brake system, changing engine oil/filter, changing air/fuel/AC filters, changing spark plugs/coils/injectors, cleaning/changing throttle body, changing serpentine belt/tensioner/pulleys, fixing minor water/oil/fuel leaks, changing gaskets (valve cover, oil pan), changing transmission/power fluid, securing exhaust/rubber hangers."""

@app.route('/api/chat', methods=['POST'])
def chat():
    try:
        data = request.json
        model_key = data.get('model', 'deepseek')  # استلام النموذج من Flutter
        user_messages = data.get('messages', [])  # نستقبل قائمة الرسائل مباشرة بدلاً من صيغة Gemini

        # جلب إعدادات النموذج المطلوب
        config = MODELS_CONFIG.get(model_key)
        if not config:
            return jsonify({"error": "نموذج غير معروف"}), 400

        # تهيئة عميل OpenAI الخاص بهذا النموذج
        client = OpenAI(
            base_url="https://integrate.api.nvidia.com/v1",
            api_key=config["api_key"]
        )

        # بناء قائمة الرسائل (System + تاريخ المحادثة)
        messages = [{"role": "system", "content": SYSTEM_PROMPT}]
        messages.extend(user_messages)  # user_messages تأتي بصيغة [{"role":"user","content":"..."}]

        # استدعاء الـ API الخاص بالنموذج
        completion = client.chat.completions.create(
            model=config["model_name"],
            messages=messages,
            temperature=config["temperature"],
            top_p=0.95,
            max_tokens=config["max_tokens"],
            extra_body=config["extra_body"],
            stream=False
        )

        reply_text = completion.choices[0].message.content
        return jsonify({"reply": reply_text})

    except Exception as e:
        print("Error:", e)
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)