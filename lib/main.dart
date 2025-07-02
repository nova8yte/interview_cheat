import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(InterviewCheatApp());
  // runZonedGuarded(body, onError) runZonedGuarded is actually a dope thing.
  // It provides you with single point of logging for Errors.
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
  late final TabController _ctrl = TabController(length: 4, vsync: this);

  // The difference between Final and Const is in runtime.
  // Const is set at compile time, whilst Final is set at runtime.
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
  final _counterSingle$ = StreamController<int>();

  int _n = 0;

  static const _native = MethodChannel('demo.native/ping');
  String _nativeResp = '-';

  // Utilize different states here <

  // State management in flutter

  @override
  void dispose() {
    _counterBroadcast$.close();
    _counterSingle$.close();
    _ctrl.dispose();
    super.dispose();
  }

  // A note on Futures and how they are done underneath.
  // Futures are just async operations, that executed out of sync with main thread.
  // I will abrubtly state that in flutter there's one main thread. Where both logic and ui is run.
  // Futures() sent to stack, that prioritizes microtasks over the other. That's the story.

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
    // ~/
    // print(7 ~/ 3);    // 2
    // print(-7 ~/ 3);   // -2   ← notice this
    // print(7 / 3);     // 2.333...
    sw.stop();
    final constant = sw.elapsedMicroseconds;
    return 'O(n) sum=$sum in ${linear}ms | O(1) fetch=$getMid in ${constant}µs';
  }

  Future<void> _callNative() async {
    try {
      final String response = await _native.invokeMethod('ping');

      // It just calls markNeedsBUild
      // void setState(VoidCallback fn) {
      // setState() must not be called after dispose() or inside constructor.
      // Always check `mounted` before calling setState from async/timer callbacks.
      // setState() must not return a Future — run async code *before* calling setState.
      //   _element!.markNeedsBuild();
      // }

      /// Marks the element as dirty and adds it to the global list of widgets to
      /// rebuild in the next frame.
      ///
      /// Since it is inefficient to build an element twice in one frame,
      /// applications and widgets should be structured so as to only mark
      /// widgets dirty during event handlers before the frame begins, not during
      /// the build itself.
      setState(() => _nativeResp = response);
    } catch (e) {
      setState(() => _nativeResp = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inteview Cheat'),
        bottom: TabBar(
          controller: _ctrl,
          tabs: const [
            Tab(text: 'Basics'),
            Tab(text: 'Algo'),
            Tab(text: 'Stream'),
            Tab(text: 'Native'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _ctrl,
        children: [
          // BASICS
          ListView(
            padding: const EdgeInsets.all(12),
            children: _basicQA
                .map((q) =>
                    ListTile(leading: const Icon(Icons.check), title: Text(q)))
                .toList(),
          ),
          // ALGO
          Center(
            child: ElevatedButton(
              onPressed: () async {
                final res = await _benchAlgo();
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(res)));
                }
              },
              child: const Text('Run O(n) vs O(1) benchmark'),
            ),
          ),
          // STREAM
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
          // NATIVE
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
        ],
      ),
    );
  }
}
