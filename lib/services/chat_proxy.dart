import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_keys.dart';

/// Thin proxy — when AppKeys.proxyUrl is set, all chat goes through
/// Functions so keys live in Secret Manager. Otherwise falls back to direct
/// provider (BYOK via SecureKeyStore + --dart-define for dev).
class ChatProxy {
  final String base = AppKeys.proxyUrl;
  bool get enabled => AppKeys.useProxy;

  Future<Map<String,String>> _authHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {'Content-Type': 'application/json'};
    try {
      final token = await user.getIdToken();
      if (token != null && token.isNotEmpty) {
        return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
      }
    } catch (_) {}
    return {'Content-Type': 'application/json'};
  }

  Future<String> proxyGenerate({required String prompt, required String model, List<Map<String,String>>? history}) async {
    final headers = await _authHeaders();
    final res = await http.post(Uri.parse('$base/chat'), headers: headers, body: jsonEncode({'prompt':prompt,'model':model,'history':history})).timeout(const Duration(seconds: 60));
    if (res.statusCode != 200) throw Exception('Proxy ${res.statusCode}: ${res.body}');
    return (jsonDecode(res.body) as Map)['text'] as String? ?? '';
  }
  Stream<String> proxyStream({required String prompt, required String model, List<Map<String,String>>? history}) async* {
    final headers = await _authHeaders();
    final req = http.Request('POST', Uri.parse('$base/chat/stream'))..headers.addAll(headers)..body=jsonEncode({'prompt':prompt,'model':model,'history':history});
    final res = await req.send().timeout(const Duration(seconds: 60));
    if (res.statusCode != 200) throw Exception('Proxy stream ${res.statusCode}');
    await for (final chunk in res.stream.transform(const Utf8Decoder()).transform(const LineSplitter())) {
      if (chunk.startsWith('data: ')) yield chunk.substring(6);
    }
  }
}
