import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telcabo/DemandeList.dart';
import 'package:telcabo/Tools.dart';
import 'package:telcabo/ui/LoadingDialog.dart';

class LoginFormBloc extends FormBloc<String, String> {
  final loginTextFieldBloc = TextFieldBloc(
    // initialValue: !kReleaseMode ?  "Admin" : "",
    initialValue: !kReleaseMode ?  "0619993849" : "",
    validators: [
      FieldBlocValidators.required,
      // FieldBlocValidators.email,
    ],
  );

  final passwordTextFieldBloc = TextFieldBloc(
    initialValue: !kReleaseMode ?  "aa" : "",
    validators: [
      FieldBlocValidators.required,
    ],
  );

  final rememberMeBoolenFieldBloc = BooleanFieldBloc();

  // final stayConnectedFieldBloc = BooleanFieldBloc();

  LoginFormBloc() : super(isLoading: true) {
    addFieldBlocs(
      fieldBlocs: [
        loginTextFieldBloc,
        passwordTextFieldBloc,
        rememberMeBoolenFieldBloc,
        // stayConnectedFieldBloc,
      ],
    );
  }

  @override
  void onLoading() async {
    print("LoginWidget onLoading");

    final prefs = await SharedPreferences.getInstance();

    if (prefs.getBool('rememberMe') ?? false) {
      rememberMeBoolenFieldBloc.updateValue(true);
      loginTextFieldBloc.updateValue(prefs.getString('userEmail') ?? "");
    }

    emitLoaded();
  }

  @override
  void onSubmitting() async {
    print(loginTextFieldBloc.value);
    print(passwordTextFieldBloc.value);
    print(rememberMeBoolenFieldBloc.value);
    // print(stayConnectedFieldBloc.value);

    Map<String, dynamic> loginMap = {
      "username": loginTextFieldBloc.value,
      "password": passwordTextFieldBloc.value
    };

    try {
      var callWsLogin = await Tools.callWsLogin(loginMap);

      if (callWsLogin) {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setBool('rememberMe', rememberMeBoolenFieldBloc.value);

        emitSuccess();
      } else {
        emitFailure(failureResponse: 'login ou mot de passe incorrect!');
      }
    } catch (e) {
      print("exception login ${e}");
      emitFailure(failureResponse: "Erreur de connexion au serveur");
      // emitFailure(failureResponse: "eeee");
    }
  }
}

class LoginForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginFormBloc(),
      child: Builder(
        builder: (context) {
          final loginFormBloc = context.read<LoginFormBloc>();

          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: Stack(
                children: [
                  Container(
                    decoration: new BoxDecoration(
                      image: new DecorationImage(
                        image: new ExactAssetImage('assets/bg_home.jpeg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: new BackdropFilter(
                      filter: new ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                      child: new Container(
                        decoration: new BoxDecoration(
                            color: Colors.white.withOpacity(0.0)),
                      ),
                    ),
                  ),
                  FormBlocListener<LoginFormBloc, String, String>(
                    onSubmitting: (context, state) {
                      LoadingDialog.show(context);
                    },
                    onSubmissionFailed: (context, state) {
                      LoadingDialog.hide(context);
                    },
                    onSubmissionCancelled: (context, state) {
                      LoadingDialog.hide(context);
                    },
                    onSuccess: (context, state) {
                      LoadingDialog.hide(context);

                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (_) => DemandeList(),
                        ));

                      // SchedulerBinding.instance.addPostFrameCallback((_) {
                      //   Navigator.of(context).pushReplacement(MaterialPageRoute(
                      //     builder: (_) => DemandeList(),
                      //   ));
                      // });
                    },
                    onFailure: (context, state) {
                      LoadingDialog.hide(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(state.failureResponse!)));
                    },
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12.0),
                        physics: ClampingScrollPhysics(),
                        child: AutofillGroup(
                          child: Column(
                            children: <Widget>[
                              Container(
                                  child: Image(
                                image: AssetImage('assets/logo.png'),
                                width: MediaQuery.of(context).size.width / 1.8,
                              )),
                              SizedBox(
                                height: 30,
                              ),
                              TextFieldBlocBuilder(
                                textFieldBloc: loginFormBloc.loginTextFieldBloc,
                                keyboardType: TextInputType.text,
                                autofillHints: [
                                  AutofillHints.username,
                                ],
                                decoration: InputDecoration(
                                  labelText: 'Login',
                                  prefixIcon: Icon(Icons.person),
                                ),
                              ),
                              TextFieldBlocBuilder(
                                textFieldBloc:
                                    loginFormBloc.passwordTextFieldBloc,
                                suffixButton: SuffixButton.obscureText,
                                autofillHints: [AutofillHints.password],
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 250,
                                    child: CheckboxFieldBlocBuilder(
                                      alignment: AlignmentDirectional.center,
                                      booleanFieldBloc:
                                          loginFormBloc.rememberMeBoolenFieldBloc,
                                      body: Container(
                                        alignment: Alignment.centerLeft,
                                        child: Text('Se souvenir de moi',
                                        style: TextStyle(
                                          fontFamily: "Roboto"
                                        ),),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 40,
                              ),

                              ElevatedButton(
                                onPressed: () async {
                                  loginFormBloc.submit();
                                },
                                // icon: Icon(Icons.login),
                                child: Text("Se connecter".toUpperCase()),
                                style: ElevatedButton.styleFrom(
                                  // shape: CircleBorder(),
                                  minimumSize: Size(280, 50),
                                  // primary: Tools.colorPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        new BorderRadius.circular(5.0),
                                  ),
                                ),
                              ),
                              // SizedBox(height: 15,),
                              // Divider(color: Colors.black, height: 2,),
                              //
                              // Container(
                              //   alignment: Alignment.centerLeft,
                              //   child: CheckboxFieldBlocBuilder(
                              //     booleanFieldBloc: loginFormBloc.rememberMeBoolenFieldBloc,
                              //     body: Container(
                              //       alignment: Alignment.centerLeft,
                              //       child: Text('Rester connecté'),
                              //     ),
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Center(
                  //   child: SingleChildScrollView(
                  //     child: Column(
                  //       mainAxisAlignment: MainAxisAlignment.center,
                  //       crossAxisAlignment: CrossAxisAlignment.center,
                  //       children: [
                  //         // SizedBox(height: MediaQuery.of(context).size.height / 4,),
                  //         Container(
                  //             child: Image(image: AssetImage('assets/logo.png'), width: MediaQuery.of(context).size.width / 1.7,)
                  //         ),
                  //         SizedBox(height: 40,),
                  //         Container(
                  //           margin: EdgeInsets.only(left: 35, right: 35),
                  //           child: Column(
                  //             children: [
                  //               TextField(
                  //                 style: TextStyle(color: Colors.black),
                  //                 controller: _emailController,
                  //                 decoration: InputDecoration(
                  //                     prefixIcon: Icon(Icons.person),
                  //                     fillColor: Colors.grey.shade100,
                  //                     filled: true,
                  //                     hintText: "Login",
                  //                     border: OutlineInputBorder(
                  //                       borderRadius: BorderRadius.circular(15),
                  //                     )),
                  //               ),
                  //               SizedBox(
                  //                 height: 15,
                  //               ),
                  //               TextField(
                  //                 style: TextStyle(),
                  //                 controller: _passwordController,
                  //                 obscureText: true,
                  //                 decoration: InputDecoration(
                  //                     prefixIcon: Icon(Icons.key),
                  //                     fillColor: Colors.grey.shade100,
                  //                     filled: true,
                  //                     hintText: "Password",
                  //                     border: OutlineInputBorder(
                  //                       borderRadius: BorderRadius.circular(15),
                  //                     )),
                  //               ),
                  //               SizedBox(
                  //                 height: 40,
                  //               ),
                  //
                  //               ElevatedButton(
                  //                 onPressed: () async {
                  //                   Map<String, dynamic> loginMap = {
                  //                     "username" : _emailController.value.text,
                  //                     "password" : _passwordController.value.text
                  //                   };
                  //
                  //
                  //                   LoadingDialog.show(context);
                  //
                  //                   var callWsLogin = await Tools.callWsLogin(loginMap) ;
                  //
                  //                   LoadingDialog.hide(context);
                  //
                  //                   if(callWsLogin){
                  //
                  //                     SchedulerBinding.instance?.addPostFrameCallback((_) {
                  //                       Navigator.of(context).pushReplacement(MaterialPageRoute(
                  //                         builder: (_) => DemandeList(),
                  //                       ));
                  //                     });
                  //
                  //                   };
                  //                 },
                  //                 child: const Text(
                  //                   'Se Connecter',
                  //                   textAlign: TextAlign.center,
                  //                   style: TextStyle(
                  //                       fontSize: 18.0,
                  //                       letterSpacing: 2
                  //                   ),
                  //                 ),
                  //                 style: ElevatedButton.styleFrom(
                  //                   // shape: CircleBorder(),
                  //                   primary: Tools.colorPrimary,
                  //                   minimumSize: Size(280, 60),
                  //                   // primary: Tools.colorPrimary,
                  //                   shape: RoundedRectangleBorder(
                  //                     borderRadius: new BorderRadius.circular(15.0),
                  //                   ),
                  //                 ),
                  //               ),
                  //
                  //             ],
                  //           ),
                  //         )
                  //       ],
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
