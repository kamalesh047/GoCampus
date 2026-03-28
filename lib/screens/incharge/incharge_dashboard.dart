import 'package:flutter/material.dart';

class InchargeDashboard extends StatelessWidget {
  const InchargeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Incharge Dashboard')),
      body: const Center(child: Text('Incharge View')),
    );
  }
}
