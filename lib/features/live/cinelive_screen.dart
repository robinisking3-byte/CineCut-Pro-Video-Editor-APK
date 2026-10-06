import 'package:flutter/material.dart';

class CineLiveScreen extends StatelessWidget {
  const CineLiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CineLive Broadcasts'),
      ),
      body: const Center(
        child: Text('Live HLS Streams, Chat & Reactions', style: TextStyle(color: Colors.white70)),
      ),
    );
  }
}
