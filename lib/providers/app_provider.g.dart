// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Main app provider managing theme and user state

@ProviderFor(App)
final appProvider = AppProvider._();

/// Main app provider managing theme and user state
final class AppProvider extends $NotifierProvider<App, AppState> {
  /// Main app provider managing theme and user state
  AppProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'appProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$appHash();

  @$internal
  @override
  App create() => App();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppState>(value),
    );
  }
}

String _$appHash() => r'9141d5d46c7169c43e6e70b24e203ab47127b1a5';

/// Main app provider managing theme and user state

abstract class _$App extends $Notifier<AppState> {
  AppState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AppState, AppState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AppState, AppState>, AppState, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
