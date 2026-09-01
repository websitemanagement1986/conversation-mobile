import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import 'setup_screen.dart';

class RecapScreen extends StatelessWidget {
  const RecapScreen({super.key, required this.recap});

  final SessionRecap recap;

  @override
  Widget build(BuildContext context) {
    final minutes = recap.endedAt.difference(recap.startedAt).inMinutes.clamp(1, 9999);

    return Scaffold(
      appBar: AppBar(title: const Text('Session recap')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '${recap.config.targetLanguage.name} · ${recap.config.level.label} · $minutes min',
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceRaised,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Text(recap.performanceNote),
          ),
          if (recap.corrections.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Corrections (${recap.corrections.length})',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...recap.corrections.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${c.original} → ${c.corrected}\n${c.explanation}'),
                  ),
                )),
          ],
          if (recap.vocabulary.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('New vocabulary (${recap.vocabulary.length})',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...recap.vocabulary.map((v) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${v.word} — ${v.meaning}\n${v.example}'),
                  ),
                )),
          ],
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  child: const Text('Home'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final key = await StorageService().getApiKey();
                    if (!context.mounted || key == null) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => SetupScreen(apiKey: key),
                      ),
                      (r) => false,
                    );
                  },
                  child: const Text('Practice again'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
