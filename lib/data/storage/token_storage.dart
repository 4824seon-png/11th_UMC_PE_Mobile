import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 토큰 저장 규칙을 인증 흐름에서 분리한 추상화.
/// AuthViewModel·Interceptor는 이 인터페이스만 알고, 실제 저장소(Keychain/Keystore)는 모른다.

/// 저장소 규칙만 정의, 실제 구현은 SecureTokenStorage
abstract interface class TokenStorage {
  Future<void> saveAccessToken(String token);
  Future<String?> readAccessToken();
  Future<void> deleteAccessToken();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage(this._storage);

  // 읽기·쓰기·삭제에 같은 key를 써야 한다.
  static const _accessTokenKey = 'movielog.access_token';
  final FlutterSecureStorage _storage;

  @override
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  @override
  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  @override
  Future<void> deleteAccessToken() => _storage.delete(key: _accessTokenKey);
}
