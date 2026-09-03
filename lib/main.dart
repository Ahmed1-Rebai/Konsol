import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:konsol/core/theme/app_theme.dart';
import 'package:konsol/data/models/host_adapter.dart';
import 'package:konsol/data/models/ssh_key_adapter.dart';
import 'package:konsol/data/providers/providers.dart';
import 'package:konsol/data/repositories/host_repository.dart';
import 'package:konsol/data/repositories/key_repository.dart';
import 'package:konsol/data/repositories/secure_storage.dart';
import 'package:konsol/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(HostAdapter());
  Hive.registerAdapter(SSHKeyAdapter());

  await Hive.openBox('settings');
  final secure = SecureStorageService();
  final hostRepo = HostRepository();
  await hostRepo.init();
  final keyRepo = KeyRepository(secure);
  await keyRepo.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        hostRepositoryProvider.overrideWithValue(hostRepo),
        keyRepositoryProvider.overrideWithValue(keyRepo),
      ],
      child: const KonsolApp(),
    ),
  );
}

class KonsolApp extends ConsumerWidget {
  const KonsolApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(
      settingsProvider.select((s) => s['themeMode']),
    );

    return MaterialApp.router(
      title: 'Konsol',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode == 'light'
          ? ThemeMode.light
          : themeMode == 'dark'
              ? ThemeMode.dark
              : ThemeMode.system,
      routerConfig: router,
    );
  }
}
