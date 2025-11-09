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

    // Optimistically update state first
    final currentState = state.valueOrNull;
    if (currentState != null) {
      final updatedSlots = currentState.map((slot) {
        if (slot.timeIndex == timeIndex) {
          return slot.copyWith(
            happinessScore: score,
            updatedAt: DateTime.now(),
          );
        }
        return slot;
      }).toList();
      state = AsyncValue.data(updatedSlots);
    }

    // Then save to database in background
    await dbService.updateHappinessScore(date, timeIndex, score);
  }

  /// Update description for a timeslot
  Future<void> updateDescription(int timeIndex, String? description) async {
    final date = ref.read(selectedDateProvider);
    final dbService = ref.read(databaseServiceProvider);

    // Optimistically update state first
    final currentState = state.valueOrNull;
    if (currentState != null) {
      final updatedSlots = currentState.map((slot) {
        if (slot.timeIndex == timeIndex) {
          return slot.copyWith(
            description: description,
            updatedAt: DateTime.now(),
          );
        }
        return slot;
      }).toList();
      state = AsyncValue.data(updatedSlots);
    }

    // Then save to database in background
    await dbService.updateDescription(date, timeIndex, description);
  }

  /// Update both score and description in one transaction
  Future<void> updateTimeslot(int timeIndex, int score, String? description) async {
    final date = ref.read(selectedDateProvider);
    final dbService = ref.read(databaseServiceProvider);

    // Optimistically update state first
    final currentState = state.valueOrNull;
    if (currentState != null) {
      final updatedSlots = currentState.map((slot) {
        if (slot.timeIndex == timeIndex) {
          return slot.copyWith(
            happinessScore: score,
            description: description,
            updatedAt: DateTime.now(),
          );
        }
        return slot;
      }).toList();
      state = AsyncValue.data(updatedSlots);
    }

    // Then save to database in background
    await dbService.updateHappinessScore(date, timeIndex, score);
    if (description != null && description.isNotEmpty) {
      await dbService.updateDescription(date, timeIndex, description);
    }
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
