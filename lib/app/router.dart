import 'package:bible_tracker/core/models/reader_context.dart';
import 'package:bible_tracker/features/bible/screens/biblia_screen.dart';
import 'package:bible_tracker/features/bible/screens/reader_screen.dart';
import 'package:bible_tracker/features/plan/screens/plan_screen.dart';
import 'package:bible_tracker/features/statistics/screens/statistika_screen.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/plan',
  routes: [
    GoRoute(path: '/plan', builder: (_, _) => const PlanScreen()),
    GoRoute(
      path: '/books',
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
    GoRoute(path: '/statistics', builder: (_, _) => const StatistikaScreen()),
    GoRoute(
      path: '/plan/reader/:bookId/:chapter',
      builder: (_, state) => ReaderScreen(
        bookId: state.pathParameters['bookId']!,
        chapterNumber: int.parse(state.pathParameters['chapter']!),
        readerContext: ReaderContext.plan,
      ),
    ),
  ],
);
