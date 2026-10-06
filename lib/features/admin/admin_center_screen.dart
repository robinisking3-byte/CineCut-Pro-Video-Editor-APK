import 'package:flutter/material.dart';

class AdminCenterScreen extends StatelessWidget {
  const AdminCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Center'),
        actions: const [
          Chip(
            label: Text('robinisking3@gmail.com', style: TextStyle(fontSize: 12)),
            backgroundColor: Color(0xFFF59E0B),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            color: Color(0xFF18181B),
            child: ListTile(
              leading: Icon(Icons.verified_user, color: Colors.amber),
              title: Text('Super Admin Authority'),
              subtitle: Text('Default owner: robinisking3@gmail.com - Cloud Functions claim active'),
            ),
          ),
          Card(
            color: Color(0xFF18181B),
            child: ListTile(
              leading: Icon(Icons.monetization_on, color: Colors.amber),
              title: Text('Coin Minting & Ledger'),
              subtitle: Text('Authoritative balance management via trusted Firebase triggers'),
            ),
          ),
        ],
      ),
    );
  }
}
