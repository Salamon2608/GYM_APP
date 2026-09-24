import 'package:encrypt/encrypt.dart';

class EncryptionService {
  // USER: This should ideally be a secure key stored in environment variables
  // or a secure vault. For this implementation, we use a fixed 32-char key.
  static const String _keyString = 'my32charultrasecurekeyforgym1234'; // 32 chars
  static const String _ivString = 'my16charivstring'; // 16 chars

  static final _key = Key.fromUtf8(_keyString);
  static final _iv = IV.fromUtf8(_ivString);
  static final _encrypter = Encrypter(AES(_key, mode: AESMode.cbc));

  /// Encrypts a plain text string
  static String encrypt(String plainText) {
    if (plainText.isEmpty) return '';
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  /// Decrypts an encrypted base64 string
  static String decrypt(String encryptedBase64) {
    if (encryptedBase64.isEmpty) return '';
    try {
      return _encrypter.decrypt64(encryptedBase64, iv: _iv);
    } catch (e) {
      return 'Error decrypting';
    }
  }
}
