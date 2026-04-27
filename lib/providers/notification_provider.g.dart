// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NotificationNotifier)
final notificationProvider = NotificationNotifierProvider._();

final class NotificationNotifierProvider
    extends $NotifierProvider<NotificationNotifier, NotificationState> {
  NotificationNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'notificationProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$notificationNotifierHash();

  @$internal
  @override
  NotificationNotifier create() => NotificationNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationState>(value),
    );
  }
}

String _$notificationNotifierHash() =>
    r'c224f933c6a95af4c05699af0cb9fe74c2000473';

abstract class _$NotificationNotifier extends $Notifier<NotificationState> {
  NotificationState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<NotificationState, NotificationState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<NotificationState, NotificationState>,
        NotificationState,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
