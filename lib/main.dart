import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'chat_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  final state = AppState();
  await state.load();
  runApp(FoxAiApp(state: state));
}

class FoxAiApp extends StatelessWidget {
  const FoxAiApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => MaterialApp(
        title: 'Vigil AI',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(vigilScheme()),
        darkTheme: buildTheme(vigilScheme()),
        themeMode: ThemeMode.dark,
        home: ChatScreen(state: state),
      ),
    );
  }
}
