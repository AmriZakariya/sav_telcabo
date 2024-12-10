import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cool_alert/cool_alert.dart';
// import 'package:dartx/dartx.dart';
import 'package:dio/dio.dart';
import 'package:dio_logger/dio_logger.dart';
import 'package:floating_action_bubble/floating_action_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:flutter_social_share_plugin/flutter_social_share.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:telcabo/Tools.dart';
import 'package:telcabo/ToolsExtra.dart';
import 'package:telcabo/custome/ConnectivityCheckBlocBuilder.dart';
import 'package:telcabo/models/response_get_liste_pannes.dart';
import 'package:telcabo/ui/InterventionHeaderInfoWidget.dart';
import 'package:telcabo/ui/LoadingDialog.dart';
import 'package:timelines/timelines.dart';

final GlobalKey<ScaffoldState> formStepperScaffoldKey =
    new GlobalKey<ScaffoldState>();

class PlanificationFormBloc extends FormBloc<String, String> {
  late final ResponseGetListPannes responseGetListPannes;

  Directory dir = Directory("");
  File fileTraitementList = File("");

  /* Form Fields */
  final dateRdvInputFieldBLoc = InputFieldBloc<DateTime?, Object>(
    initialValue: null,
    name: "date_rdv",
    validators: [
      FieldBlocValidators.required,
    ],
    toJson: (value) {
      final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:s');
      final String formatted = formatter.format(value ?? DateTime.now());
      return formatted;
    },
  );

  final commentaireTextField = TextFieldBloc(
    name: 'commentaire',
    validators: [
      FieldBlocValidators.required,
    ],
  );

  PlanificationFormBloc() : super(isLoading: true) {
    Tools.currentStep = (Tools.selectedDemande?.etape ?? 1) - 1;

    print("Tools.currentStep ==> ${Tools.currentStep}");
    emit(FormBlocLoading(currentStep: Tools.currentStep));

    addFieldBlocs(
      step: 0,
      fieldBlocs: [
        dateRdvInputFieldBLoc,
        commentaireTextField,
      ],
    );


  }


  @override
  void onLoading() async {
    emitFailure(failureResponse: "loadingTest");
    Tools.initFiles();

    getApplicationDocumentsDirectory().then((Directory directory) {
      dir = directory;
      fileTraitementList = new File(dir.path + "/fileTraitementList.json");

      if (!fileTraitementList.existsSync()) {
        fileTraitementList.createSync();
      }
    });

    emitLoaded();

  }

  @override
  void updateCurrentStep(int step) {
    print("override updateCurrentStep");
    print("Tools.currentStep ==> ${Tools.currentStep}");

    // currentStepValueNotifier.value = Tools.currentStep;

    super.updateCurrentStep(step);
  }

  @override
  void previousStep() {
    print("override previousStep");
    print("Tools.currentStep ==> ${Tools.currentStep}");

    clearInputs();

    super.previousStep();
  }

  Future<String> callWsAddMobile(Map<String, dynamic> formDateValues) async {
    print("****** callWsAddMobile ***");

    FormData formData = FormData.fromMap(formDateValues);
    print(formData);

    Response apiRespon;
    try {
      print("**************doPOST***********");
      Dio dio = new Dio();
      dio.interceptors.add(CustomInterceptor());
      dio.interceptors.add(dioLoggerInterceptor);

      apiRespon = await dio.post("${Tools.baseUrl}/demandes/planifier_mobile",
          data: formData,
          options: Options(
            followRedirects: true,
            method: "POST",
            headers: {
              'Content-Type': 'multipart/form-data;charset=UTF-8',
              'Charset': 'utf-8',
              'Accept': 'application/json',
            },
          ));

      print("Image Upload ${apiRespon}");

      print(apiRespon);

      if (apiRespon.data == "000") {
        return "000";
      }

    } on DioError catch (e) {
      print("**************DioError***********");
      print(e);
      // The request was made and the server responded with a status code
      // that falls out of the range of 2xx and is also not 304.
      if (e.response != null) {
        print(e.response);
        // print(e.response.headers);
        // print(e.response.);
        //           print("**->REQUEST ${e.response?.re.uri}#${Transformer.urlEncodeMap(e.response?.request.data)} ");
        // throw (e.response?.statusMessage ?? "");
      } else {
        // Something happened in setting up or sending the request that triggered an Error
        //        print(e.request);
        print(e.message);
      }
    } catch (e) {
      // throw ('API ERROR');
      print("API ERROR ${e}");
      return "Erreur de connexion au serveur";
    }

    return "Erreur de connexion au serveur";
  }

