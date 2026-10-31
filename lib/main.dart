import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'core/hive/hive_setup.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_colors.dart';
import 'core/utils/notification_service.dart';
import 'core/utils/widget_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// FutureProvider that manages asynchronous app initialization.
final appInitializationProvider = FutureProvider<void>((ref) async {
  // System UI Config
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF000000),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Hive initialization
  await HiveSetup.initialize();

  // Notifications initialization
  try {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Initialize Notification Service (timezone database + daily fixed reminders)
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('Local notifications initialization failed: $e');
  }

  // Initialize WidgetService + push fresh data to home screen widget
  try {
    await WidgetService.initialize();
    await WidgetService.updateWidget();
  } catch (e) {
    debugPrint('WidgetService initialization failed: $e');
  }

  // Prefetch Google Fonts (offline-friendly fallback)
  GoogleFonts.config.allowRuntimeFetching = true;
});

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: HabitFlowApp(),
    ),
  );
}

class HabitFlowApp extends ConsumerWidget {
  const HabitFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initAsync = ref.watch(appInitializationProvider);

    return initAsync.when(
      data: (_) {
        final router = ref.watch(appRouterProvider);
        WidgetService.setupClickListener((path) {
          router.go(path);
        });

        return MaterialApp.router(
          title: 'HabitFlow',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          routerConfig: router,
          builder: (context, child) {
            if (child == null) return const SizedBox.shrink();

            // On mobile devices (screen width <= 600), run without any container constraints
            if (MediaQuery.of(context).size.width <= 600) {
              return child;
            }

            // On desktop/tablets, center the layout inside a 600px column
            return Scaffold(
              backgroundColor: Colors.black, // true black background on desktop borders
              body: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  decoration: const BoxDecoration(
                    border: Border.symmetric(
                      vertical: BorderSide(color: AppColors.border, width: 0.5),
                    ),
                  ),
                  child: child,
                ),
              ),
            );
          },
        );
      },
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: CircularProgressIndicator(
              color: AppColors.accent,
              strokeWidth: 3,
            ),
          ),
        ),
      ),
      error: (err, stack) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Failed to launch app: $err',
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
