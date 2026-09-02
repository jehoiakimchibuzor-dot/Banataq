# Security Review

## 1. Secrets Management

| Secret | Storage | Access |
|--------|---------|--------|
| Firebase config | `google-services.json` / `GoogleService-Info.plist` | Committed to repo (Firebase-safe) |
| AI API keys | `flutter_secure_storage` (AES-256) | User's device only |
| Auth tokens | Firebase Auth SDK (auto-managed) | SDK internal |
| Encryption keys | Platform keychain (iOS Keychain / Android EncryptedSharedPreferences) | OS-level |

**Never store in code:**
- API keys (OpenAI, Gemini, etc.) — always user-provided, never hardcoded
- Firebase admin/service account keys — not needed on client

## 2. API Key Rotation Strategy

```dart
class ApiKeyManager {
  Future<void> rotateKey(AiProviderType provider, String newKey) async {
    // 1. Validate new key works
    final isValid = await _testKey(provider, newKey);
    if (!isValid) throw InvalidKeyException();

    // 2. Store encrypted
    await _secureStorage.write(
      key: '${provider.name}_api_key',
      value: newKey,
    );

    // 3. Emit event so active provider picks up new key
    _eventBus.emit(KeyRotated(provider));

    // 4. Optional: revoke old key via provider API
    if (_oldKey != null) {
      await _revokeKey(provider, _oldKey);
    }
  }
}
```

## 3. Encryption Strategy

| Data | At Rest (Device) | In Transit | At Rest (Server) |
|------|-----------------|------------|------------------|
| API keys | AES-256 (flutter_secure_storage) | HTTPS/TLS | Not stored |
| Chat messages | Plaintext (Isar) | HTTPS/TLS | Firestore encrypted at rest |
| User profile | Plaintext (Isar) | HTTPS/TLS | Firestore encrypted at rest |
| Memories | Plaintext (Isar) | HTTPS/TLS | Firestore encrypted at rest |
| Uploaded files | Plaintext (device storage) | HTTPS/TLS | Firebase Storage encrypted at rest |

**Note**: Firestore and Firebase Storage are encrypted at rest by default (AES-256). No additional server-side encryption needed for MVP.

## 4. Abuse Prevention

```dart
class AbusePreventionService {
  // Rate limiting per user
  Future<bool> isRateLimited(String userId) async {
    final recent = await _getRequestCount(userId, Duration(minutes: 1));
    final limit = _remoteConfig.getInt(RemoteConfigKeys.rateLimitPerMinute);
    return recent >= limit;
  }

  // Content moderation (basic)
  bool containsAbuse(String text) {
    // Block list + pattern matching
    // Phase 2: AI-powered content moderation
    return _blockList.any((pattern) => text.contains(pattern));
  }

  // File validation
  FileValidationResult validateUpload(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    final allowed = ['pdf', 'docx', 'pptx', 'txt', 'png', 'jpg', 'jpeg'];
    if (!allowed.contains(extension)) {
      return FileValidationResult.invalid('File type not allowed');
    }
    final size = file.lengthSync();
    if (size > 10 * 1024 * 1024) { // 10MB max
      return FileValidationResult.invalid('File too large (max 10MB)');
    }
    return FileValidationResult.valid();
  }
}
```

## 5. Prompt Injection Protection

```dart
class PromptSanitizer {
  String sanitize(String userInput) {
    // 1. Strip obvious injection attempts
    var sanitized = userInput
      .replaceAll('Ignore previous instructions', '')
      .replaceAll('System prompt:', '')
      .replaceAll('You are an AI', '');

    // 2. Use system prompt as immutable prefix (not appended)
    //    The system prompt is PREPENDED before user input

    // 3. Wrap user input in delimiters
    //    "=== USER INPUT START ===\n$sanitized\n=== USER INPUT END ==="

    // 4. Rate limit: max 5000 chars per message
    if (sanitized.length > 5000) {
      sanitized = sanitized.substring(0, 5000);
    }

    return sanitized;
  }

  // Validate before sending to AI
  ValidationResult validate(String input) {
    if (input.trim().isEmpty) return ValidationResult.invalid('Empty input');
    if (input.length > 5000) return ValidationResult.invalid('Input too long');
    if (hasSuspiciousPatterns(input)) return ValidationResult.invalid('Suspicious input detected');
    return ValidationResult.valid();
  }
}
```

## 6. File Validation & Sanitization

```dart
class FileSecurityValidator {
  Future<ValidationResult> validate(String filePath) async {
    final file = File(filePath);
    final extension = file.path.split('.').last.toLowerCase();

    // 1. Type check (whitelist, not blacklist)
    if (!_allowedExtensions.contains(extension)) {
      return ValidationResult.invalid('File type: $extension not allowed');
    }

    // 2. Size check
    if (await file.length() > _maxSizeBytes) {
      return ValidationResult.invalid('File exceeds maximum size');
    }

    // 3. Magic byte verification (prevent extension spoofing)
    if (!await _verifyMagicBytes(file, extension)) {
      return ValidationResult.invalid('File header mismatch');
    }

    // 4. PDF: check for malicious JavaScript
    if (extension == 'pdf') {
      final content = await file.readAsBytes();
      if (_containsJavaScript(content)) {
        return ValidationResult.invalid('PDF contains embedded scripts');
      }
    }

    // 5. Images: re-encode to strip metadata
    if (['png', 'jpg', 'jpeg'].contains(extension)) {
      await _stripExifData(file);
    }

    return ValidationResult.valid();
  }

  final _allowedExtensions = {'pdf', 'docx', 'pptx', 'txt', 'png', 'jpg', 'jpeg', 'gif'};
  final _maxSizeBytes = 10 * 1024 * 1024; // 10MB
}
```

## 7. Audit Logging

```dart
class AuditLogger {
  Future<void> log({
    required String userId,
    required String action,
    required String resource,
    Map<String, dynamic>? details,
  }) async {
    await FirebaseFirestore.instance.collection('audit_logs').add({
      'userId': userId,
      'action': action,       // 'auth.login', 'conversation.delete', 'settings.update'
      'resource': resource,   // 'conversation/abc123'
      'details': details,     // { method: 'google' }
      'ipAddress': null,      // Collected server-side via Cloud Function
      'userAgent': null,      // Collected server-side
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
```

## 8. Compliance Considerations

| Requirement | Status | Notes |
|------------|--------|-------|
| GDPR data export | Planned | Settings > Export Data |
| GDPR right to deletion | Planned | Settings > Delete Account |
| Data encryption at rest | Firebase default | AES-256 |
| Data encryption in transit | HTTPS/TLS | Default |
| Children's privacy (COPPA) | Not targeted | Banataq is 13+ |
| Nigerian Data Protection Reg. | Planned | Local data storage option needed |
