/// Patient account. Later this becomes the root of the "one patient,
/// one verified care thread" data model.
class SmritiUser {
  final String name;
  final String identifier; // email or phone
  final int? age;
  final String language;

  const SmritiUser({
    required this.name,
    required this.identifier,
    this.age,
    this.language = 'English',
  });
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// Swap MockAuthService for a Firebase / backend implementation later.
/// The UI only talks to this interface.
abstract class AuthService {
  Future<SmritiUser> signIn(String identifier, String password);
  Future<SmritiUser> signUp({
    required String name,
    required String identifier,
    required String password,
    required int age,
    required String language,
  });
}

class MockAuthService implements AuthService {
  MockAuthService._() {
    // Demo account so you can log in instantly during the hackathon demo.
    _accounts['demo@smriti.app'] = _Record(
      'demo1234',
      const SmritiUser(
        name: 'Demo Patient',
        identifier: 'demo@smriti.app',
        age: 34,
        language: 'English',
      ),
    );
  }

  static final MockAuthService instance = MockAuthService._();

  final Map<String, _Record> _accounts = {};

  @override
  Future<SmritiUser> signIn(String identifier, String password) async {
    await Future.delayed(const Duration(milliseconds: 1400));
    final rec = _accounts[identifier.trim().toLowerCase()];
    if (rec == null) {
      throw AuthException('No account found. Please sign up first.');
    }
    if (rec.password != password) {
      throw AuthException('Incorrect password. Please try again.');
    }
    return rec.user;
  }

  @override
  Future<SmritiUser> signUp({
    required String name,
    required String identifier,
    required String password,
    required int age,
    required String language,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1600));
    final key = identifier.trim().toLowerCase();
    if (_accounts.containsKey(key)) {
      throw AuthException('An account with this email/phone already exists.');
    }
    final user = SmritiUser(
      name: name.trim(),
      identifier: key,
      age: age,
      language: language,
    );
    _accounts[key] = _Record(password, user);
    return user;
  }
}

class _Record {
  final String password;
  final SmritiUser user;
  _Record(this.password, this.user);
}