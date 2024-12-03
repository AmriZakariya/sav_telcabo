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
import 'package:flutter/services.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:flutter_social_share_plugin/flutter_social_share.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as imagePLugin;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:telcabo/Tools.dart';
import 'package:telcabo/ToolsExtra.dart';
import 'package:telcabo/custome/ConnectivityCheckBlocBuilder.dart';
import 'package:telcabo/custome/ImageFieldBlocbuilder.dart';
import 'package:telcabo/custome/QrScannerTextFieldBlocBuilder.dart';
import 'package:telcabo/models/response_get_liste_pannes.dart';
import 'package:telcabo/ui/InterventionHeaderInfoWidget.dart';
import 'package:telcabo/ui/LoadingDialog.dart';
import 'package:timelines/timelines.dart';

final GlobalKey<ScaffoldState> formStepperScaffoldKey =
new GlobalKey<ScaffoldState>();

ValueNotifier<int> currentStepValueNotifier = ValueNotifier(Tools.currentStep);

class InterventionFormBLoc extends FormBloc<String, String> {
  // late final ResponseGetListEtat responseListEtat;
  // late final ResponseGetListType responseGetListType;
  late final ResponseGetListPannes responseGetListPannes;

  Directory dir = Directory("");
  File fileTraitementList = File("");

  final Map<int, List<FieldBloc>> dynamicFields = {};

  void buildDynamicsFields() {
    for (var i = 1; i <= 10; i++) {
      final panneDropDown_dynamic = SelectFieldBloc<Panne, dynamic>(
        name: "SolPanne[${i}][panne_id]",
        validators: [
          FieldBlocValidators.required,
        ],
        toJson: (value) => value?.id,
      );

      final solutionEtatDropDown_dynamic = SelectFieldBloc<Solution, dynamic>(
        name: "SolPanne[${i}][solution_id]",
        validators: [
          FieldBlocValidators.required,
        ],
        toJson: (value) => value?.id,
      );

      final qteTextField_dynamic = TextFieldBloc(
        name: "SolPanne[${i}][qte]",
        validators: [FieldBlocValidators.required, _qteMinMaxValue],
      );

      panneDropDown_dynamic.onValueChanges(
        onData: (previous, current) async* {
          var selectedPanne = current.value;
          if (selectedPanne?.id == null) {
            return;
          }

          if (selectedPanne == panneDropDown.value) {
            panneDropDown_dynamic.addError("Panne déjà sélectionnée");
          }

          removeFieldBlocs(fieldBlocs: [
            solutionEtatDropDown_dynamic,
            qteTextField_dynamic,
          ]);

          // if (solutionEtatDropDown.value?.hasExtra == false) {
          //   removeFieldBlocs(fieldBlocs: [
          //     adresseMacTextField,
          //     snRouteurTextField,
          //     snGponTextField,
          //     macAncienneBoxTextField,
          //     snAncienneBoxTextField,
          //     snAncienneGponTextField,
          //     articlesDropDown,
          //   ]);
          //
          // }

          solutionEtatDropDown_dynamic.updateItems(
              selectedPanne?.solutions ?? []);
          addFieldBloc(fieldBloc: solutionEtatDropDown_dynamic);
        },
      );

      solutionEtatDropDown_dynamic.onValueChanges(
        onData: (previous, current) async* {
          var selectedSolution = current.value;
          if (selectedSolution?.id == null) {
            return;
          }

          removeFieldBlocs(fieldBlocs: [
            qteTextField_dynamic,
          ]);

          if (selectedSolution?.hasQuantity == true) {
            addFieldBloc(fieldBloc: qteTextField_dynamic);
          }

          // if (selectedSolution?.hasExtra == true) {
          //   articlesDropDown.updateItems(selectedSolution?.articles ?? []);
          //   addFieldBloc(fieldBloc: articlesDropDown);
          // }
        },
      );

      final List<FieldBloc> fieldBlocsList = [
        panneDropDown_dynamic,
        solutionEtatDropDown_dynamic,
        qteTextField_dynamic,
      ];

      dynamicFields[i] = fieldBlocsList;
    }

    print("[dynamic_debug] dynamicFields ==> ${dynamicFields.length}");
  }

  /* Form Fields */

  final panneDropDown = SelectFieldBloc<Panne, dynamic>(
    name: "SolPanne[0][panne_id]",
    validators: [
      FieldBlocValidators.required,
    ],
    toJson: (value) => value?.id,
  );

  final solutionEtatDropDown = SelectFieldBloc<Solution, dynamic>(
    name: "SolPanne[0][solution_id]",
    validators: [
      FieldBlocValidators.required,
    ],
    toJson: (value) => value?.id,
  );

