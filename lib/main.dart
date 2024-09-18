import 'package:flutter/material.dart';
import 'package:flutter_154620/routes.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() {
  usePathUrlStrategy();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: routes.first,
      routes: {
        for (var i = 0; i < routes.length; i++)
          routes[i]: (_) =>
              HomePage(destination: routes[(i + 1) % routes.length]),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({required this.destination});

  final String destination;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () {
            Navigator.of(context).pushNamed(destination);
          },
          child: Text('Next: `$destination`'),
        ),
      ),
    );
  }
}
