import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_theme.dart';
import 'core/routing/app_router.dart';
import 'features/auth/presentation/auth_controller.dart';

// This container is made global to be accessible by the AuthInterceptor.
final providerContainer = ProviderContainer();

Future<void> main() async {
  // Required for async operations before runApp()
  WidgetsFlutterBinding.ensureInitialized();
  
  // This crucial line initializes the AuthController and waits for the
  // auto-login check to complete before the app starts.
  await providerContainer.read(authControllerProvider.future);
  
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
    );
  }
}