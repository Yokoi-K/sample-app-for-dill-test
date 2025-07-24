import 'package:flutter/material.dart';
import 'package:module_a/module_a.dart';
import 'package:module_b/module_b.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Multi Module Example')),
        body: Column(
          children: [
            Text('A: ${ModuleA().run()}'),
            Text('B: ${ModuleB().run()}'),
          ],
        ),
      ),
    );
  }
}
