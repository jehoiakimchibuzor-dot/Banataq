/// Estimates token counts without a full model vocabulary.
///
/// Providers and the context compressor both use this so budget accounting is
/// deterministic and offline.
abstract interface class Tokenizer {
  int countTokens(String text);
}
