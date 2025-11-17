// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deep_link_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$deepLinkNotifierHash() => r'b91eda6151ba40aaf1890d2654c778cdf3d5c504';

/// Provider for managing deep link navigation requests
///
/// Used to communicate navigation requests from notifications
/// to the home screen for proper scrolling and modal opening
///
/// Copied from [DeepLinkNotifier].
@ProviderFor(DeepLinkNotifier)
final deepLinkNotifierProvider =
    AutoDisposeNotifierProvider<DeepLinkNotifier, DeepLinkRequest?>.internal(
      DeepLinkNotifier.new,
      name: r'deepLinkNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$deepLinkNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DeepLinkNotifier = AutoDisposeNotifier<DeepLinkRequest?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
