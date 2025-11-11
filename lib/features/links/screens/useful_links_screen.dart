import 'package:flutter/material.dart';

class UsefulLinksScreen extends StatelessWidget {
  const UsefulLinksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Links Úteis',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.link_rounded,
                size: 80,
                color: const Color.fromRGBO(76, 175, 80, 1),
              ),
              const SizedBox(height: 24),
              const Text(
                'Links Úteis',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Esta funcionalidade está em desenvolvimento',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color.fromRGBO(158, 158, 158, 1),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Em breve disponível!',
                style: TextStyle(
                  color: Color.fromRGBO(158, 158, 158, 1),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
