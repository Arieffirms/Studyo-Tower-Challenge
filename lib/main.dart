import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'src/core/routes/app_pages.dart';
import 'src/core/routes/app_routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Kita gunakan GetMaterialApp, BUKAN MaterialApp standar
    return GetMaterialApp(
      title: 'Tower Challenge',
      theme: ThemeData(
        brightness: Brightness.dark, // Cocok dengan tampilan Flame hitam/gelap
        primarySwatch: Colors.blue,
      ),
      initialRoute: Routes.LOBBY, // Menggunakan Class Routes
      getPages: AppPages.pages,   // Menggunakan list yang sudah dipisah
    );
  }
}