  final articlesDropDown = SelectFieldBloc<Article, dynamic>(
    name: "Traitement[article_id]",
    validators: [
      FieldBlocValidators.required,
    ],
    toJson: (value) => value?.id,
  );

  final qteTextField = TextFieldBloc(
    name: 'SolPanne[0][qte]',
    validators: [FieldBlocValidators.required, _qteMinMaxValue],
    initialValue: "1",
  );

  final commentaireTextField = TextFieldBloc(
    name: 'Traitement[commentaire]',
    validators: [
      FieldBlocValidators.required,
    ],
  );

  final commentaireSupTextField = TextFieldBloc(
    name: 'Traitement[commentaire_sup]',
    validators: [
      FieldBlocValidators.required,
    ],
  );

  final InputFieldBloc<XFile?, Object> photoProblemeInputFieldBloc =
  InputFieldBloc(
    initialValue: null,
    name: "photo_probleme",
    validators: [
      FieldBlocValidators.required,
    ],
    toJson: (value) {
      MultipartFile file = MultipartFile.fromFileSync(value?.path ?? "",
          filename: value?.name ?? "");
      return file;
    },
  );

  final InputFieldBloc<XFile?, Object> photoSignalInputFieldBloc =
  InputFieldBloc(
    initialValue: null,
    name: "photo_signal",
    validators: [
      FieldBlocValidators.required,
    ],
    toJson: (value) {
      MultipartFile file = MultipartFile.fromFileSync(value?.path ?? "",
          filename: value?.name ?? "");
      return file;
    },
  );

  final InputFieldBloc<XFile?, Object> photoResolutionProblemeInputFieldBloc =
  InputFieldBloc(
    initialValue: null,
    validators: [
      FieldBlocValidators.required,
    ],
    name: "photo_resolution_probleme",
    toJson: (value) {
      MultipartFile file = MultipartFile.fromFileSync(value?.path ?? "",
          filename: value?.name ?? "");
      return file;
    },
  );

  final InputFieldBloc<XFile?, Object> photoSup1InputFieldBloc = InputFieldBloc(
    initialValue: null,
    name: "photo_sup1",
    toJson: (value) {
      MultipartFile file = MultipartFile.fromFileSync(value?.path ?? "",
          filename: value?.name ?? "");
      return file;
    },
  );

  final InputFieldBloc<XFile?, Object> photoSup2InputFieldBloc = InputFieldBloc(
    initialValue: null,
    name: "photo_sup2",
    // validators: [
    //   FieldBlocValidators.required,
    // ],
    toJson: (value) {
      MultipartFile file = MultipartFile.fromFileSync(value?.path ?? "",
          filename: value?.name ?? "");
      return file;
    },
  );

  static String? _qteMinMaxValue(String? debit) {
    int intValue;

    try {
      intValue = int.parse(debit ?? "");
      if (intValue < 1) {
        return "min 1";
      }
    } catch (e) {
      return "intValue";
    }
    return null;
  }

  final latitudeTextField = TextFieldBloc(
    name: 'Traitement[latitude]',
    validators: [
      FieldBlocValidators.required,
    ],
  );

  final longintudeTextField = TextFieldBloc(
    name: 'Traitement[longitude]',
    validators: [
      FieldBlocValidators.required,
    ],
  );
  final adresseMacTextField = TextFieldBloc(
    name: 'Traitement[adresse_mac]',
    validators: [
      FieldBlocValidators.required,
    ],
  );

  final snRouteurTextField = TextFieldBloc(
    name: 'Traitement[sn_routeur]',
    validators: [
      FieldBlocValidators.required,
    ],
  );

  final snGponTextField = TextFieldBloc(
    name: 'Traitement[sn_gpon]',
    validators: [
      FieldBlocValidators.required,
    ],
  );
  final macAncienneBoxTextField = TextFieldBloc(
    name: 'Traitement[mac_an_box]',
    validators: [
      // FieldBlocValidators.required,
    ],
  );

  final snAncienneBoxTextField = TextFieldBloc(
    name: 'Traitement[sn_an_box]',
    validators: [
      FieldBlocValidators.required,
    ],
  );

  final snAncienneGponTextField = TextFieldBloc(
    name: 'Traitement[sn_an_gpon]',
    validators: [
      FieldBlocValidators.required,
    ],
  );

