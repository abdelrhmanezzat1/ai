class Message {
  final String text;
  final bool isUser; // true للمستخدم، false للبوت

  Message({required this.text, required this.isUser});
}