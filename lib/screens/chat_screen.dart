import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/message.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Message> _messages = [];
  final TextEditingController _controller = TextEditingController();
  String _selectedModel = 'deepseek'; // النموذج الافتراضي
  bool _isLoading = false;

  // تاريخ المحادثة بصيغة {role, content} لتمريرها للـ API
  List<Map<String, String>> _conversationHistory = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لخصلي - تشخيص السيارات'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          DropdownButton<String>(
            value: _selectedModel,
            dropdownColor: Colors.white,
            style: const TextStyle(color: Colors.black),
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            items: const [
              DropdownMenuItem(value: 'deepseek', child: Text('DeepSeek V4')),
              DropdownMenuItem(value: 'gemma', child: Text('Gemma 4-31B')),
              DropdownMenuItem(value: 'nemotron', child: Text('Nemotron 3 Nano')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedModel = value;
                  // مسح المحادثة عند تغيير النموذج (اختياري)
                  _messages.clear();
                  _conversationHistory.clear();
                });
              }
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'مرحباً! كيف يمكنني مساعدتك في سيارتك؟',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[_messages.length - 1 - index];
                      return _buildMessageItem(msg);
                    },
                  ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'اكتب مشكلتك...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Colors.blue,
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Message msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: msg.isUser ? Colors.blue.shade100 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          msg.text,
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.right,
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // إضافة رسالة المستخدم محلياً
    setState(() {
      _messages.add(Message(text: text, isUser: true));
      _conversationHistory.add({"role": "user", "content": text});
      _controller.clear();
      _isLoading = true;
    });

    try {
      // إرسال الطلب
      final reply = await ChatService.sendMessage(
        model: _selectedModel,
        userMessage: text,
        conversationHistory: _conversationHistory,
      );

      // إضافة رد البوت
      setState(() {
        _messages.add(Message(text: reply, isUser: false));
        _conversationHistory.add({"role": "assistant", "content": reply});
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(Message(text: 'حدث خطأ: $e', isUser: false));
        _isLoading = false;
      });
    }
  }
}