  InterventionFormBLoc() : super(isLoading: true) {
    Tools.currentStep = (Tools.selectedDemande?.etape ?? 1) - 1;

    print("Tools.currentStep ==> ${Tools.currentStep}");
    emit(FormBlocLoading(currentStep: Tools.currentStep));

    addFieldBlocs(
      step: 0,
      fieldBlocs: [
        panneDropDown,
        latitudeTextField,
        longintudeTextField,
        photoProblemeInputFieldBloc,
        photoSignalInputFieldBloc,
        photoResolutionProblemeInputFieldBloc,
        photoSup1InputFieldBloc,
        photoSup2InputFieldBloc,
        commentaireTextField,
      ],
    );

    panneDropDown.onValueChanges(
      onData: (previous, current) async* {
        var selectedPanne = current.value;
        if (selectedPanne?.id == null) {
          return;
        }

        removeFieldBlocs(fieldBlocs: [
          articlesDropDown,
          solutionEtatDropDown,
          qteTextField,
          adresseMacTextField,
          snRouteurTextField,
          snGponTextField,
          macAncienneBoxTextField,
          snAncienneBoxTextField,
          snAncienneGponTextField,
        ]);

        solutionEtatDropDown.updateItems(selectedPanne?.solutions ?? []);
        addFieldBloc(fieldBloc: solutionEtatDropDown);
      },
    );

    solutionEtatDropDown.onValueChanges(
      onData: (previous, current) async* {
        var selectedSolution = current.value;
        if (selectedSolution?.id == null) {
          return;
        }

        removeFieldBlocs(fieldBlocs: [
          articlesDropDown,
          qteTextField,
          adresseMacTextField,
          snRouteurTextField,
          snGponTextField,
          macAncienneBoxTextField,
          snAncienneBoxTextField,
          snAncienneGponTextField,
        ]);

        if (selectedSolution?.hasQuantity == true) {
          addFieldBloc(fieldBloc: qteTextField);
        }

        if (selectedSolution?.hasExtra == true) {
          articlesDropDown.updateItems(selectedSolution?.articles ?? []);
          addFieldBlocs(fieldBlocs: [
            articlesDropDown,
            adresseMacTextField,
            snRouteurTextField,
            snGponTextField,
            macAncienneBoxTextField,
            snAncienneBoxTextField,
            snAncienneGponTextField,
          ]);
        }
      },
    );

    buildDynamicsFields();
  }

