// lib/services/chat_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  // عنوان الخادم الوسيط (غيّر localhost إلى IP جهازك إذا كنت تشغّل على هاتف حقيقي)
  ///static const String baseProxyUrl = "http://127.0.0.1:5000/api/chat";
  // static const String baseProxyUrl = "http://127.0.0.1:5000/api/chat";
static String get baseProxyUrl {
  // قمنا بتغيير العنوان الافتراضي هنا ليكون عنوان سيرفر AWS الخاص بك مباشرة
  const String apiUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://16.171.100.46:5000');
  return '$apiUrl/api/chat';
}
  /// إرسال رسالة المستخدم والحصول على رد النموذج المختار
  /// [model] : اسم النموذج (deepseek, gemma, nemotron)
  /// [userMessage] : نص رسالة المستخدم الحالية
  /// [conversationHistory] : تاريخ المحادثة السابقة كقائمة من الخرائط [{"role":"user"/"assistant", "content":"..."}]
  static Future<String> sendMessage({
    required String model,
    required String userMessage,
    required List<Map<String, String>> conversationHistory,
  }) async {
    // بناء الـ Payload كما يطلبه الخادم الوسيط
    final payload = {
      "model": model,
      "messages": [
        ...conversationHistory,
        {"role": "user", "content": userMessage}
      ]
    };

    try {
      final response = await http.post(
        Uri.parse(baseProxyUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('reply')) {
          return data['reply'] as String;
        } else {
          throw Exception("الخادم لم يعد برد صحيح");
        }
      } else {
        // محاولة قراءة رسالة الخطأ من الخادم
        String errorMsg = "خطأ غير معروف";
        try {
          final errorData = jsonDecode(response.body);
          errorMsg = errorData['error'] ?? "خطأ في الخادم";
        } catch (_) {}
        throw Exception("فشل الطلب: $errorMsg (كود ${response.statusCode})");
      }
    } catch (e) {
      throw Exception("فشل الاتصال بالخادم الوسيط: $e");
    }
  }
}