class LocalAssistant {
  Future<String> reply(String input) {
    final text = input.toLowerCase();
    if (text.contains('summar')) {
      return Future.value(
        'Paste the note you want summarized. I will turn it into clear bullet points, key definitions, and likely exam questions.',
      );
    }
    if (text.contains('exam') ||
        text.contains('question') ||
        text.contains('assignment')) {
      return Future.value(
        'Send the exact question. I will explain the meaning, show the steps, and help you build an answer without making it confusing.',
      );
    }
    if (text.contains('caption') ||
        text.contains('post') ||
        text.contains('announce')) {
      return Future.value(
        'Tell me what you are announcing, who should see it, and the tone you want. I can make it short for WhatsApp, clean for Instagram, or formal for LinkedIn.',
      );
    }
    if (text.contains('business') || text.contains('sell')) {
      return Future.value(
        'Tell me the product, price, location, and why people should trust it. I will write a clean business description and customer-facing pitch.',
      );
    }
    if (text.contains('hausa')) {
      return Future.value(
        'Hausa mode is planned for the next version. For now, I can prepare the app structure so Hausa and English can sit side by side cleanly.',
      );
    }
    return Future.value(
      'I can help with studying, writing, business ideas, summaries, explanations, and planning. Give me the task and I will structure the answer clearly.',
    );
  }
}
