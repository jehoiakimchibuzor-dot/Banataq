import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureKeyStore {
  static const _openai = 'openai_api_key';
  static const _gemini = 'gemini_api_key';
  static const _groq = 'groq_api_key';
  static const _openrouter = 'openrouter_api_key';
  final _s = const FlutterSecureStorage();

  Future<String?> readGemini() => _s.read(key: _gemini);
  Future<String?> readGroq() => _s.read(key: _groq);
  Future<String?> readOpenRouter() => _s.read(key: _openrouter);
  Future<String?> readOpenAI() => _s.read(key: _openai);
  Future<void> writeGemini(String v) => _s.write(key: _gemini, value: v);
  Future<void> writeGroq(String v) => _s.write(key: _groq, value: v);
  Future<void> writeOpenRouter(String v) => _s.write(key: _openrouter, value: v);
  Future<void> writeOpenAI(String v) => _s.write(key: _openai, value: v);
  Future<void> delete(String key) => _s.delete(key: key);
}
