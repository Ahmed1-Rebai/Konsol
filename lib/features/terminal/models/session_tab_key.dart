/// Uniquely identifies an open terminal tab/session.
///
/// Allows multiple concurrent sessions against the same host by varying
/// [instance], while still being usable as a Riverpod family key.
class SessionTabKey {
  final String hostId;
  final int instance;

  const SessionTabKey({required this.hostId, this.instance = 0});

  String get cacheKey => '$hostId::$instance';

  @override
  bool operator ==(Object other) =>
      other is SessionTabKey &&
      other.hostId == hostId &&
      other.instance == instance;

  @override
  int get hashCode => Object.hash(hostId, instance);

  @override
  String toString() => 'SessionTabKey($hostId, $instance)';
}
