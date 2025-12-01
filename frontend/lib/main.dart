import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routes.dart';
import 'theme.dart';
import 'services/auth_service.dart';
import 'services/background_location_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background location service
  await BackgroundLocationService.initialize();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final bool skipAuthInit;
  const MyApp({super.key, this.skipAuthInit = false});

  @override
  Widget build(BuildContext context) {
    if (skipAuthInit) {
      return ChangeNotifierProvider(
        create: (_) => AuthService(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: "Tracking App",
          theme: AppTheme.lightTheme,
          initialRoute: "/admin-login",
          routes: appRoutes,
        ),
      );
    }
    return FutureBuilder<AuthService>(
      future: AuthService.create(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        return ChangeNotifierProvider.value(
          value: snapshot.data,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: "Tracking App",
            theme: AppTheme.lightTheme,
            initialRoute: "/admin-login",
            routes: appRoutes,
          ),
        );
      },
    );
  }
}
