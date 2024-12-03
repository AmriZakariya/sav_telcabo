import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telcabo/DemandeList.dart';
import 'package:telcabo/LoginWidget.dart';
import 'package:telcabo/Tools.dart';

class SplashPage extends StatefulWidget {
  final Color backgroundColor = Colors.white;
  final TextStyle styleTextUnderTheLoader = TextStyle(
      fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.black);

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  String versionNameString = 'V1.0.0';
  // final splashDelay = 3700;
  final splashDelay = 3500;

  @override
  void initState() {
    super.initState();

    _loadWidget();
  }

  _loadWidget() async {
    var _duration = Duration(milliseconds: splashDelay);
    return Timer(_duration, navigationPage);
  }

  void navigationPage() {
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (BuildContext context) => HomePage()));
    // Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => HomePageFuturBuilder()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Stack(
          children: [
            Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/bg_login.gif"),
                    fit: BoxFit.cover,
                  ),
                )),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Center(
                    child: FutureBuilder<String>(
                      future: getVersionName(), // a Future<String> or null
                      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                        switch (snapshot.connectionState) {
                          case ConnectionState.none: return new Text('Press button to start');
                          case ConnectionState.waiting: return new Text('Awaiting result...');
                          default:
                            if (snapshot.hasError)
                              return Container();
                            // return new Text('Error: ${snapshot.error}');
                            else
                              return Text(snapshot.data ?? "",
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black,
                                    backgroundColor: Colors.transparent,
                                  letterSpacing: 2
                                ),);
                        }
                      },
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );

    return Scaffold(
      body: InkWell(
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  flex: 7,
                  child: Container(
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Image.asset(
                        'assets/logo.png',
                        width: MediaQuery.of(context).size.width / 1.4,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                      ),
                      CircularProgressIndicator(),
                    ],
                  )),
                ),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      Container(
                        height: 20,
                      ),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                            Spacer(),
                            FutureBuilder<String>(
                              future: getVersionName(),
                              // a Future<String> or null
                              builder: (BuildContext context,
                                  AsyncSnapshot<String> snapshot) {
                                switch (snapshot.connectionState) {
                                  case ConnectionState.none:
                                    return new Text('Press button to start');
                                  case ConnectionState.waiting:
                                    return new Text('Awaiting result...');
                                  default:
                                    if (snapshot.hasError)
                                      return Container();
                                    // return new Text('Error: ${snapshot.error}');
                                    else
                                      return new Text(snapshot.data ?? "");
                                }
                              },
                            ),
                            Spacer(
                              flex: 4,
                            ),
                            Text('Telcabo'),
                            Spacer(),
                          ])
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<String> getVersionName() async {
    // String appName = "", packageName  = "", version  = "", buildNumber  = "";

    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    String appName = packageInfo.appName;
    String packageName = packageInfo.packageName;
    String version = packageInfo.version;
    String buildNumber = packageInfo.buildNumber;

    // return "${appName} ${packageName} ${version}  ${buildNumber}" ;
    return "V: ${version}  Build: ${buildNumber}";
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
        future: _checkLogin(),
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          print("snapshot ...");
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return Center(child: const CircularProgressIndicator());
            default:
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                if (snapshot.data == true) {
                  return DemandeList();
                } else {
                  return LoginForm();
                }
              }
          }
        });
  }

  Future<bool> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();

    Tools.userId = prefs.getString('userId') ?? "";
    Tools.userName = prefs.getString('userName') ?? "";
    Tools.userEmail = prefs.getString('userEmail') ?? "";

    return prefs.getBool('isOnline') ?? false;
  }
}
