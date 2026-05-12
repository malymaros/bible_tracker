import 'package:bible_tracker/features/bible/screens/biblia_screen.dart';
import 'package:bible_tracker/features/bible/screens/reader_screen.dart';
import 'package:bible_tracker/features/plan/screens/plan_screen.dart';
import 'package:bible_tracker/features/statistics/screens/statistika_screen.dart';
import 'package:bible_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final _bibliaKey = GlobalKey<NavigatorState>(debugLabel: 'biblia');
final _planKey = GlobalKey<NavigatorState>(debugLabel: 'plan');
final _statistikaKey = GlobalKey<NavigatorState>(debugLabel: 'statistika');

final appRouter = GoRouter(
  initialLocation: '/biblia',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _AppShell(shell: shell),
      branches: [
        StatefulShellBranch(
          navigatorKey: _bibliaKey,
          routes: [
            GoRoute(
              path: '/biblia',
              builder: (_, _) => const BibliaScreen(),
              routes: [
                GoRoute(
                  path: 'reader/:bookId/:chapter',
                  builder: (_, state) => ReaderScreen(
                    bookId: state.pathParameters['bookId']!,
                    chapterNumber: int.parse(state.pathParameters['chapter']!),
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _planKey,
          routes: [
            GoRoute(path: '/plan', builder: (_, _) => const PlanScreen()),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _statistikaKey,
          routes: [
            GoRoute(
              path: '/statistika',
              builder: (_, _) => const StatistikaScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

class _AppShell extends StatelessWidget {
  final StatefulNavigationShell shell;

  const _AppShell({required this.shell});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (index) => shell.goBranch(
          index,
          // Tapping the active tab again returns to its root screen.
          initialLocation: index == shell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book),
            label: l10n.tabBiblia,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bookmark_border),
            selectedIcon: const Icon(Icons.bookmark),
            label: l10n.tabPlan,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: l10n.tabStatistika,
          ),
        ],
      ),
    );
  }
}
