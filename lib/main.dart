import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kos_gdgoc/core/router/app_router.dart';
import 'package:kos_gdgoc/core/theme/app_theme.dart';
import 'package:kos_gdgoc/features/explore/data/discover_provider.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const ProviderScope(child: App()),
    ),
  );
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Warm the explore cache early so the first open feels instant.
    ref.read(exploreListingsProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'KosCheck',
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
