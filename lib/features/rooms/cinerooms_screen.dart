import 'package:flutter/material.dart';

class CineRoomsScreen extends StatelessWidget {
  const CineRoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CineRooms'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(title: Text('Founder Lounge'), subtitle: Text('Exclusive room for Founder badge holders')),
          ListTile(title: Text('Diamond Studio'), subtitle: Text('Diamond tier creators room')),
          ListTile(title: Text('Gold Hub'), subtitle: Text('Color grading and sound design')),
        ],
      ),
    );
  }
}
