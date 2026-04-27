// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'navigation_shell.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NavigationIndex)
final navigationIndexProvider = NavigationIndexProvider._();

final class NavigationIndexProvider
    extends $NotifierProvider<NavigationIndex, int> {
  NavigationIndexProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'navigationIndexProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$navigationIndexHash();

  @$internal
  @override
  NavigationIndex create() => NavigationIndex();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$navigationIndexHash() => r'd414893e1ca6a80fb2253812d81d3fbffa99ea74';

abstract class _$NavigationIndex extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element = ref.element
        as $ClassProviderElement<AnyNotifier<int, int>, int, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
