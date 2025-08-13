import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'providers/theme_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/ratings_provider.dart';
import 'themes/app_themes.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('pt')],
      path: 'assets/translations',
      fallbackLocale: const Locale('pt'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ThemeProvider()),
          ChangeNotifierProvider(create: (context) => FavoritesProvider()),
          ChangeNotifierProvider(create: (context) => RatingsProvider()),
        ],
        child: const MainApp(),
      ),
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
    // Carrega dados salvos quando o app inicia
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesProvider>().loadFavorites();
      context.read<RatingsProvider>().loadRatings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final seed = themeProvider.seedColor;
        return MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          title: 'app_name'.tr(),
          theme: AppThemes.light(seed),
            darkTheme: AppThemes.dark(seed),
          themeMode: themeProvider.themeMode,
          home: const HomeScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}