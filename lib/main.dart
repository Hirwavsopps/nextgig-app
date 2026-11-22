import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:nextgig/app.dart';
import 'package:nextgig/core/di/injection.dart';
import 'package:nextgig/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await configureDependencies();

  runApp(const NextGigApp());
}
