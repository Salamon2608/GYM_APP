import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management/core/router/app_router.dart';
import 'package:gym_management/core/services/api_service.dart';
import 'package:gym_management/core/theme/app_theme.dart';
import 'package:gym_management/features/shared/presentation/connectivity_banner_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize ApiService
  ApiService.initialize();

  runApp(const ProviderScope(child: GymManagementApp()));
}

class GymManagementApp extends ConsumerWidget {
  const GymManagementApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'TRACEFIT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      builder: (context, child) {
        return ConnectivityBannerWrapper(child: child!);
      },
    );
  }
}
