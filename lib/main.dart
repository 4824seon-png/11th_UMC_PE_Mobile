import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/movie_log_app.dart';
import 'core/config/tmdb_config.dart';

Future<void> main() async {
  // runApp 전에 asset(.env)을 읽으려면 Flutter 엔진 연결을 먼저 준비해야 한다.
  WidgetsFlutterBinding.ensureInitialized();

  // await: 로드가 끝나기 전에 Token을 읽으면 빈 값이 나온다.
  await dotenv.load(fileName: '.env');

  // Token 원문 대신 설정 여부만 출력한다. (debug 빌드에서만)
  if (kDebugMode) {
    debugPrint('[TMDB] Token 설정됨: ${TmdbConfig.hasAccessToken}');
  }

  runApp(const MovieLogApp());
}
