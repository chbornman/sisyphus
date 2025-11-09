import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/database_service.dart';

part 'database_provider.g.dart';

/// Provider for DatabaseService singleton
/// This is the main service used throughout the app for data persistence
@riverpod
DatabaseService databaseService(DatabaseServiceRef ref) {
  return DatabaseService();
}
