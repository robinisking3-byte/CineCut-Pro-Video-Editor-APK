import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CineCut Discover'),
      ),
      body: const Center(
        child: Text('CineCut Creator Feed & Templates', style: TextStyle(color: Colors.white70)),
      ),
    );
  }
}
