import 'dart:io';
import 'package:flutter/material.dart';
import 'data/database.dart';
import 'data/app_state.dart';
import 'data/preferences.dart';
import 'models/expense.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase().init();
  await appPrefs.init();
  await appState.loadAll();
  _checkRecurringTemplates();
  runApp(const XiaoZhangBenApp());
}

void _checkRecurringTemplates() {
  Future.microtask(() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayStr = today.toIso8601String().split('T').first;

    for (final t in appState.templates) {
      if (!t.isActive) continue;
      if (t.lastGenerated != null && t.lastGenerated == todayStr) continue;
      bool shouldGenerate = false;
      switch (t.cycle) {
        case 'daily': shouldGenerate = true; break;
        case 'weekly': shouldGenerate = now.weekday == t.cycleDay; break;
        case 'monthly':
          shouldGenerate = now.day == t.cycleDay ||
              (t.cycleDay > 28 && now.day == _lastDayOfMonth(now));
          break;
        case 'yearly':
          if (t.cycleDay > 0) shouldGenerate = now.month == t.cycleDay && now.day == 1;
          break;
      }
      if (shouldGenerate) {
        final expense = Expense(
          type: t.type, amount: t.amount, date: today,
          majorCategory: t.majorCategory, minorCategory: t.minorCategory,
          paymentMethod: t.paymentMethod, note: t.note,
          isRecurring: true, recurringId: t.id,
        );
        await appState.addExpense(expense);
        if (t.id != null) {
          await AppDatabase().updateTemplateLastGenerated(t.id!, todayStr);
        }
      }
    }
    await appState.loadAll();
  });
}

int _lastDayOfMonth(DateTime date) =>
    DateTime(date.year, date.month + 1, 0).day;

class XiaoZhangBenApp extends StatelessWidget {
  const XiaoZhangBenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '小账本',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F8FA).withOpacity(0.88),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.white.withOpacity(0.72),
          color: Colors.white.withOpacity(0.72),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.3), width: 0.5),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5),
          headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3),
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 16, letterSpacing: -0.2),
          bodyMedium: TextStyle(fontSize: 14, letterSpacing: -0.2),
          bodySmall: TextStyle(fontSize: 12, letterSpacing: -0.1),
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 0,
          backgroundColor: Colors.white.withOpacity(0.72),
          indicatorColor: const Color(0xFF2E7D32).withOpacity(0.12),
          surfaceTintColor: Colors.transparent,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 64,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212).withOpacity(0.88),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white.withOpacity(0.06),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.06), width: 0.5),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 0,
          height: 64,
          backgroundColor: const Color(0xFF121212).withOpacity(0.72),
          indicatorColor: const Color(0xFF4CAF50).withOpacity(0.15),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = const [
    HomeScreen(), HistoryScreen(), StatisticsScreen(), SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: appPrefs,
      builder: (context, _) {
        return Stack(
          children: [
            // 全局背景（所有标签页共享）
            _buildGlobalBackground(theme),
            // 主界面
            Scaffold(
              backgroundColor: Colors.transparent,
              body: IndexedStack(index: _currentIndex, children: _screens),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (i) => setState(() => _currentIndex = i),
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '首页'),
                  NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: '明细'),
                  NavigationDestination(icon: Icon(Icons.pie_chart_outline), selectedIcon: Icon(Icons.pie_chart), label: '统计'),
                  NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '我的'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGlobalBackground(ThemeData theme) {
    final bgPath = appPrefs.bgImagePath;
    if (bgPath != null && File(bgPath).existsSync()) {
      return Positioned.fill(
        child: Opacity(
          opacity: appPrefs.bgOpacity,
          child: Image.file(File(bgPath), fit: BoxFit.cover),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
