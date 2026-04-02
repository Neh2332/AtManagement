import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/project_provider.dart';
import 'screens/onboarding_screen.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:at_client_mobile/at_client_mobile.dart';
import 'constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Base directory — each AtSign gets its own sub-folder so multiple
  // Windows instances can run side-by-side without Hive conflicts.
  final baseDir = await path_provider.getApplicationSupportDirectory();
  AtManagementApp.baseStoragePath = baseDir.path;

  runApp(const AtManagementApp());
}

class AtManagementApp extends StatelessWidget {
  const AtManagementApp({super.key});

  /// Set once in main(); each AtSign sub-folder is derived at onboarding time.
  static late String baseStoragePath;

  /// Global key to show snackbars from providers or background services
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Build a preference object for a specific AtSign so storage paths
  /// are unique per account (supports multiple simultaneous instances).
  static AtClientPreference preferencesFor(String atSign) {
    // Sanitise the AtSign for use as a directory name (strip the leading @)
    final safeName = atSign.startsWith('@') ? atSign.substring(1) : atSign;
    final dir = '$baseStoragePath\\$safeName';

    return AtClientPreference()
      ..rootDomain = atDirectoryHost
      ..namespace = appNamespace
      ..hiveStoragePath = dir
      ..commitLogPath = dir
      ..downloadPath = dir
      ..isLocalStoreRequired = true;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProjectProvider(),
      child: MaterialApp(
        title: 'AtManagement',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: scaffoldMessengerKey,
        theme: AppTheme.lightTheme,
        // Always start at onboarding — never auto-navigate to HomeScreen.
        home: const OnboardingScreen(),
      ),
    );
  }
}
