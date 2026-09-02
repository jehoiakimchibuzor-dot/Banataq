abstract class AiProvider {
  Future<String> generateResponse(
    String prompt, {
    String? persona,
    String? displayName,
    List<Map<String, String>>? history,
  });
  Stream<String> generateResponseStream(
    String prompt, {
    String? persona,
    String? displayName,
    List<Map<String, String>>? history,
  });
  String get name;
}
