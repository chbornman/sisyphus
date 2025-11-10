// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timeslot_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$timeslotsHash() => r'fdae4b12fc6077f41ab7186c647749d7fa7ed6d5';

/// Provider for timeslots for a specific date
/// Automatically watches the selected date and updates when it changes
///
/// Copied from [Timeslots].
@ProviderFor(Timeslots)
final timeslotsProvider =
    AutoDisposeAsyncNotifierProvider<Timeslots, List<Timeslot>>.internal(
      Timeslots.new,
      name: r'timeslotsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$timeslotsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$Timeslots = AutoDisposeAsyncNotifier<List<Timeslot>>;
String _$topMomentsHash() => r'3c2100143e78f54c742c74ee773b4b58f1b7cf7c';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$TopMoments
    extends BuildlessAutoDisposeAsyncNotifier<List<Timeslot>> {
  late final int limit;

  FutureOr<List<Timeslot>> build({int limit = 10});
}

/// Provider for top moments (highest happiness scores)
///
/// Copied from [TopMoments].
@ProviderFor(TopMoments)
const topMomentsProvider = TopMomentsFamily();

/// Provider for top moments (highest happiness scores)
///
/// Copied from [TopMoments].
class TopMomentsFamily extends Family<AsyncValue<List<Timeslot>>> {
  /// Provider for top moments (highest happiness scores)
  ///
  /// Copied from [TopMoments].
  const TopMomentsFamily();

  /// Provider for top moments (highest happiness scores)
  ///
  /// Copied from [TopMoments].
  TopMomentsProvider call({int limit = 10}) {
    return TopMomentsProvider(limit: limit);
  }

  @override
  TopMomentsProvider getProviderOverride(
    covariant TopMomentsProvider provider,
  ) {
    return call(limit: provider.limit);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'topMomentsProvider';
}

/// Provider for top moments (highest happiness scores)
///
/// Copied from [TopMoments].
class TopMomentsProvider
    extends AutoDisposeAsyncNotifierProviderImpl<TopMoments, List<Timeslot>> {
  /// Provider for top moments (highest happiness scores)
  ///
  /// Copied from [TopMoments].
  TopMomentsProvider({int limit = 10})
    : this._internal(
        () => TopMoments()..limit = limit,
        from: topMomentsProvider,
        name: r'topMomentsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$topMomentsHash,
        dependencies: TopMomentsFamily._dependencies,
        allTransitiveDependencies: TopMomentsFamily._allTransitiveDependencies,
        limit: limit,
      );

  TopMomentsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.limit,
  }) : super.internal();

  final int limit;

  @override
  FutureOr<List<Timeslot>> runNotifierBuild(covariant TopMoments notifier) {
    return notifier.build(limit: limit);
  }

  @override
  Override overrideWith(TopMoments Function() create) {
    return ProviderOverride(
      origin: this,
      override: TopMomentsProvider._internal(
        () => create()..limit = limit,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<TopMoments, List<Timeslot>>
  createElement() {
    return _TopMomentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TopMomentsProvider && other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TopMomentsRef on AutoDisposeAsyncNotifierProviderRef<List<Timeslot>> {
  /// The parameter `limit` of this provider.
  int get limit;
}

class _TopMomentsProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<TopMoments, List<Timeslot>>
    with TopMomentsRef {
  _TopMomentsProviderElement(super.provider);

  @override
  int get limit => (origin as TopMomentsProvider).limit;
}

String _$bottomMomentsHash() => r'c28bdf4bdd37952071452556238c3e90607da796';

abstract class _$BottomMoments
    extends BuildlessAutoDisposeAsyncNotifier<List<Timeslot>> {
  late final int limit;

  FutureOr<List<Timeslot>> build({int limit = 10});
}

/// Provider for bottom moments (lowest happiness scores)
///
/// Copied from [BottomMoments].
@ProviderFor(BottomMoments)
const bottomMomentsProvider = BottomMomentsFamily();

/// Provider for bottom moments (lowest happiness scores)
///
/// Copied from [BottomMoments].
class BottomMomentsFamily extends Family<AsyncValue<List<Timeslot>>> {
  /// Provider for bottom moments (lowest happiness scores)
  ///
  /// Copied from [BottomMoments].
  const BottomMomentsFamily();

  /// Provider for bottom moments (lowest happiness scores)
  ///
  /// Copied from [BottomMoments].
  BottomMomentsProvider call({int limit = 10}) {
    return BottomMomentsProvider(limit: limit);
  }

  @override
  BottomMomentsProvider getProviderOverride(
    covariant BottomMomentsProvider provider,
  ) {
    return call(limit: provider.limit);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'bottomMomentsProvider';
}

/// Provider for bottom moments (lowest happiness scores)
///
/// Copied from [BottomMoments].
class BottomMomentsProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<BottomMoments, List<Timeslot>> {
  /// Provider for bottom moments (lowest happiness scores)
  ///
  /// Copied from [BottomMoments].
  BottomMomentsProvider({int limit = 10})
    : this._internal(
        () => BottomMoments()..limit = limit,
        from: bottomMomentsProvider,
        name: r'bottomMomentsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$bottomMomentsHash,
        dependencies: BottomMomentsFamily._dependencies,
        allTransitiveDependencies:
            BottomMomentsFamily._allTransitiveDependencies,
        limit: limit,
      );

  BottomMomentsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.limit,
  }) : super.internal();

  final int limit;

  @override
  FutureOr<List<Timeslot>> runNotifierBuild(covariant BottomMoments notifier) {
    return notifier.build(limit: limit);
  }

  @override
  Override overrideWith(BottomMoments Function() create) {
    return ProviderOverride(
      origin: this,
      override: BottomMomentsProvider._internal(
        () => create()..limit = limit,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<BottomMoments, List<Timeslot>>
  createElement() {
    return _BottomMomentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BottomMomentsProvider && other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BottomMomentsRef on AutoDisposeAsyncNotifierProviderRef<List<Timeslot>> {
  /// The parameter `limit` of this provider.
  int get limit;
}

class _BottomMomentsProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<BottomMoments, List<Timeslot>>
    with BottomMomentsRef {
  _BottomMomentsProviderElement(super.provider);

  @override
  int get limit => (origin as BottomMomentsProvider).limit;
}

String _$trackedDatesHash() => r'8c1a99a050e24d0b8dd01290967e637914fcf55c';

/// Provider for all tracked dates
///
/// Copied from [TrackedDates].
@ProviderFor(TrackedDates)
final trackedDatesProvider =
    AutoDisposeAsyncNotifierProvider<TrackedDates, List<String>>.internal(
      TrackedDates.new,
      name: r'trackedDatesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$trackedDatesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TrackedDates = AutoDisposeAsyncNotifier<List<String>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
