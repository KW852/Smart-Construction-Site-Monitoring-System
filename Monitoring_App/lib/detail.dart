import 'package:flutter/material.dart';

class DetailPage extends StatelessWidget {
  final String fullText;

  const DetailPage({super.key, required this.fullText});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notification Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            fullText,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}