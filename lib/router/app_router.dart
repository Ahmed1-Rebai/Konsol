import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:konsol/features/hosts/screens/host_list_screen.dart';
import 'package:konsol/features/hosts/screens/add_edit_host_screen.dart';
import 'package:konsol/features/keys/screens/key_manager_screen.dart';
import 'package:konsol/features/settings/screens/settings_screen.dart';
import 'package:konsol/features/terminal/screens/session_host_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        name: 'hosts',
        builder: (context, state) => const HostListScreen(),
        routes: [
          GoRoute(
            path: 'add',
            name: 'add-host',
            builder: (context, state) => const AddEditHostScreen(),
          ),
          GoRoute(
            path: 'edit/:id',
            name: 'edit-host',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return AddEditHostScreen(hostId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/terminal/:id',
        name: 'terminal',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return SessionHostScreen(initialHostId: id);
        },
      ),
      GoRoute(
        path: '/keys',
        name: 'keys',
        builder: (context, state) => const KeyManagerScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
