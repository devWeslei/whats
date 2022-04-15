import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:whatsapp/Login.dart';
import 'RouteGenerator.dart';
import 'dart:io';

final ThemeData temaPadrao = ThemeData(
  colorScheme: ColorScheme.fromSwatch().copyWith(
    primary: const Color(0xff075E54),
    secondary: const Color(0xff25D366),
  ),
);

final ThemeData temaIOS = ThemeData(
  colorScheme: ColorScheme.fromSwatch().copyWith(
    primary: const Color(0xff075E54),
    secondary: const Color(0xff25D366),
  ),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MaterialApp(
    theme: Platform.isIOS ? temaIOS : temaPadrao,
    home: Login(),
    initialRoute: RouteGenerator.ROTA_LOGIN,
    onGenerateRoute: RouteGenerator.generateRoute,
    debugShowCheckedModeBanner: false,
  ));
}
