import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'data/network/network_data_source.dart';
import 'data/network/network_repository_impl.dart';
import 'domain/usecases/run_network_diagnostic.dart';
import 'presentation/providers/network_diagnostic_provider.dart';
import 'presentation/providers/local_chat_provider.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AppState appState = AppState();

  await appState.loadSavedData();

  runApp(
    PortfolioApp(
      appState: appState,
    ),
  );
}

class PortfolioApp extends StatelessWidget {
  final AppState appState;

  const PortfolioApp({
    super.key,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Existing global application state
        ChangeNotifierProvider.value(
          value: appState,
        ),

        // Network Diagnostic global state
        ChangeNotifierProvider(
          create: (_) {
            final dataSource = NetworkDataSource(
              connectivity: Connectivity(),
            );

            final repository = NetworkRepositoryImpl(
              dataSource: dataSource,
            );

            final useCase = RunNetworkDiagnostic(
              repository: repository,
            );

            final provider = NetworkDiagnosticProvider(
              runNetworkDiagnostic: useCase,
            );

            // --------------------------------------------------
            // Restore previous diagnostic automatically.
            //
            // If a diagnostic was already completed before
            // closing the app, the provider will:
            //
            // 1. Restore the saved values.
            // 2. Restore progress to 100%.
            // 3. Automatically start live monitoring.
            // --------------------------------------------------

            provider.initialize();

            return provider;
          },
        ),

        // Activity 4 - Local Mesh Chat global state
        ChangeNotifierProvider(
          create: (_) => LocalChatProvider(),
        ),
      ],
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          return MaterialApp(
            title: 'Flutter Portfolio',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: appState.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            initialRoute: AppRoutes.dashboard,
            onGenerateRoute: AppRoutes.onGenerateRoute,
          );
        },
      ),
    );
  }
}