  @override
  void onSubmitting() async {
    print("FormStepper onSubmitting() ");
    print("Tools.currentStep ==> ${Tools.currentStep}");
    print('onSubmittinga ${state.toJson()}');

    try {
      final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:s');
      final String dateNowFormatted = formatter.format(DateTime.now());
      String currentAddress = "";

      bool isLocationServiceOK = await ToolsExtra.checkLocationService();
      if (isLocationServiceOK == false) {
        emitFailure(
            failureResponse: "Les services de localisation sont désactivés.");
        return;
      }

      try {
        currentAddress = await Tools.getAddressFromLatLng();
      } catch (e) {
        emitFailure(failureResponse: e.toString());
        return;
      }

      Map<String, dynamic> formDateValues = await state.toJson();

      formDateValues.addAll({
        // "etape": Tools.currentStep + 1,
        "demande_id": Tools.selectedDemande?.id ?? "",
        "user_id": Tools.userId,
        "Traitement[date]": dateNowFormatted,
        "Traitement[currentAddress]": currentAddress,
        "Traitement[commentaire_sup]": "commentaire_sup"
      });

      print(formDateValues);

      print("dio start");

      if (await Tools.tryConnection()) {
        String checkCallWs = await callWsAddMobile(formDateValues);

        if (checkCallWs == "000") {
          // if (await Tools.refreshSelectedDemande()) {
          await Tools.refreshSelectedDemande();
          print("refreshed refreshSelectedDemande");
          print("Tools.selectedDemande ==> ${Tools.selectedDemande?.etape}");
          print("state.currentStep ==> ${state.currentStep}");

          emitSuccess();
        } else {
          // writeToFileTraitementList(formDateValues);
          emitFailure(failureResponse: checkCallWs);
        }
      } else {
        print('No internet :( Reason:');
        writeToFileTraitementList(formDateValues);
        emitFailure(failureResponse: "sameStep");
      }
    } catch (e) {
      emitFailure();
    }

    if (state.currentStep == 0) {
    } else if (state.currentStep == 1) {
    } else if (state.currentStep == 2) {}
  }

  void clearInputs() {
    print("clearInputs()");
    print("Tools.currentStep ==> ${Tools.currentStep}");
    dateRdvInputFieldBLoc.clear();
    commentaireTextField.clear();
  }

  bool writeToFileTraitementList(Map jsonMapContent) {
    print("Writing to writeToFileTraitementList!");

    // fileTraitementList.writeAsStringSync("");
    // return true;
    try {
      String fileContent = fileTraitementList.readAsStringSync();
      print("file content ==> ${fileContent}");

      if (fileContent.isEmpty) {
        print("empty file");

        Map emptyMap = {"traitementList": []};

        fileTraitementList.writeAsStringSync(json.encode(emptyMap));

        fileContent = fileTraitementList.readAsStringSync();
      }

      Map traitementListMap = json.decode(fileContent);

      print("file content decode ==> ${traitementListMap}");

      List traitementList = traitementListMap["traitementList"];

      traitementList.add(json.encode(jsonMapContent));

      traitementListMap["traitementList"] = traitementList;

      fileTraitementList.writeAsStringSync(json.encode(traitementListMap));

      return true;
    } catch (e) {
      print("exeption -- " + e.toString());
    }

    return false;
  }
}

class CustomInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    if (response.statusCode == 302) {
      String? redirectUrl = response.headers.value('location');
      if (redirectUrl != null) {
        // Make a new request to the redirected URL
        var dio = Dio();
        var newResponse = await dio.post(
          redirectUrl,
          data: response.requestOptions.data,
          options: Options(
            headers: response.requestOptions.headers,
            followRedirects: true,
          ),
        );
        handler.resolve(newResponse);
        return;
      }
    }
    super.onResponse(response, handler);
  }
}

class PlanificationForm extends StatefulWidget {
  @override
  _PlanificationFormState createState() => _PlanificationFormState();
}

