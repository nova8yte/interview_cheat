import 'dart:convert';
import 'dart:io';

Future<List<Map<String, dynamic>>> _load() async {
  try {
    final data = await File('assets/qa.json').readAsString();
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  } catch (_) {
    return [];
  }
}

int _lev(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  final dp = List.generate(
      a.length + 1, (_) => List<int>.filled(b.length + 1, 0, growable: false));
  for (var i = 0; i <= a.length; i++) dp[i][0] = i;
  for (var j = 0; j <= b.length; j++) dp[0][j] = j;
  for (var i = 1; i <= a.length; i++) {
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      dp[i][j] = [dp[i - 1][j] + 1, dp[i][j - 1] + 1, dp[i - 1][j - 1] + cost]
          .reduce((v, e) => v < e ? v : e);
    }
  }
  return dp[a.length][b.length];
}

Future<void> main(List<String> args) async {
  final tagArg = args.firstWhere((a) => a.startsWith('--tag='), orElse: () => '');
  final tag = tagArg.isEmpty ? null : tagArg.split('=')[1];
  final qa = await _load();
  final filtered = tag == null ? qa : qa.where((e) => e['tag'] == tag).toList();
  filtered.shuffle();
  if (filtered.isEmpty) return;
  final q = filtered.first;
  stdout.writeln(q['q']);
  final input = stdin.readLineSync() ?? '';
  final ok = _lev(input.trim().toLowerCase(), q['a'].toLowerCase()) <= 2;
  stdout.writeln(ok ? '✓' : '✗  answer: ${q['a']}');
}
