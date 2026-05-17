import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kos_gdgoc/features/analysis/presentation/pages/analysis_result_page.dart';
import 'package:kos_gdgoc/features/analysis/presentation/pages/analyzing_page.dart';
import 'package:kos_gdgoc/features/analysis/presentation/pages/chat_template_page.dart';
import 'package:kos_gdgoc/features/analysis/presentation/pages/basic_info_page.dart';
import 'package:kos_gdgoc/features/analysis/presentation/pages/deep_check_page.dart';
import 'package:kos_gdgoc/features/analysis/presentation/pages/overview_page.dart';
import 'package:kos_gdgoc/features/analysis/presentation/pages/quick_check_page.dart';
import 'package:kos_gdgoc/features/history/presentation/pages/history_detail_page.dart';
import 'package:kos_gdgoc/features/history/presentation/pages/history_page.dart';
import 'package:kos_gdgoc/features/home/presentation/pages/home_page.dart';
import 'package:kos_gdgoc/features/home/presentation/pages/landing_page.dart';
import 'package:kos_gdgoc/core/theme/app_theme.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) =>
            _ScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(
            path: '/',
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/history',
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => const HistoryPage(),
          ),
          GoRoute(
            path: '/education',
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => const LandingPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/history/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => HistoryDetailPage(
          id: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/analyze',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BasicInfoPage(),
        routes: [
          GoRoute(
            path: 'quick',
            builder: (context, state) => const QuickCheckPage(),
          ),
          GoRoute(
            path: 'deep',
            builder: (context, state) => const DeepCheckPage(),
          ),
          GoRoute(
            path: 'overview',
            builder: (context, state) => const OverviewPage(),
          ),
          GoRoute(
            path: 'result',
            builder: (context, state) => const AnalysisResultPage(),
          ),
          GoRoute(
            path: 'loading',
            builder: (context, state) => const AnalyzingPage(),
          ),
          GoRoute(
            path: 'chat',
            builder: (context, state) => const ChatTemplatePage(),
          ),
          GoRoute(
            path: 'quick-edit',
            builder: (context, state) => const QuickCheckPage(isEditMode: true),
          ),
        ],
      ),
    ],
  );
}

class _ScaffoldWithNavBar extends StatelessWidget {
  const _ScaffoldWithNavBar({required this.child});
  final Widget child;

  static int _indexOf(String location) {
    if (location.startsWith('/history')) return 1;
    if (location.startsWith('/education')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location =
        GoRouterState.of(context).uri.toString();
    final idx = _indexOf(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withOpacity(0.12),
        selectedIndex: idx,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/');
            case 1:
              context.go('/history');
            case 2:
              context.go('/education');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.primary),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: AppColors.primary),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book, color: AppColors.primary),
            label: 'Edukasi',
          ),
        ],
      ),
    );
  }
}
