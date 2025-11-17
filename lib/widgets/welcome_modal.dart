import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/spacing.dart';
import '../providers/settings_provider.dart';
import '../providers/notification_provider.dart';

/// Welcome modal shown on first app launch
/// Introduces the app's value proposition and offers notification setup
class WelcomeModal extends ConsumerWidget {
  const WelcomeModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settingsAsync = ref.watch(settingsProvider);
    final accentColor = settingsAsync.maybeWhen(
      data: (settings) => settings.accentColor,
      orElse: () => theme.colorScheme.primary,
    );

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: EdgeInsets.all(AppSpacing.spacing4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // App Icon
            Image.asset(
              'assets/app_icon.png',
              width: 56,
              height: 56,
            ),
            SizedBox(height: AppSpacing.spacing3),

            // Title
            Text(
              'Welcome to Sisyphus',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.spacing2),

            // Body text
            Text(
              'Understanding how you spend your time starts with paying attention.\n\n'
              'Track your happiness every 30 minutes to discover patterns and reprioritize what matters.',
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.spacing4),

            // Enable Reminders Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleEnableReminders(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing2),
                ),
                child: const Text('Enable Reminders'),
              ),
            ),
            SizedBox(height: AppSpacing.spacing2),

            // Maybe Later Button
            TextButton(
              onPressed: () => _handleMaybeLater(context, ref),
              child: const Text('Maybe Later'),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle "Enable Reminders" button tap
  Future<void> _handleEnableReminders(BuildContext context, WidgetRef ref) async {
    final notificationService = ref.read(notificationServiceProvider);

    // Request permissions
    final hasPermission = await notificationService.requestPermissions();

    if (hasPermission) {
      // Enable notifications with default hours (7 AM - 10 PM)
      await ref.read(settingsProvider.notifier).toggleNotifications(true);

      // Show success feedback
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reminders enabled! You\'ll get notified every 30 minutes.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      // Permission denied - show guidance
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permissions Needed'),
            content: const Text(
              'To receive reminders, please enable notifications for Sisyphus in your device settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }

    // Mark welcome as seen
    await ref.read(settingsProvider.notifier).markWelcomeSeen();

    // Close welcome modal
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Handle "Maybe Later" button tap
  Future<void> _handleMaybeLater(BuildContext context, WidgetRef ref) async {
    // Mark welcome as seen
    await ref.read(settingsProvider.notifier).markWelcomeSeen();

    // Close welcome modal
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
