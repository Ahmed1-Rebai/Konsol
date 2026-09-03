import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konsol/data/models/host.dart';
import 'package:konsol/data/repositories/key_repository.dart';

/// Thrown when connection/authentication fails so the UI can surface the reason.
class SshConnectionException implements Exception {
  final String message;
  const SshConnectionException(this.message);

  @override
  String toString() => message;
}

/// A live remote terminal: raw byte streams in both directions.
class SshSessionHandle {
  final SSHSession session;
  final SSHClient client;

  SshSessionHandle(this.session, this.client);

  Future<void> get done => session.done;

  Stream<List<int>> get stdout => session.stdout;

  Stream<List<int>> get stderr => session.stderr;

  void resize(int cols, int rows) => session.resizeTerminal(cols, rows);

  Future<void> write(List<int> data) async {
    session.stdin.add(Uint8List.fromList(data));
  }

  /// Runs [command] non-interactively on a side channel of the same
  /// connection, leaving the user's shell session untouched.
  Future<String> runCommand(String command) async {
    final result = await client.run(command, stderr: false);
    return utf8.decode(result, allowMalformed: true);
  }

  Future<void> close() async {
    session.close();
    await client.close();
  }
}

/// Connects to a host and opens an interactive PTY shell.
class SshService {
  const SshService();

  /// [password] is required for `password` auth; [keyId] for `key` auth.
  Future<SshSessionHandle> connect(
    Host host, {
    required String? password,
    String? keyId,
    KeyRepository? keyRepository,
    int width = 80,
    int height = 24,
  }) async {
    final SSHSocket socket;
    try {
      socket = await SSHSocket.connect(
        host.address,
        host.port,
        timeout: const Duration(seconds: 10),
      );
    } on SocketException catch (e) {
      throw SshConnectionException(
        'Could not reach ${host.address}:${host.port} (${e.message})',
      );
    }

    SSHIdentity? identity;
    if (host.authMethod == 'key') {
      if (keyId == null || keyRepository == null) {
        throw const SshConnectionException(
          'Key-based auth requested but no key is selected.',
        );
      }
      identity = await keyRepository.identityFor(keyId);
    }

    final client = SSHClient(
      socket,
      username: host.username,
      disableHostkeyVerification: true,
      onPasswordRequest: () => _passwordRequest(password),
      identities: identity != null ? [identity] : null,
      handshakeTimeout: const Duration(seconds: 15),
      authTimeout: const Duration(seconds: 15),
    );

    SSHSession session;
    try {
      session = await client.shell(
        pty: SSHPtyConfig(
          type: 'xterm-256color',
          width: width,
          height: height,
        ),
      );
    } catch (e) {
      await client.close();
      rethrow;
    }

    return SshSessionHandle(session, client);
  }

  String? _passwordRequest(String? password) {
    if (password == null || password.isEmpty) {
      throw const SshConnectionException(
        'The server requested a password but none is saved. '
        'Edit the host to set one.',
      );
    }
    return password;
  }
}

final sshServiceProvider = Provider<SshService>((ref) {
  return const SshService();
});
