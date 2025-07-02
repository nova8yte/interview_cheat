import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class Qa {
  Qa(this.id, this.q, this.a, this.tag);
  final String id;
  final String q;
  final String a;
  final String tag;

  factory Qa.fromJson(Map<String, dynamic> j) =>
      Qa(j['id'], j['q'], j['a'], j['tag']);
}

void main() {
  runApp(const InterviewCheatApp());
}

class InterviewCheatApp extends StatelessWidget {
  const InterviewCheatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Interview Cheat',
      theme: ThemeData.dark(),
      home: const CheatHome(),
    );
  }
}

class CheatHome extends StatefulWidget {
  const CheatHome({super.key});

  @override
  State<StatefulWidget> createState() => _CheatHomeState();
}

class _CheatHomeState extends State<CheatHome>
    with SingleTickerProviderStateMixin {
  late final TabController _ctrl = TabController(length: 6, vsync: this);

  static const _skipFor = Duration(hours: 24);

  List<Qa> _pool = [];
  final _prefsFuture = SharedPreferences.getInstance();
  Map<String, int> _seen = {};
  final _review = <Qa>[];

  final _basicQA = <String>[
    "What is Flutter and how does it differ from other UI toolkits?",
    "What’s the difference between hot reload and hot restart in Flutter?",
    "Can you explain Flutter’s build modes: debug, profile, and release?",
    "What’s the difference between a StatefulWidget and a StatelessWidget?",
    "What’s the role of `main()` and `runApp()` in a Flutter app?",
    "What are the types of Dart Streams, and how does RxDart extend them?",
    "How does `setState()` work under the hood in Flutter?",
    "When would you use `MainAxisAlignment` vs `CrossAxisAlignment`?",
    "What are the five SOLID principles and why are they important in app architecture?",
    "Can you walk through some Big-O notations relevant to Flutter or Dart code?",
    "How do you communicate with native code in Flutter?",
    "How can you embed native views inside a Flutter application?"
  ];

  final _counterBroadcast$ = StreamController<int>.broadcast();
  int _n = 0;
  static const _native = MethodChannel('demo.native/ping');
  String _nativeResp = '-';

  @override
  void initState() {
    super.initState();
    _loadPool();
  }

  Future<void> _loadPool() async {
    try {
      final data = await rootBundle.loadString('assets/qa.json');
      final list = jsonDecode(data) as List;
      _pool = list.map((e) => Qa.fromJson(e)).toList();
    } catch (_) {
      _pool = _basicQA
          .asMap()
          .entries
          .map((e) => Qa('b${e.key}', e.value, 'A', 'basics'))
          .toList();
    }
    final prefs = await _prefsFuture;
    _seen = Map<String, int>.from(jsonDecode(prefs.getString('seen') ?? '{}'));
    setState(() {});
  }

  @override
  void dispose() {
    _counterBroadcast$.close();
    _ctrl.dispose();
    super.dispose();
  }

  // Simple O(n) vs O(1) timing
  Future<String> _benchAlgo() async {
    final list = List<int>.generate(10000, (i) => i);
    final sw = Stopwatch()..start();
    int sum = list.reduce((a, b) => a + b);
    sw.stop();
    final linear = sw.elapsedMilliseconds;
    sw
      ..reset()
      ..start();

    int getMid = list[list.length ~/ 2];
    sw.stop();
    final constant = sw.elapsedMicroseconds;
    return 'O(n) sum=$sum in ${linear}ms | O(1) fetch=$getMid in ${constant}µs';
  }

  Future<void> _callNative() async {
    try {
      final String response = await _native.invokeMethod('ping');

      setState(() => _nativeResp = response);
    } catch (e) {
      setState(() => _nativeResp = 'Error: $e');
    }
  }

  Qa? _nextQa([Set<String>? tags]) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final pool = _pool.where((q) {
      if (tags != null && tags.isNotEmpty && !tags.contains(q.tag))
        return false;
      final last = _seen[q.id];
      return last == null || now - last > _skipFor.inMilliseconds;
    }).toList()
      ..shuffle();
    return pool.isEmpty ? null : pool.first;
  }

  Future<void> _recordCorrect(String id) async {
    final prefs = await _prefsFuture;
    _seen[id] = DateTime.now().millisecondsSinceEpoch;
    await prefs.setString('seen', jsonEncode(_seen));
  }

  int _lev(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final dp = List.generate(a.length + 1,
        (_) => List<int>.filled(b.length + 1, 0, growable: false));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inteview Cheat'),
        bottom: TabBar(
          controller: _ctrl,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Basics'),
            Tab(text: 'Algo'),
            Tab(text: 'Stream'),
            Tab(text: 'Native'),
            Tab(icon: Icon(Icons.flash_on)),
            Tab(text: 'Review'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _ctrl,
        children: [
          ListView(
            padding: const EdgeInsets.all(12),
            children: _basicQA
                .map((q) =>
                    ListTile(leading: const Icon(Icons.check), title: Text(q)))
                .toList(),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(kReleaseMode
                  ? 'RELEASE'
                  : (bool.fromEnvironment('dart.vm.profile')
                      ? 'PROFILE'
                      : 'DEBUG')),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final res = await _benchAlgo();
                  if (mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(res)));
                  }
                },
                child: const Text('Run O(n) vs O(1) benchmark'),
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StreamBuilder<int>(
                stream: _counterBroadcast$.stream,
                builder: (c, snap) => Text('Stream counter: ${snap.data ?? 0}',
                    style: const TextStyle(fontSize: 20)),
              ),
              ElevatedButton(
                  onPressed: () {
                    _counterBroadcast$.add(++_n);
                  },
                  child: const Text('Add event'))
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Platform response: $_nativeResp'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _callNative,
                child: const Text('Ping native'),
              )
            ],
          ),
          PressureQuiz(
            nextQa: _nextQa,
            recordCorrect: _recordCorrect,
            lev: _lev,
            review: _review,
          ),
          ListView(
            padding: const EdgeInsets.all(12),
            children: _review
                .map((q) => ListTile(
                      title: Text(q.q),
                      subtitle: Text('${q.a} [${q.tag}]'),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class PressureQuiz extends StatefulWidget {
  const PressureQuiz(
      {super.key,
      required this.nextQa,
      required this.recordCorrect,
      required this.lev,
      required this.review});
  final Qa? Function([Set<String>? tags]) nextQa;
  final Future<void> Function(String) recordCorrect;
  final int Function(String, String) lev;
  final List<Qa> review;

  @override
  State<PressureQuiz> createState() => _PressureQuizState();
}

class _PressureQuizState extends State<PressureQuiz> {
  Qa? _current;
  final _ctrl = TextEditingController();
  int _time = 30;
  bool _light = false;
  Timer? _timer;
  Set<String> _tags = {};
  List<Qa> _options = [];

  @override
  void initState() {
    super.initState();
    _next();
  }

  void _next() {
    _timer?.cancel();
    _ctrl.clear();
    _current = widget.nextQa(_tags);
    if (_current == null) return;
    _time = _light ? 5 : 30;
    if (_light) _makeOptions();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (--_time == 3) Vibration.vibrate(duration: 200);
      if (_time <= 0) {
        _miss();
        _next();
      }
      setState(() {});
    });
    setState(() {});
  }

  void _makeOptions() {
    _options = [_current!];
    final picks = <Qa>{};
    while (picks.length < 3) {
      final q = widget.nextQa(null);
      if (q == null || q.id == _current!.id) continue;
      picks.add(q);
    }
    _options.addAll(picks);
    _options.shuffle();
  }

  void _submit(String answer) {
    if (_current == null) return;
    final correct =
        widget.lev(answer.trim().toLowerCase(), _current!.a.toLowerCase()) <= 2;
    if (correct) {
      widget.recordCorrect(_current!.id);
    } else {
      widget.review.insert(0, _current!);
      if (widget.review.length > 20) widget.review.removeLast();
    }
    _next();
  }

  void _miss() {
    if (_current == null) return;
    widget.review.insert(0, _current!);
    if (widget.review.length > 20) widget.review.removeLast();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_current == null) {
      return const Center(child: Text('No questions'));
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Wrap(
            spacing: 4,
            children: ['basics', 'perf', 'native', 'algo', 'soft']
                .map((t) => FilterChip(
                      label: Text(t),
                      selected: _tags.contains(t),
                      onSelected: (v) {
                        setState(() => v ? _tags.add(t) : _tags.remove(t));
                        _next();
                      },
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          Text(_current!.q),
          const SizedBox(height: 12),
          if (_light)
            ..._options
                .map((q) => RadioListTile<String>(
                      title: Text(q.a),
                      value: q.a,
                      groupValue: null,
                      onChanged: (v) => _submit(v ?? ''),
                    ))
                .toList()
          else
            TextField(
              controller: _ctrl,
              onSubmitted: _submit,
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                child: const Icon(Icons.flash_on),
                onLongPress: () {
                  setState(() => _light = !_light);
                  _next();
                },
              ),
              Text('$_time s'),
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: () => _submit(_ctrl.text),
              ),
            ],
          )
        ],
      ),
    );
  }
}
