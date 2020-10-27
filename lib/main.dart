import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import 'pages/home_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // final routes = <String, WidgetBuilder>{
  //   LoginPage.tag: (context) => LoginPage(),
  //   HomePage.tag: (context) => HomePage(),
  // };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'plexmusic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.amber,
        fontFamily: 'Nunito',
      ),
      home: AudioServiceWidget(child: HomePage()),
      // routes: routes,
    );
  }
}
