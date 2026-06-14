import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'core/config/app_theme.dart';
import 'core/routing/app_router.dart';

// This container is made global to be accessible by the AuthInterceptor.
final providerContainer = ProviderContainer();

Future<void> main() async {
  // Required for async operations before runApp()
  WidgetsFlutterBinding.ensureInitialized();

  // Load the IANA timezone database so attendance punch times can be rendered
  // in the school's timezone regardless of the device's clock/timezone.
  tz.initializeTimeZones();
  
  // NOTE: We no longer await authControllerProvider here.
  // The SplashScreen handles the auth initialization and shows a branded
  // loading screen instead of a blank white screen.
  
  runApp(
    UncontrolledProviderScope(
      container: providerContainer,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Staff PWS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
      ],
    );
  }
}