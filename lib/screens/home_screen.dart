import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_theme.dart';

/// Home screen - Main timeslot list view
/// This is a placeholder for Phase 1, will be fully implemented in Phase 2
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HappyTracks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              // TODO: Navigate to calendar screen
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              // TODO: Navigate to analysis screen
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings screen
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mood,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: AppTheme.spacing4),
            Text(
              'Welcome to HappyTracks',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            SizedBox(height: AppTheme.spacing2),
            Text(
              'Phase 1: Foundation Complete ✓',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: AppTheme.spacing8),
            Text(
              'Next: Phase 2 - Core Feature',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