  bool writeToFileTraitementList(Map jsonMapContent) {
    print("Writing to writeToFileTraitementList!");

    // fileTraitementList.writeAsStringSync("");
    // return true;
    try {
      for (var mapKey in jsonMapContent.keys) {
        // print('${k}: ${v}');
        // print(k);

        if (mapKey == "p_pbi_avant") {
          jsonMapContent[mapKey] =
          "${photoProblemeInputFieldBloc.value
              ?.path};;${photoProblemeInputFieldBloc.value?.name}";
        } else if (mapKey == "p_pbi_apres") {
          // jsonMapContent[mapKey] = pPbiApresTextField.value?.path;
          jsonMapContent[mapKey] =
          "${photoSignalInputFieldBloc.value?.path};;${photoSignalInputFieldBloc
              .value?.name}";
        } else if (mapKey == "p_pbo_avant") {
          // jsonMapContent[mapKey] = pPboAvantTextField.value?.path;
          jsonMapContent[mapKey] =
          "${photoResolutionProblemeInputFieldBloc.value
              ?.path};;${photoResolutionProblemeInputFieldBloc.value?.name}";
        } else if (mapKey == "p_pbo_apres") {
          // jsonMapContent[mapKey] = pPboApresTextField.value?.path;
          jsonMapContent[mapKey] =
          "${photoSup1InputFieldBloc.value?.path};;${photoSup1InputFieldBloc
              .value?.name}";
        } else if (mapKey == "photo_blocage1") {
          // jsonMapContent[mapKey] = pSpeedTest.value?.path;
          jsonMapContent[mapKey] =
          "${photoSup2InputFieldBloc.value?.path};;${photoSup2InputFieldBloc
              .value?.name}";
        }
      }

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

    try {
      responseGetListPannes = await Tools.getPannesListFromLocalAndInternet();

      panneDropDown.updateItems(responseGetListPannes.pannes ?? []);

      final List<FieldBloc> allFields =
      dynamicFields.values.expand((list) => list).toList();
      for (var dynamicField in allFields) {
        if (dynamicField is SelectFieldBloc<Panne, dynamic>) {
          dynamicField.updateItems(responseGetListPannes.pannes ?? []);
        }
      }

      if (Tools.userName.toLowerCase().contains("admin")) {
        addFieldBlocs(fieldBlocs: [
          commentaireSupTextField,
        ]);
      }
      emitLoaded();
      // emitFailure(failureResponse: "loadingTestFinish");
    } catch (e) {
      print(e);
      emitLoadFailed(failureResponse: e.toString());
    }
  }

  @override
  void updateCurrentStep(int step) {
    print("override updateCurrentStep");
    print("Tools.currentStep ==> ${Tools.currentStep}");

    clearInputs();

    currentStepValueNotifier.value = Tools.currentStep;

    super.updateCurrentStep(step);
  }

  @override
  void previousStep() {
    print("override previousStep");
    print("Tools.currentStep ==> ${Tools.currentStep}");

    currentStepValueNotifier.value = Tools.currentStep;

    clearInputs();

    super.previousStep();
  }

  Future<String> callWsAddMobile(Map<String, dynamic> formDateValues) async {
    print("****** callWsAddMobile ***");

    String fileName = DateTime
        .now()
        .millisecondsSinceEpoch
        .toString();

    if (Tools.localWatermark == true) {
      print("Local watermark start ");
      for (var mapKey in formDateValues.keys) {
        print("mapKey ==> $mapKey");
        if (mapKey == "photo_probleme" ||
            mapKey == "photo_signal" ||
            mapKey == "photo_resolution_probleme" ||
            mapKey == "photo_sup1" ||
            mapKey == "photo_sup2") {
          try {
            if (formDateValues[mapKey] != null) {
              var xfileSrc;

              if (mapKey == "photo_probleme") {
                xfileSrc = photoProblemeInputFieldBloc.value;
              } else if (mapKey == "photo_signal") {
                xfileSrc = photoSignalInputFieldBloc.value;
              } else if (mapKey == "photo_resolution_probleme") {
                xfileSrc = photoResolutionProblemeInputFieldBloc.value;
              } else if (mapKey == "photo_sup1") {
                xfileSrc = photoSup1InputFieldBloc.value;
              } else if (mapKey == "photo_sup2") {
                xfileSrc = photoSup2InputFieldBloc.value;
              }

              final File fileResult = File(xfileSrc?.path ?? "");

              final image =
              imagePLugin.decodeImage(fileResult.readAsBytesSync())!;

              // imagePLugin.Image image = imagePLugin.copyResize(thumbnail, width: 960) ;

              // imagePLugin.drawString(
              //     image, imagePLugin.arial_24, 0, 0, currentDate);
              // imagePLugin.drawString(
              //     image, imagePLugin.arial_24, 0, 32, currentAddress);

              File fileResultWithWatermark =
              File(dir.path + "/" + fileName + '.png');
              fileResultWithWatermark
                  .writeAsBytesSync(imagePLugin.encodePng(image));

              XFile xfileResult = XFile(fileResultWithWatermark.path);

              formDateValues[mapKey] = MultipartFile.fromFileSync(
                  xfileResult.path,
                  filename: xfileResult.name);

              print("watermark success");
            }
          } catch (e) {
            print("+++ exception ++++ mapKey ==> $mapKey");
            print(e);
            formDateValues[mapKey] = null;
          }
        }
      }
    }

    FormData formData = FormData.fromMap(formDateValues);
    print(formData);

    Response apiRespon;
    try {
      print("**************doPOST***********");
      Dio dio = new Dio();
      dio.interceptors.add(CustomInterceptor());
      dio.interceptors.add(dioLoggerInterceptor);

      apiRespon = await dio.post("${Tools.baseUrl}/traitements/add_mobile",
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

      // if (apiRespon.statusCode == 201) {
      //   apiRespon.statusCode == 201;
      //
      //   return true ;
      // } else {
      //   print('errr');
      // }
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
        "date": dateNowFormatted,
        "currentAddress": currentAddress,
        // "Traitement[commentaire_sup]": "commentaire_sup"
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

          Tools.currentStep = (Tools.selectedDemande?.etape ?? 1) - 1;
          currentStepValueNotifier.value = Tools.currentStep;

          emitSuccess(canSubmitAgain: true);
          clearInputs();
          // }else {
          //   emitFailure(failureResponse: "WS");
          // }
        } else {
          // writeToFileTraitementList(formDateValues);

          emitFailure(failureResponse: checkCallWs);
        }
      } else {
        print('No internet :( Reason:');
        writeToFileTraitementList(formDateValues);
        emitFailure(failureResponse: "sameStep");
        // emitSuccess();
      }

      // readJson();
    } catch (e) {
      emitFailure();
    }
  }

  void clearInputs() {
    print("clearInputs()");
    print("Tools.currentStep ==> ${Tools.currentStep}");
    clear();
  }

  void updateInputsFromDemande() {
    // updateValidatorFromDemande();
    //
    // var selectedPanne =
    // responseGetListPannes.pannes?.firstWhereOrNull((element) {
    //   return element.id == Tools.selectedDemande?.etatId;
    // });
    // print("selectedEtat ==> ${selectedPanne}");
    //
    // if (selectedPanne != null) {
    //   if (panneDropDown.state.items.contains(selectedPanne)) {
    //     panneDropDown.updateValue(selectedPanne);
    //   } else {
    //     panneDropDown.addItem(selectedPanne);
    //     panneDropDown.updateValue(selectedPanne);
    //   }
    // }
    //
    //
    // latitudeTextField.updateValue(Tools.selectedDemande?.latitude ?? "");
    // longintudeTextField.updateValue(Tools.selectedDemande?.longitude ?? "");
    // adresseMacTextField.updateValue(Tools.selectedDemande?.adresseMac ?? "");
    // macAncienneBoxTextField.updateValue(Tools.selectedDemande?.snTel ?? "");
    // snRouteurTextField.updateValue(Tools.selectedDemande?.snRouteur ?? "");

  }

  void updateValidatorFromDemande() {
  //   if (Tools.selectedDemande?.pPbiAvant?.isNotEmpty == true) {
  //     print("removeValidators pPbiAvantTextField");
  //     photoProblemeInputFieldBloc.removeValidators([
  //       FieldBlocValidators.required,
  //     ]);
  //   } else {
  //     print("addValidators pPbiAvantTextField");
  //
  //     photoProblemeInputFieldBloc.addValidators([
  //       FieldBlocValidators.required,
  //     ]);
  //   }
  //
  //   if (Tools.selectedDemande?.pPbiApres?.isNotEmpty == true) {
  //     photoSignalInputFieldBloc.removeValidators([
  //       FieldBlocValidators.required,
  //     ]);
  //   } else {
  //     photoSignalInputFieldBloc.addValidators([
  //       FieldBlocValidators.required,
  //     ]);
  //   }
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

class InterventionForm extends StatefulWidget {
  @override
  _InterventionFormState createState() => _InterventionFormState();
}

class _InterventionFormState extends State<InterventionForm>
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
        BlocProvider<InterventionFormBLoc>(
          create: (BuildContext context) => InterventionFormBLoc(),
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
                floatingActionButton: ValueListenableBuilder(
                    valueListenable: currentStepValueNotifier,
                    builder: (BuildContext context, int currentStepNotifier,
                        Widget? child) {
                      print(
                          "ValueListenableBuilder ==> ${currentStepNotifier}");
                      return Visibility(
                          visible: currentStepNotifier != 1,
                          child: FloatingActionBubble(
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
                                  getMsgShare(currentStepNotifier);

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
                            onPress: () =>
                            _animationController.isCompleted
                                ? _animationController.reverse()
                                : _animationController.forward(),

                            // Floating Action button Icon color
                            iconColor: Tools.colorSecondary,

                            // Flaoting Action button Icon
                            iconData: FontAwesomeIcons.whatsapp,
                            backGroundColor: Colors.white,
                          ));
                    }),

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
                  title: Text('Intervention'),
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
                  child: FormBlocListener<InterventionFormBLoc, String, String>(
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

                      Tools.currentStep = state.currentStep;
                      context.read<InterventionFormBLoc>().clearInputs();

                      if (state.stepCompleted == state.lastStep) {
                        Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => SuccessScreen()));
                      }
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
                        StepperFormBlocBuilder<InterventionFormBLoc>(
                          formBloc: context.read<InterventionFormBLoc>(),
                          type: _type,
                          physics: ClampingScrollPhysics(),
                          // onStepCancel: (formBloc) {
                          //   print("Cancel clicked");
                          //
                          //
                          //
                          // },
                          controlsBuilder: (BuildContext context,
                              VoidCallback? onStepContinue,
                              VoidCallback? onStepCancel,
                              int step,
                              FormBloc formBloc,) {
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
                                    width: MediaQuery
                                        .of(context)
                                        .size
                                        .width,
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

  FormBlocStep _step1(InterventionFormBLoc formBloc) {
    return FormBlocStep(
      title: Text('Intervention'),
      content: Column(
        children: <Widget>[
          InterventionHeaderInfoClientWidget(),
          buildSizedDivider(),
          InterventionHeaderInfoProjectWidget(),
          SizedBox(
            height: 20,
          ),
          if (Tools.selectedDemande?.etatId == "9")
            Container(
              padding: const EdgeInsets.only(bottom: 30),
              child: Text(
                Tools.selectedDemande?.etatName ?? "",
                style: TextStyle(fontSize: 20),
              ),
            ),
          DropdownFieldBlocBuilder<Panne>(
            selectFieldBloc: formBloc.panneDropDown,
            decoration: const InputDecoration(
              labelText: 'Panne :',
              prefixIcon: Icon(Icons.list),
            ),
            itemBuilder: (context, value) =>
                FieldItem(
                  child: Text(value.name ?? ""),
                ),
          ),
          DropdownFieldBlocBuilder<Solution>(
            selectFieldBloc: formBloc.solutionEtatDropDown,
            decoration: const InputDecoration(
              labelText: 'Solution',
              prefixIcon: Padding(
                padding: const EdgeInsets.only(top: 10, left: 12),
                child: FaIcon(
                  FontAwesomeIcons.scribd,
                ),
              ),
            ),
            itemBuilder: (context, value) =>
                FieldItem(
                  child: Text(value.name ?? ""),
                ),
          ),
          TextFieldBlocBuilder(
            textFieldBloc: formBloc.qteTextField,
            keyboardType:
            TextInputType.numberWithOptions(decimal: true, signed: true),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              labelText: "Qte (Unité):",
              // prefixIcon: Icon(Icons.speed),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(top: 10, left: 12),
                child: FaIcon(
                  FontAwesomeIcons.houseSignal,
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FilledButton.icon(
                onPressed: () {
                  displayExtraPanneDialog(context, formBloc);
                },
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
              ),
              FilledButton.icon(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.red),

                ),
                onPressed: () {
                  removeLastDynamicField(context, formBloc);
                },
                icon: const Icon(Icons.remove),
                label: const Text('supprimer'),
              ),
            ],
          ),
          buildDynamicFieldItems(formBloc),
          DropdownFieldBlocBuilder<Article>(
            selectFieldBloc: formBloc.articlesDropDown,
            decoration: const InputDecoration(
              labelText: 'Routeur :',
              prefixIcon: Padding(
                padding: const EdgeInsets.only(top: 10, left: 12),
                child: FaIcon(
                  FontAwesomeIcons.scribd,
                ),
              ),
            ),
            itemBuilder: (context, value) =>
                FieldItem(
                  child: Text(value.name ?? ""),
                ),
          ),
          QrScannerTextFieldBlocBuilder(
            formBloc: formBloc,
            iconField: Padding(
              padding: const EdgeInsets.only(top: 10, left: 12),
              child: FaIcon(
                FontAwesomeIcons.terminal,
              ),
            ),
            labelText: "Adresse Mac :",
            qrCodeTextFieldBloc: formBloc.adresseMacTextField,
          ),
          QrScannerTextFieldBlocBuilder(
            formBloc: formBloc,
            iconField: Padding(
              padding: const EdgeInsets.only(top: 10, left: 12),
              child: FaIcon(
                FontAwesomeIcons.terminal,
              ),
            ),
            labelText: "SN Routeur :",
            qrCodeTextFieldBloc: formBloc.snRouteurTextField,
          ),
          QrScannerTextFieldBlocBuilder(
            formBloc: formBloc,
            iconField: Padding(
              padding: const EdgeInsets.only(top: 10, left: 12),
              child: FaIcon(
                FontAwesomeIcons.terminal,
              ),
            ),
            labelText: "SN G-PON :",
            qrCodeTextFieldBloc: formBloc.snGponTextField,
          ),
          QrScannerTextFieldBlocBuilder(
            formBloc: formBloc,
            iconField: Padding(
              padding: const EdgeInsets.only(top: 10, left: 12),
              child: FaIcon(
                FontAwesomeIcons.terminal,
              ),
            ),
            labelText: "MAC Ancienne Box :",
            qrCodeTextFieldBloc: formBloc.macAncienneBoxTextField,
          ),
          QrScannerTextFieldBlocBuilder(
            formBloc: formBloc,
            iconField: Padding(
              padding: const EdgeInsets.only(top: 10, left: 12),
              child: FaIcon(
                FontAwesomeIcons.terminal,
              ),
            ),
            labelText: "SN Ancienne Box :",
            qrCodeTextFieldBloc: formBloc.snAncienneBoxTextField,
          ),
          QrScannerTextFieldBlocBuilder(
            formBloc: formBloc,
            iconField: Padding(
              padding: const EdgeInsets.only(top: 10, left: 12),
              child: FaIcon(
                FontAwesomeIcons.terminal,
              ),
            ),
            labelText: "SN Ancienne G-PON :",
            qrCodeTextFieldBloc: formBloc.snAncienneGponTextField,
          ),
          buildSizedDivider(),
          Container(
              child: Row(
                children: [
                  Flexible(
                    flex: 5,
                    child: Container(
                      child: Column(
                        children: [
                          TextFieldBlocBuilder(
                            readOnly: true,
                            textFieldBloc: formBloc.latitudeTextField,
                            clearTextIcon: Icon(Icons.cancel),
                            suffixButton: SuffixButton.clearText,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              labelText: "Latitude ",
                              prefixIcon: Icon(Icons.location_on),
                              disabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    width: 1,
                                    // color: Tools.colorPrimary
                                  ),
                                  borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                          TextFieldBlocBuilder(
                            readOnly: true,
                            textFieldBloc: formBloc.longintudeTextField,
                            keyboardType: TextInputType.text,
                            clearTextIcon: Icon(Icons.cancel),
                            suffixButton: SuffixButton.clearText,
                            decoration: InputDecoration(
                              labelText: "Longitude ",
                              prefixIcon: Icon(Icons.location_on),
                              disabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    width: 1,
                                    // color: Tools.colorPrimary
                                  ),
                                  borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Flexible(
                    // flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          bool isLocationServiceOK =
                          await ToolsExtra.checkLocationService();
                          if (isLocationServiceOK == false) {
                            CoolAlert.show(
                                context: context,
                                type: CoolAlertType.error,
                                text:
                                "Les services de localisation sont désactivés.",
                                autoCloseDuration: Duration(seconds: 5),
                                title: "Erreur");

                            return;
                          }

                          Position? position = await Tools.determinePosition();

                          if (position != null) {
                            formBloc.latitudeTextField
                                .updateValue(position.latitude.toStringAsFixed(
                                4));
                            formBloc.longintudeTextField
                                .updateValue(position.longitude.toStringAsFixed(
                                4));

                            print("heeeeeee 3 ${position}");
                          }
                        } catch (e) {
                          print(e);
                          // showSimpleNotification(
                          //   Text("Erreur"),
                          //   subtitle: Text(e.toString()),
                          //   background: Colors.green,
                          //   duration: Duration(seconds: 5),
                          // );

                          CoolAlert.show(
                              context: context,
                              type: CoolAlertType.error,
                              text: e.toString(),
                              autoCloseDuration: Duration(seconds: 5),
                              title: "Erreur");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        // primary: Tools.colorPrimary,
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(10),
                      ),
                      child: const Icon(Icons.my_location),
                    ),
                  ),
                ],
              )),
          buildSizedDivider(),
          Container(
            // margin: const EdgeInsets.only(top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                //Center Row contents horizontally,
                crossAxisAlignment: CrossAxisAlignment.center,
                //Center Row contents vertically,
                children: [
                  Flexible(
                    child: ImageFieldBlocBuilder(
                      formBloc: formBloc,
                      fileFieldBloc: formBloc.photoProblemeInputFieldBloc,
                      labelText: "Photo problème :",
                      iconField: Icon(Icons.image_not_supported),
                    ),
                  ),
                  Flexible(
                    // flex: 2,
                    child: ImageFieldBlocBuilder(
                      formBloc: formBloc,
                      fileFieldBloc: formBloc.photoSignalInputFieldBloc,
                      labelText: "Photo Signal :",
                      iconField: Icon(Icons.image_not_supported),
                    ),
                  ),
                ],
              )),
          Container(
            // margin: const EdgeInsets.only(top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                //Center Row contents horizontally,
                crossAxisAlignment: CrossAxisAlignment.center,
                //Center Row contents vertically,
                children: [
                  Flexible(
                    child: ImageFieldBlocBuilder(
                      formBloc: formBloc,
                      fileFieldBloc: formBloc
                          .photoResolutionProblemeInputFieldBloc,
                      labelText: "Photo de résolution de problème :",
                      iconField: Icon(Icons.image_not_supported),
                    ),
                  ),
                  Flexible(
                    // flex: 2,
                    child: ImageFieldBlocBuilder(
                      formBloc: formBloc,
                      fileFieldBloc: formBloc.photoSup1InputFieldBloc,
                      labelText: "Photo \n supplémentaire 1 :",
                      iconField: Icon(Icons.image_not_supported),
                    ),
                  ),
                ],
              )),
          Container(
            // margin: const EdgeInsets.only(top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                //Center Row contents horizontally,
                crossAxisAlignment: CrossAxisAlignment.center,
                //Center Row contents vertically,
                children: [
                  Flexible(
                    child: ImageFieldBlocBuilder(
                      formBloc: formBloc,
                      fileFieldBloc: formBloc.photoSup2InputFieldBloc,
                      labelText: "Photo supplémentaire 2 :",
                      iconField: Icon(Icons.image_not_supported),
                    ),
                  ),
                ],
              )),
          buildSizedDivider(),
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
          TextFieldBlocBuilder(
            textFieldBloc: formBloc.commentaireSupTextField,
            keyboardType: TextInputType.text,
            minLines: 6,
            maxLines: 20,
            decoration: InputDecoration(
              labelText: "Commentaire supperviseur :",
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

  Widget buildFieldBlocWidget(fieldBloc, index) {
    print(
        "buildFieldBlocWidget ==> ${fieldBloc.runtimeType} index ==> ${index}");
    if (fieldBloc is SelectFieldBloc<Panne, dynamic>) {
      return DropdownFieldBlocBuilder<Panne>(
        selectFieldBloc: fieldBloc,
        decoration: InputDecoration(
          labelText: 'Panne extra ${index} :',
          prefixIcon: Icon(Icons.list),
        ),
        itemBuilder: (context, value) =>
            FieldItem(
              child: Text(value.name ?? ""),
            ),
      );
    } else if (fieldBloc is SelectFieldBloc<Solution, dynamic>) {
      return DropdownFieldBlocBuilder<Solution>(
        selectFieldBloc: fieldBloc,
        decoration: InputDecoration(
          labelText: 'Solution extra ${index} :',
          prefixIcon: Icon(Icons.list),
        ),
        itemBuilder: (context, value) =>
            FieldItem(
              child: Text(value.name ?? ""),
            ),
      );
    } else if (fieldBloc is TextFieldBloc) {
      return TextFieldBlocBuilder(
        textFieldBloc: fieldBloc,
        keyboardType:
        TextInputType.numberWithOptions(decimal: true, signed: true),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          labelText: "Qte (Unité) extra ${index} :",
          // prefixIcon: Icon(Icons.speed),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(top: 10, left: 12),
            child: FaIcon(
              FontAwesomeIcons.houseSignal,
            ),
          ),
        ),
      ); // Return a default widget if the type is not recognized
    }

    return Text("azer");
  }

  Widget buildDynamicFieldItems(InterventionFormBLoc formBloc) {
    List<Widget> widgets = [];

    for (var entry in formBloc.dynamicFields.entries) {
      widgets.add(Visibility(
          visible: formBloc.state
              .fieldBlocs()
              ?.containsKey(entry.value.first.name) ??
              true,
          child: buildSizedDivider()));
      for (var fieldBloc in entry.value) {
        widgets.add(buildFieldBlocWidget(fieldBloc, entry.key));
      }
      widgets.add(Visibility(
          visible: formBloc.state
              .fieldBlocs()
              ?.containsKey(entry.value.first.name) ??
              true,
          child: buildSizedDivider()));
    }

    return Column(
      children: widgets,
    );
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

  void displayExtraPanneDialog(BuildContext context, InterventionFormBLoc formBloc) {
      if (formBloc.panneDropDown.value != null) {
        // Iterate over the existing dynamic fields to find the first not added
        for (var entry in formBloc.dynamicFields.entries) {
          var fieldsList = entry.value;
          if (fieldsList.isNotEmpty) {
            var firstField = fieldsList.first;
            bool isFieldAdded = formBloc.state.fieldBlocs()?.containsKey(firstField.name) ?? false;
            if (!isFieldAdded) {
              formBloc.addFieldBlocs(fieldBlocs: [firstField]);
              break;
            }
          }
        }
      } else {
        // Add error message if panneDropDown value is null
        formBloc.panneDropDown.addFieldError(
          "Veuillez selectionner une panne avant d'ajouter des champs extra",
        );
      }
    }


    void removeLastDynamicField(BuildContext context, InterventionFormBLoc formBloc) {
    // Ensure that there are dynamic fields to remove
    if (formBloc.dynamicFields.isEmpty) return;

    // Iterate from the last to the first list of dynamic fields
    for (int i = formBloc.dynamicFields.length - 1; i >= 0; i--) {
      final fieldsList = formBloc.dynamicFields.values.elementAt(i);

      // Check if any field in the list is added to the form
      bool isFieldAdded = fieldsList.any((field) => formBloc.state.fieldBlocs()?.containsKey(field.name) ?? false);

      if (isFieldAdded) {
        formBloc.removeFieldBlocs(fieldBlocs: fieldsList);
        break;
      }
    }
  }


}

class CustomRangeTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue,
      TextEditingValue newValue,) {
    print("new value ==> ${newValue.text}");
    if (newValue.text == '')
      return TextEditingValue();
    else if (double.parse(newValue.text) < -26)
      return TextEditingValue().copyWith(text: '-25.99');

    return double.parse(newValue.text) > -15
        ? TextEditingValue().copyWith(text: '-15')
        : newValue;
  }
}

class NumericalRangeFormatter extends TextInputFormatter {
  final double min;
  final double max;

  NumericalRangeFormatter({required this.min, required this.max});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue,
      TextEditingValue newValue,) {
    print("oldValue ==> ${oldValue.text}");
    print("newValue ==> ${newValue.text}");

    if (newValue.text == '-' && oldValue.text == '') {
      return newValue;
    }

    if (newValue.text == '') {
      return newValue;
    } else if (int.parse(newValue.text) < min) {
      return TextEditingValue().copyWith(text: min.toStringAsFixed(2));
    } else {
      return int.parse(newValue.text) > max ? oldValue : newValue;
    }
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
                      contentsBuilder: (context, index) =>
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(Tools.selectedDemande
                                  ?.commentaires?[index].commentaire ??
                                  ""),
                            ),
                          ),
                      oppositeContentsBuilder: (context, index) =>
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                                alignment: AlignmentDirectional.centerEnd,
                                child: Column(
                                  children: [
                                    // Text(Tools.selectedDemande?.commentaires?[index].userId ?? ""),
                                    Text(Tools.selectedDemande
                                        ?.commentaires?[index]
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
                right: notificationCount
                    .toString()
                    .length >= 3 ? 15 : 25,
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
