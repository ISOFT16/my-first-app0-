import 'package:flutter/material.dart';

import 'app_state.dart';
import 'chat_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        title: 'Fox AI',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(foxLightScheme()),
        darkTheme: buildTheme(foxDarkScheme()),
        themeMode: state.themeMode,
        home: ChatScreen(state: state),
      ),
    );
  }
}
