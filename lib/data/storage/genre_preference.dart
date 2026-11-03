import 'package:shared_preferences/shared_preferences.dart';

/// 영화 목록에서 마지막으로 선택한 장르를 기기에 저장·복원한다.
class GenrePreference {
  // preferences를 받을 수 있게 열어 두면 테스트에서 가짜 저장소를 넣을 수 있다.
  GenrePreference({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  // 읽기·쓰기에 같은 Key를 써야 복원된다.
  static const _selectedGenreIdKey = 'selected_genre_id';

  final SharedPreferencesAsync _preferences;

  /// 저장된 장르 id. 저장한 적이 없거나 '전체'면 null.
  Future<int?> read() {
    return _preferences.getInt(_selectedGenreIdKey);
  }

  /// genreId가 null('전체')이면 저장값을 지운다.
  Future<void> save(int? genreId) async {
    if (genreId == null) {
      await _preferences.remove(_selectedGenreIdKey);
      return;
    }
    await _preferences.setInt(_selectedGenreIdKey, genreId);
  }

  Future<void> clear() async {
    await _preferences.remove(_selectedGenreIdKey);
  }
}
