import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/timeslot.dart';
import 'database_provider.dart';
import 'selected_date_provider.dart';

part 'timeslot_provider.g.dart';

/// Provider for timeslots for a specific date
/// Automatically watches the selected date and updates when it changes
@riverpod
class Timeslots extends _$Timeslots {
  @override
  Future<List<Timeslot>> build() async {
    // Watch the selected date
    final date = ref.watch(selectedDateProvider);

    // Load timeslots for that date
    final dbService = ref.read(databaseServiceProvider);
    return await dbService.getTimeslotsForDate(date);
  }

  /// Update happiness score for a timeslot
  Future<void> updateScore(int timeIndex, int score) async {
    final date = ref.read(selectedDateProvider);
    final dbService = ref.read(databaseServiceProvider);

    await dbService.updateHappinessScore(date, timeIndex, score);

    // Refresh timeslots
    ref.invalidateSelf();
  }

  /// Update description for a timeslot
  Future<void> updateDescription(int timeIndex, String? description) async {
    final date = ref.read(selectedDateProvider);
    final dbService = ref.read(databaseServiceProvider);

    await dbService.updateDescription(date, timeIndex, description);

    // Refresh timeslots
    ref.invalidateSelf();
  }

  /// Update both score and description in one transaction
  Future<void> updateTimeslot(int timeIndex, int score, String? description) async {
    final date = ref.read(selectedDateProvider);
    final dbService = ref.read(databaseServiceProvider);

    // Update score and description separately
    // We could optimize this with a single database call in the future
    await dbService.updateHappinessScore(date, timeIndex, score);
    if (description != null && description.isNotEmpty) {
      await dbService.updateDescription(date, timeIndex, description);
    }

    // Refresh timeslots
    ref.invalidateSelf();
  }
}

/// Provider for top moments (highest happiness scores)
@riverpod
class TopMoments extends _$TopMoments {
  @override
  Future<List<Timeslot>> build({int limit = 10}) async {
    final dbService = ref.read(databaseServiceProvider);
    return await dbService.getTopMoments(limit: limit);
  }

  /// Refresh top moments
  void refresh() {
    ref.invalidateSelf();
  }
}

/// Provider for bottom moments (lowest happiness scores)
@riverpod
class BottomMoments extends _$BottomMoments {
  @override
  Future<List<Timeslot>> build({int limit = 10}) async {
    final dbService = ref.read(databaseServiceProvider);
    return await dbService.getBottomMoments(limit: limit);
  }

  /// Refresh bottom moments
  void refresh() {
    ref.invalidateSelf();
  }
}

/// Provider for all tracked dates
@riverpod
class TrackedDates extends _$TrackedDates {
  @override
  Future<List<String>> build() async {
    final dbService = ref.read(databaseServiceProvider);
    return await dbService.getTrackedDates();
  }

  /// Refresh tracked dates list
  void refresh() {
    ref.invalidateSelf();
  }
}
