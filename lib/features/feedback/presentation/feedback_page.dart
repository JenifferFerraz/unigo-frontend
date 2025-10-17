import 'package:flutter/material.dart';
import '../../../core/layouts/main_layout.dart';

class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainLayout(
      title: 'Feedback',
      child: Center(
        child: Text('Página de Feedback'),
      ),
    );
  }
}


