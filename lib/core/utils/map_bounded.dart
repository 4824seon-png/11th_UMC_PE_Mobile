// ── ① 여러 값을 변환하되, 동시에 최대 concurrency개만 실행 ──
Future<List<R>> mapBounded<T, R>(
  Iterable<T> values,
  int concurrency,
  Future<R> Function(T value) convert,
) async {
  final input = values.toList(growable: false);
  if (input.isEmpty) return <R>[];
  if (concurrency <= 0) {
    throw ArgumentError.value(concurrency, 'concurrency', 'must be positive');
  }

  // ── ② 결과 자리를 미리 만들어 순서 보장 ──
  final output = List<R?>.filled(input.length, null);
  var next = 0;

  // ── ③ 일꾼: 남은 작업 번호를 하나씩 가져가 처리 ──
  Future<void> worker() async {
    while (true) {
      final index = next++;
      if (index >= input.length) return;
      output[index] = await convert(input[index]);
    }
  }

  // ── ④ 일꾼 최대 5명 → Future.wait로 모두 끝날 때까지 대기 ──
  final workers = List.generate(
    concurrency.clamp(1, input.length),
    (_) => worker(),
  );
  await Future.wait(workers);
  return output.cast<R>();
}
