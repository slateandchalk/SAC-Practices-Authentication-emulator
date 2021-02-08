import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' show Platform;
import 'package:sac_practices/flim_list.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sac_practices/signin_page.dart';

// ignore: non_constant_identifier_names
bool USE_EMULATORS = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  String host = '';
  String authHost = '';
  String ip = '10.1.81.182';

  if(kIsWeb){
    host = '$ip:8080';
    authHost = 'http://$ip:9099';
  } else if(Platform.isAndroid){
    host = '10.0.2.2:8080';
    authHost = 'http://10.0.2.2:9099';
  } else if(Platform.isIOS){
    host = '$ip:8080';
    authHost = 'http://$ip:9099';
  }

  if(USE_EMULATORS){
    FirebaseFirestore.instance.settings = Settings(
      host: host, sslEnabled: false
    );

    FirebaseAuth.instance.useEmulator(authHost);
  }

  runApp(SacPracticesApp());
}

class SacPracticesApp extends StatelessWidget {
  
  MaterialApp withMaterialApp(Widget body){
    return MaterialApp(
      title: 'SAC Practices App',
      theme: ThemeData.dark(),
      home: Scaffold(
        body: body,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return withMaterialApp(Center(child: SplashPage()));
  }
}

class SplashPage extends StatefulWidget {
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool isLoggedin;

  @override
  void initState() {
    isLoggedin = false;
    FirebaseAuth.instance.authStateChanges().listen((User user) {
      if(user != null){
        setState(() {
          isLoggedin = true;
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return isLoggedin ? new FilmList() : new SigninPage();
  }
}




