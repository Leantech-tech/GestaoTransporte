import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'services/api_data_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ApiDataService>(
          create: (context) => ApiDataService(context.read<AuthProvider>().apiClient),
          update: (context, auth, previous) {
            final service = previous ?? ApiDataService(auth.apiClient);
            service.usuarioLogado = auth.usuario;
            return service;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Gestão de Transporte',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const LoginScreen(),
      ),
    );
  }
}