class _PlanificationFormState extends State<PlanificationForm>
    with SingleTickerProviderStateMixin {
  var _type = StepperType.horizontal;

  void _toggleType() {
    setState(() {
      if (_type == StepperType.horizontal) {
        _type = StepperType.vertical;
      } else {
        _type = StepperType.horizontal;
      }
    });
  }

  ValueNotifier<int> commentaireCuuntValueNotifer =
      ValueNotifier(Tools.selectedDemande?.commentaires?.length ?? 0);

  late Animation<double> _animation;
  late AnimationController _animationController;

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 260),
    );

    final curvedAnimation =
        CurvedAnimation(curve: Curves.easeInOut, parent: _animationController);
    _animation = Tween<double>(begin: 0, end: 1).animate(curvedAnimation);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PlanificationFormBloc>(
          create: (BuildContext context) => PlanificationFormBloc(),
        ),
        BlocProvider<InternetCubit>(
          create: (BuildContext context) =>
              InternetCubit(connectivity: Connectivity()),
        ),
      ],
      child: Builder(
        builder: (context) {
          return Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            child: MultiBlocListener(
              listeners: [
                BlocListener<InternetCubit, InternetState>(
                  listener: (context, state) {
                    if (state is InternetConnected) {
                      // showSimpleNotification(
                      //   Text("status : en ligne"),
                      //   // subtitle: Text("onlime"),
                      //   background: Colors.green,
                      //   duration: Duration(seconds: 5),
                      // );
                    }
                    if (state is InternetDisconnected) {
                      // showSimpleNotification(
                      //   Text("Offline"),
                      //   // subtitle: Text("onlime"),
                      //   background: Colors.red,
                      //   duration: Duration(seconds: 5),
                      // );
                    }
                  },
                ),
              ],
              child: Scaffold(
                key: formStepperScaffoldKey,
                resizeToAvoidBottomInset: true,
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.miniStartFloat,

                //Init Floating Action Bubble
                floatingActionButton: FloatingActionBubble(
                  // Menu items
                  items: <Bubble>[
                    // Floating action menu item
                    Bubble(
                      title: "WhatssApp",
                      iconColor: Colors.white,
                      bubbleColor: Colors.blue,
                      icon: FontAwesomeIcons.whatsapp,
                      titleStyle: TextStyle(
                          fontSize: 16, color: Colors.white),
                      onPress: () async {
                        print("share wtsp");

                        String msgShare =
                        getMsgShare(1);

                        print("msgShare ==> ${msgShare}");

                        // shareToWhatsApp({String msg,String imagePath})

                        final FlutterSocialShare flutterShareMe = FlutterSocialShare();
                        await flutterShareMe.shareToWhatsApp(msg: msgShare);
                        /*
                          var whatsapp = "+212619993849";
                          var whatsappURl_android =
                              "whatsapp://send?phone=" + whatsapp + "&text=${Uri.parse(msgShare)}";
                          var whatappURL_ios =
                              "https://wa.me/$whatsapp?text=${Uri.parse(msgShare)}";
                          if (Platform.isIOS) {
                            // for iOS phone only
                            if (await canLaunch(whatappURL_ios)) {
                              await launch(whatappURL_ios, forceSafariVC: false);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: new Text("whatsapp no installed")));
                            }
                          } else {
                            // android , web
                            if (await canLaunch(whatsappURl_android)) {
                              await launch(whatsappURl_android);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: new Text("whatsapp no installed")));
                            }
                          }

                           */
                        _animationController.reverse();
                      },
                    ),
                    // Floating action menu item
                    Bubble(
                      title: "Mail",
                      iconColor: Colors.white,
                      bubbleColor: Colors.blue,
                      icon: Icons.mail_outline,
                      titleStyle: TextStyle(
                          fontSize: 16, color: Colors.white),
                      onPress: () async {
                        LoadingDialog.show(context);
                        bool success = await Tools.callWSSendMail();
                        LoadingDialog.hide(context);

                        if (success) {
                          CoolAlert.show(
                              context: context,
                              type: CoolAlertType.success,
                              text: "Email Envoyé avec succès",
                              autoCloseDuration:
                              Duration(seconds: 5),
                              title: "Succès");
                        }
                        _animationController.reverse();
                      },
                    ),
                    //Floating action menu item
                  ],

                  // animation controller
                  animation: _animation,

                  // On pressed change animation state
                  onPress: () => _animationController.isCompleted
                      ? _animationController.reverse()
                      : _animationController.forward(),

                  // Floating Action button Icon color
                  iconColor: Tools.colorSecondary,

                  // Flaoting Action button Icon
                  iconData: FontAwesomeIcons.whatsapp,
                  backGroundColor: Colors.white,
                ),

                appBar: AppBar(
                  leading: Builder(
                    builder: (BuildContext context) {
                      final ScaffoldState? scaffold = Scaffold.maybeOf(context);
                      final ModalRoute<Object?>? parentRoute =
                          ModalRoute.of(context);
                      final bool hasEndDrawer = scaffold?.hasEndDrawer ?? false;
                      final bool canPop = parentRoute?.canPop ?? false;

                      if (hasEndDrawer && canPop) {
                        return BackButton();
                      } else {
                        return SizedBox.shrink();
                      }
                    },
                  ),
                  title: Text('Planification'),
                  actions: <Widget>[
                    // NamedIcon(
                    //     text: '',
                    //     iconData: _type == StepperType.horizontal
                    //         ? Icons.swap_vert
                    //         : Icons.swap_horiz,
                    //     onTap: _toggleType),
                    ValueListenableBuilder(
                      valueListenable: commentaireCuuntValueNotifer,
                      builder: (BuildContext context, int commentaireCount,
                          Widget? child) {
                        return NamedIcon(
                          text: '',
                          iconData: Icons.comment,
                          notificationCount: commentaireCount,
                          onTap: () {
                            formStepperScaffoldKey.currentState
                                ?.openEndDrawer();
                          },
                        );
                      },
                    )
                  ],
                ),
                endDrawer: EndDrawerWidget(),
                body: SafeArea(
                  child: FormBlocListener<PlanificationFormBloc, String, String>(
                    onLoading: (context, state) {
                      print("FormBlocListener onLoading");
                      LoadingDialog.show(context);
                    },
                    onLoaded: (context, state) {
                      print("FormBlocListener onLoaded");
                      LoadingDialog.hide(context);
                    },
                    onLoadFailed: (context, state) {
                      print("FormBlocListener onLoadFailed");
                      LoadingDialog.hide(context);
                    },
                    onSubmissionCancelled: (context, state) {
                      print("FormBlocListener onSubmissionCancelled");
                      LoadingDialog.hide(context);
                    },
                    onSubmitting: (context, state) {
                      print("FormBlocListener onSubmitting");
                      LoadingDialog.show(context);
                    },
                    onSuccess: (context, state) {
                      print("FormBlocListener onSuccess");
                      LoadingDialog.hide(context);

                      commentaireCuuntValueNotifer.value =
                          Tools.selectedDemande?.commentaires?.length ?? 0;

                      CoolAlert.show(
                        context: context,
                        type: CoolAlertType.success,
                        text: "Enregistré avec succès",
                        // autoCloseDuration: Duration(seconds: 2),
                        title: "Succès",
                      );

                      context.read<PlanificationFormBloc>().clear();

                      // Navigator.of(context).pop();
                    },
                    onFailure: (context, state) {
                      print("FormBlocListener onFailure");

                      if (state.failureResponse == "loadingTest") {
                        LoadingDialog.show(context);
                        return;
                      }

                      if (state.failureResponse == "loadingTestFinish") {
                        LoadingDialog.hide(context);
                        return;
                      }

                      LoadingDialog.hide(context);

                      if (state.failureResponse == "sameStep") {
                        commentaireCuuntValueNotifer.value =
                            Tools.selectedDemande?.commentaires?.length ?? 0;

                        CoolAlert.show(
                          context: context,
                          type: CoolAlertType.success,
                          text: "Enregistré avec succès",
                          // autoCloseDuration: Duration(seconds: 2),
                          title: "Succès",
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(state.failureResponse!)));
                      }
                    },
                    onSubmissionFailed: (context, state) {
                      print("FormBlocListener onSubmissionFailed ${state}");
                      // LoadingDialog.hide(context);
                    },
                    child: Stack(
                      children: [
                        StepperFormBlocBuilder<PlanificationFormBloc>(
                          formBloc: context.read<PlanificationFormBloc>(),
                          type: _type,
                          physics: ClampingScrollPhysics(),
                          // onStepCancel: (formBloc) {
                          //   print("Cancel clicked");
                          //
                          //
                          //
                          // },
                          controlsBuilder: (
                            BuildContext context,
                            VoidCallback? onStepContinue,
                            VoidCallback? onStepCancel,
                            int step,
                            FormBloc formBloc,
                          ) {
                            return Column(
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    SizedBox(
                                      height: 50,
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        // padding: const  EdgeInsets.only(top: 8,left: 8,right: 8, bottom: 20),

                                        child: ElevatedButton(
                                          onPressed: () async {
                                            print("cliick");
                                            // formBloc.readJson();
                                            // formBloc.fileTraitementList.writeAsStringSync("");

                                            // bool isLocationServiceOK = await ToolsExtra.checkLocationService();
                                            // if(isLocationServiceOK == false){
                                            //   return;
                                            // }

                                            formBloc.submit();
                                          },
                                          child: const Text(
                                            'Enregistrer',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 18.0,
                                              wordSpacing: 12,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            // shape: CircleBorder(),
                                            minimumSize: Size(280, 50),

                                            // primary: Tools.colorPrimary,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  new BorderRadius.circular(
                                                      30.0),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (!formBloc.state.isFirstStep &&
                                        !formBloc.state.isLastStep)
                                      // Expanded(
                                      //   child: ElevatedButton(
                                      //     onPressed: () {
                                      //       print("cliick");
                                      //       // formBloc.readJson();
                                      //       // formBloc.fileTraitementList.writeAsStringSync("");
                                      //
                                      //       // context.read<formBloc>().clear();
                                      //
                                      //
                                      //
                                      //       onStepCancel!() ;
                                      //     },
                                      //     child: const Text('Annuler',
                                      //       textAlign: TextAlign.center,
                                      //       style: TextStyle(
                                      //         fontSize: 18.0,
                                      //         wordSpacing: 12,
                                      //       ),
                                      //     ),
                                      //     style: ElevatedButton.styleFrom(
                                      //       primary: Colors.grey,
                                      //       // shape: CircleBorder(),
                                      //       minimumSize: Size(200, 50),
                                      //       // primary: Tools.colorPrimary,
                                      //       shape: RoundedRectangleBorder(
                                      //         borderRadius: new BorderRadius.circular(30.0),
                                      //       ),
                                      //
                                      //     ),
                                      //   ),
                                      // ),
                                      SizedBox(
                                        height: 50,
                                      ),
//                              Text(Translations.of(context).confidential)
                                  ],
                                ),
                              ],
                            );
                          },
                          stepsBuilder: (formBloc) {
                            return [
                              _step1(formBloc!),
                              // _step2(formBloc),
                              // _step3(formBloc),
                            ];
                          },
                          onStepTapped: (FormBloc? formBloc, int step) {
                            print("onStepTapped");
                            if (step >
                                (Tools.selectedDemande?.etape ?? 1) - 1) {
                              return;
                            }
                            Tools.currentStep = step;
                            print(formBloc);
                            formBloc?.updateCurrentStep(step);

                            // formBloc?.emit(FormBlocLoaded(currentStep: Tools.currentStep));
                          },
                        ),
                        BlocBuilder<InternetCubit, InternetState>(
                          builder: (context, state) {
                            print("BlocBuilder **** InternetCubit ${state}");
                            if (state is InternetConnected &&
                                state.connectionType == ConnectionType.wifi) {
                              // return Text(
                              //   'Wifi',
                              //   style: TextStyle(color: Colors.green, fontSize: 30),
                              // );
                            } else if (state is InternetConnected &&
                                state.connectionType == ConnectionType.mobile) {
                              // return Text(
                              //   'Mobile',
                              //   style: TextStyle(color: Colors.yellow, fontSize: 30),
                              // );
                            } else if (state is InternetDisconnected) {
                              return Positioned(
                                bottom: 0,
                                child: Center(
                                  child: Container(
                                    color: Colors.grey.shade400,
                                    width: MediaQuery.of(context).size.width,
                                    padding: const EdgeInsets.all(0.0),
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          "Pas d'accès internet",
                                          style: TextStyle(
                                              color: Colors.red, fontSize: 20),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                            // return CircularProgressIndicator();
                            return Container();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  FormBlocStep _step1(PlanificationFormBloc formBloc) {
    return FormBlocStep(
      title: Text('Planification'),
      content: Column(
        children: <Widget>[
          InterventionHeaderInfoClientWidget(),
          SizedBox(
            height: 20,
          ),
          Divider(
            color: Colors.black,
            height: 2,
          ),
          SizedBox(
            height: 20,
          ),
          InterventionHeaderInfoProjectWidget(),
          SizedBox(
            height: 20,
          ),
          DateTimeFieldBlocBuilder(
            dateTimeFieldBloc: formBloc.dateRdvInputFieldBLoc,
            format: DateFormat('yyyy-MM-dd HH:mm'),
            //  Y-m-d H:i:s
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime(2100),
            canSelectTime: true,
            decoration: const InputDecoration(
              labelText: 'Rendez-vous',
              prefixIcon: Icon(Icons.date_range),
            ),
          ),
          TextFieldBlocBuilder(
            textFieldBloc: formBloc.commentaireTextField,
            keyboardType: TextInputType.text,
            minLines: 6,
            maxLines: 20,
            decoration: InputDecoration(
              labelText: "Commentaire :",
              prefixIcon: Icon(Icons.comment),
            ),
          ),
        ],
      ),
    );
  }


  String getMsgShare(int currentStepNotifier) {
    print("msgShare currentStepNotifier ==> $currentStepNotifier");

    final demande = Tools.selectedDemande;

    return '''REF: ${demande?.ref ?? ""}
        CASE ID: ${demande?.caseId ?? ""}
        VILLE: ${demande?.ville ?? ""}
        CLIENT: ${demande?.client ?? ""}
        PANNES: ${demande?.demandePanne ?? ""}
        LOGIN_SIP: ${demande?.loginSip ?? ""}
        SOLUTIONS: ${demande?.demandeSolution ?? ""}''';
  }

  Widget buildSizedDivider() {
    return Column(
      children: [
        SizedBox(
          height: 10,
        ),
        Divider(
          color: Colors.black,
          height: 2,
        ),
        SizedBox(
          height: 10,
        ),
      ],
    );
  }
}

class EndDrawerWidget extends StatelessWidget {
  const EndDrawerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/bg_home.jpg"),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Commentaires"),
              ),
              Expanded(
                child: Scrollbar(
                  // isAlwaysShown: true,
                  child: Timeline.tileBuilder(
                    // physics: BouncingScrollPhysics(),
                    builder: TimelineTileBuilder.fromStyle(
                      contentsBuilder: (context, index) => Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(Tools.selectedDemande
                                  ?.commentaires?[index].commentaire ??
                              ""),
                        ),
                      ),
                      oppositeContentsBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                            alignment: AlignmentDirectional.centerEnd,
                            child: Column(
                              children: [
                                // Text(Tools.selectedDemande?.commentaires?[index].userId ?? ""),
                                Text(Tools.selectedDemande?.commentaires?[index]
                                        .created
                                        ?.trim() ??
                                    ""),
                              ],
                            )),
                      ),
                      // itemExtent: 1,
                      // indicatorPositionBuilder: (BuildContext context, int index){
                      //   return 0 ;
                      // },
                      contentsAlign: ContentsAlign.alternating,
                      indicatorStyle: IndicatorStyle.dot,
                      connectorStyle: ConnectorStyle.dashedLine,
                      itemCount:
                          Tools.selectedDemande?.commentaires?.length ?? 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NamedIcon extends StatelessWidget {
  final IconData iconData;
  final String text;
  final VoidCallback? onTap;
  final int notificationCount;

  const NamedIcon({
    Key? key,
    this.onTap,
    required this.text,
    required this.iconData,
    this.notificationCount = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 50,
        padding: const EdgeInsets.only(top: 10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(iconData),
                Text(text, overflow: TextOverflow.ellipsis),
              ],
            ),
            if (notificationCount > 0)
              Positioned(
                top: 10,
                right: notificationCount.toString().length >= 3 ? 15 : 25,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: Colors.red),
                  alignment: Alignment.center,
                  child: Text('$notificationCount'),
                ),
              )
          ],
        ),
      ),
    );
  }
}

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.tag_faces, size: 100),
            const SizedBox(height: 10),
            const Text(
              'Success',
              style: TextStyle(fontSize: 54, color: Colors.black),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.replay),
              label: const Text('AGAIN'),
            ),
          ],
        ),
      ),
    );
  }
}
