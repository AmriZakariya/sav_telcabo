import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:dio_logger/dio_logger.dart';
import 'package:flutter/material.dart';

// import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as imagePLugin;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telcabo/custome/ConnectivityCheckBlocBuilder.dart';
import 'package:telcabo/models/response_get_demandes.dart';

import 'models/response_get_liste_pannes.dart';

class Tools {
  // static String baseUrl = "https://telcabo.castlit.com" ;
  // static String baseUrl = "https://crmtelcabo.com" ;
  // static String baseUrl = "https://sav.castlit.com";
  static String baseUrl = "https://sav.crmtelcabo.com";

  static bool localWatermark = false;

  static Demande? selectedDemande;
  static int currentStep = 1;

  static ResponseGetDemandesList? demandesListSaved;

  static Map? searchFilter = {};
  static String currentDemandesEtatFilter = "";

  static String deviceToken = "";

  static String userId = "";

  static String userName = "";

  static String userEmail = "";

  static String ETAT_EN_COURS = "1";
  static String ETAT_PLANIFIE = "2";
  static String ETAT_RESOLU = "3";
  static String ETAT_ANNULE = "4";

  static String languageCode = "ar";

  static final Color colorPrimary = Color(0xff3f4d67);
  static final Color colorSecondary = Color(0xfff99e25);
  static final Color colorBackground = Color(0xfff3f1ef);

  static String getLanguageName() {
    switch (languageCode) {
      case "ar":
        return "العربية";
      case "fr":
        return "Français";
    }

    return languageCode;
  }

  static File filePannesList = File("");
  static File fileDemandesList = File("");
  static File fileTraitementList = File("");

  static void initFiles() {
    print("initFiles!");
    try {
      getApplicationDocumentsDirectory().then((Directory directory) {
        filePannesList = new File(directory.path + "/filePannesList.json");
        fileDemandesList = new File(directory.path + "/fileDemandesList.json");
        fileTraitementList = new File(directory.path + "/fileTraitementList.json");

        if (!filePannesList.existsSync()) {
          filePannesList.createSync();
        }

        if (!fileDemandesList.existsSync()) {
          fileDemandesList.createSync();
        }

        if (!fileTraitementList.existsSync()) {
          fileTraitementList.createSync();
        }
      });
    } catch (e) {
      print("exeption -- " + e.toString());
    }
  }

  static Future<ResponseGetListPannes> callWSGetPannes() async {
    print("****** callWSGetPannes ******");

    try {
      Dio dio = Dio();
      dio.interceptors.add(dioLoggerInterceptor);

      final response = await dio.get("${Tools.baseUrl}/pannes/get_pannes");

      print('[WS GET_PANNES] Response status: ${response.statusCode}');
      print('[WS GET_PANNES] Response body: ${response.data}');

      if (response.statusCode == 200) {
        if (response.data != null && response.data.isNotEmpty) {
          try {
            final responseApiHome = jsonDecode(response.data);

            final pannesList = ResponseGetListPannes.fromJson(responseApiHome);
            print(pannesList);
            return pannesList;
          } catch (e) {
            print("[WS GET_PANNES] Error decoding response: $e");
            throw Exception("Failed to parse response");
          }
        } else {
          print("[WS GET_PANNES] Empty or null response data");
          throw Exception("Empty response");
        }
      } else {
        print("[WS GET_PANNES] Non-200 response: ${response.statusCode}");
        throw Exception('Error fetching pannes');
      }
    } on DioError catch (e) {
      print("************** DioError **************");
      if (e.response != null) {
        print("[WS GET_PANNES] Server error: ${e.response?.statusMessage}");
        throw Exception(e.response?.statusMessage ?? "Unknown server error");
      } else {
        print("[WS GET_PANNES] Request setup error: ${e.message}");
        throw Exception("Request error: ${e.message}");
      }
    } catch (e) {
      print("[WS GET_PANNES] Unexpected error: $e");
      // Fallback to local cache if all else fails
      return Tools.readfilePannesList();
    }
  }

  static Future<ResponseGetDemandesList> getDemandes() async {
    FormData formData = FormData.fromMap({"user_id": userId});

    print(formData.fields.toString());

    Response apiRespon;
    try {
      print("************** getDemandes ***********");
      Dio dio = new Dio();
      dio.interceptors.add(dioLoggerInterceptor);

      apiRespon = await dio.post("${Tools.baseUrl}/demandes/get_demandes",
          data: formData,
          options: Options(
            // followRedirects: false,
            // validateStatus: (status) { return status < 500; },
            method: "POST",
            headers: {
              'Content-Type': 'multipart/form-data;charset=UTF-8',
              'Charset': 'utf-8',
              'Accept': 'application/json',
            },
          ));

      print('Response status: ${apiRespon.statusCode}');
      print('Response body: ${apiRespon.data}');

      if (apiRespon.statusCode == 200) {
        var responseApiHome = jsonDecode(apiRespon.data);
        writeToFileDemandeList(responseApiHome);

        ResponseGetDemandesList demandesList =
            ResponseGetDemandesList.fromJson(responseApiHome);
        print(demandesList);

        return demandesList;
      } else {
        throw Exception('error fetching posts');
      }
    } on DioError catch (e) {
      print("**************DioError***********");
      print(e);
      // The request was made and the server responded with a status code
      // that falls out of the range of 2xx and is also not 304.
      if (e.response != null) {
        //        print(e.response.data);
        //        print(e.response.headers);
        //        print(e.response.);
        //           print("**->REQUEST ${e.response?.re.uri}#${Transformer.urlEncodeMap(e.response?.request.data)} ");
        // throw (e.response?.statusMessage ?? "");
      } else {
        // Something happened in setting up or sending the request that triggered an Error
        //        print(e.request);
        //        print(e.message);
      }
    } catch (e) {
      print("API ERROR ${e}");
      return ResponseGetDemandesList(demandes: []);
    }

    // return ResponseGetDemandesList(demandes: []) ;

    return readfileDemandesList();
  }

  static Future<bool> callWSSendMail() async {
    FormData formData =
        FormData.fromMap({"demande_id": Tools.selectedDemande?.id});

    Response apiRespon;
    try {
      print("************** callWSSendMail ***********");
      Dio dio = new Dio();

      apiRespon = await dio.post("${Tools.baseUrl}/traitements/send_mail",
          data: formData,
          options: Options(
            // followRedirects: false,
            // validateStatus: (status) { return status < 500; },
            method: "POST",
            headers: {
              'Content-Type': 'multipart/form-data;charset=UTF-8',
              'Charset': 'utf-8',
              'Accept': 'application/json',
            },
          ));

      print('Response status: ${apiRespon.statusCode}');
      print('Response body: ${apiRespon.data}');

      if (apiRespon.statusCode == 200) {
        if (apiRespon.data == "000") {
          return true;
        }
      } else {
        throw Exception('error fetching posts');
      }
    } on DioError catch (e) {
      print("**************DioError***********");
      print(e);
      // The request was made and the server responded with a status code
      // that falls out of the range of 2xx and is also not 304.
      if (e.response != null) {
        //        print(e.response.data);
        //        print(e.response.headers);
        //        print(e.response.);
        //           print("**->REQUEST ${e.response?.re.uri}#${Transformer.urlEncodeMap(e.response?.request.data)} ");
        throw (e.response?.statusMessage ?? "");
      } else {
        // Something happened in setting up or sending the request that triggered an Error
        //        print(e.request);
        //        print(e.message);
      }
    } catch (e) {
      // throw ('API ERROR');
      print("API ERROR ${e}");
      return false;
    }

    // return ResponseGetDemandesList(demandes: []) ;

    return false;
  }

  static void writeToFilePannesList(Map jsonMapContent) {
    print("Writing to writeToFilePanneList!");
    try {
      filePannesList.writeAsStringSync(json.encode(jsonMapContent));
      print("OK");
    } catch (e) {
      print("exeption -- " + e.toString());
    }
  }

  static void writeToFileDemandeList(Map jsonMapContent) {
    print("Writing to writeToFileDemandeList!");
    try {
      fileDemandesList.writeAsStringSync(json.encode(jsonMapContent));
      print("OK");
    } catch (e) {
      print("exeption -- " + e.toString());
    }
  }

  static Future<void> readFileTraitementList() async {
    print("readFileTraitementList!");

    // fileTraitementList.writeAsStringSync("");
    // return ;
    try {
      String fileContent = fileTraitementList.readAsStringSync();
      print("file content ==> ${fileContent}");

      if (!fileContent.isEmpty) {
        Map<String, dynamic> demandeListMap = json.decode(fileContent);

        print(demandeListMap);

        List traitementList = demandeListMap.values.elementAt(0);
        print("traitementList length==> ${traitementList.length}");
        print("traitementList ==> ${traitementList}");

        List traitementListResult = [];

        for (int i = 0; i < traitementList.length; i++) {
          print("element ==> ${traitementList[i]}");

          var isUpdated =
              await callWsAddMobileFromLocale(jsonDecode(traitementList[i]));
          if (isUpdated == true) {
            print("readFileTraitementList isUpdated success");
          } else {
            print("readFileTraitementList added");
            traitementListResult.add(traitementList[i]);
          }
        }

        print(
            "readFileTraitementList isUpdated traitementListResultlength ==> ${traitementListResult.length}");

        Map rsultMap = {"traitementList": traitementListResult};
        fileTraitementList.writeAsStringSync(json.encode(rsultMap));
      } else {
        print("empty file");
      }
    } catch (e) {
      print(" readFileTraitementList exeption -- " + e.toString());
    }
  }

  static Future<bool> callWsAddMobileFromLocale(
      Map<String, dynamic> jsonMapContent) async {
    print("****** callWsAddMobileFromLocale ***");

    String currentAddress = "";

    try {
      currentAddress = await Tools.getAddressFromLatLng();
    } catch (e) {
      return false;
    }

    String currentDate = jsonMapContent["date"];
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();

    for (var mapKey in jsonMapContent.keys) {
      if (mapKey == "p_pbi_avant" ||
          mapKey == "p_pbi_apres" ||
          mapKey == "p_pbo_avant" ||
          mapKey == "p_pbo_apres" ||
          mapKey == "p_equipement_installe" ||
          mapKey == "p_test_signal" ||
          mapKey == "p_etiquetage_indoor" ||
          mapKey == "p_etiquetage_outdoor" ||
          mapKey == "p_passage_cable" ||
          mapKey == "p_fiche_instalation" ||
          mapKey == "p_dos_routeur" ||
          mapKey == "p_speed_test" ||
          mapKey == "photo_blocage1" ||
          mapKey == "photo_blocage2") {
        try {
          if (jsonMapContent[mapKey] != null &&
              jsonMapContent[mapKey] != "null" &&
              jsonMapContent[mapKey] != "") {
            final splitted = jsonMapContent[mapKey].split(";;");

            if (Tools.localWatermark == true) {
              final File fileResult = File(splitted[0]);

              final image =
                  imagePLugin.decodeImage(fileResult.readAsBytesSync())!;
              // imagePLugin.drawString(
              //     image, imagePLugin.arial_24, 0, 0, currentDate);
              // imagePLugin.drawString(
              //     image, imagePLugin.arial_24, 0, 32, currentAddress);

              await getApplicationDocumentsDirectory()
                  .then((Directory directory) {
                File fileResultWithWatermark =
                    File(directory.path + "/" + fileName + '.png');
                fileResultWithWatermark
                    .writeAsBytesSync(imagePLugin.encodePng(image));

                XFile xfileResult = XFile(fileResultWithWatermark.path);

                jsonMapContent[mapKey] = MultipartFile.fromFileSync(
                    xfileResult.path,
                    filename: xfileResult.name);

                print("watermark success");
              });
            } else {
              jsonMapContent[mapKey] = MultipartFile.fromFileSync(splitted[0],
                  filename: splitted[1]);
            }
          }
        } catch (e) {
          print("+++ exception ++++");
          print(e);
          jsonMapContent[mapKey] = null;
        }
      }
    }

    jsonMapContent.addAll({"isOffline": true});

    print("callWsAddMobileFromLocale jsonMapContent ==> ${jsonMapContent}");

    FormData formData = FormData.fromMap(jsonMapContent);
    print(formData);

    Response apiRespon;
    try {
      print("**************doPOST***********");
      Dio dio = new Dio();
      dio.interceptors.add(dioLoggerInterceptor);

      apiRespon = await dio.post("${Tools.baseUrl}/traitements/add_mobile",
          data: formData,
          options: Options(
            method: "POST",
            headers: {
              'Content-Type': 'multipart/form-data;charset=UTF-8',
              'Charset': 'utf-8'
            },
          ));

      print("Image Upload ${apiRespon}");

      print(apiRespon);

      if (apiRespon.data == "000") {
        return true;
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
        //        print(e.response.data);
        //        print(e.response.headers);
        //        print(e.response.);
        //           print("**->REQUEST ${e.response?.re.uri}#${Transformer.urlEncodeMap(e.response?.request.data)} ");
        // throw (e.response?.statusMessage ?? "");
      } else {
        // Something happened in setting up or sending the request that triggered an Error
        //        print(e.request);
        //        print(e.message);
      }
    } catch (e) {
      // throw ('API ERROR');
      print("API ERROR ${e}");
      return false;
    }

    return false;
  }

  static T _readFile<T>(
      File file, T Function(Map<String, dynamic>) fromJson, T emptyResponse) {
    print("[INFO] Starting file read: ${file.path}");
    try {
      String fileContent = file.readAsStringSync();
      print("[DEBUG] File content: ${fileContent}");

      if (fileContent.isNotEmpty) {
        Map<String, dynamic> dataMap = json.decode(fileContent);
        print("[DEBUG] Parsed JSON: $dataMap");
        return fromJson(dataMap);
      } else {
        print("[WARNING] File is empty: ${file.path}");
      }
    } catch (e, stackTrace) {
      print(
          "[ERROR] Exception while reading file ${file.path}: ${e.toString()}");
      print("[ERROR] StackTrace: $stackTrace");
    }

    print("[INFO] Returning empty response for: ${file.path}");
    return emptyResponse;
  }

  static ResponseGetListPannes readfilePannesList() {
    return _readFile<ResponseGetListPannes>(
      filePannesList,
      (data) => ResponseGetListPannes.fromJson(data),
      ResponseGetListPannes(pannes: []),
    );
  }

  static ResponseGetDemandesList readfileDemandesList() {
    return _readFile<ResponseGetDemandesList>(
      fileDemandesList,
      (data) => ResponseGetDemandesList.fromJson(data),
      ResponseGetDemandesList(demandes: []),
    );
  }

  static Future<ResponseGetListPannes>
      getPannesListFromLocalAndInternet() async {
    print("****** get getPannesListFromLocalAndInternet ***");
    ResponseGetListPannes responseGetListPannes;

    if (await Tools.tryConnection()) {
      responseGetListPannes = await Tools.callWSGetPannes();
    } else {
      responseGetListPannes = Tools.readfilePannesList();
    }

    print(
        "****** getListEtatFromLocalAndINternet *** return  ${responseGetListPannes.toJson()} ");

    return responseGetListPannes;
  }

  static Future<bool> tryConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    print("tryConnection ==> connectivityResult : ${connectivityResult}");

    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }

    try {
      final response = await InternetAddress.lookup('www.google.com');

      print("tryConnection ==> response : ${response}");
      if (response.isEmpty) {
        return false;
      }

      if (response.isNotEmpty && response[0].rawAddress.isNotEmpty) {
        return true;
      } else {
        return false;
      }
    } on SocketException catch (e) {
      print("tryConnection ==> SocketException : ${e}");
      return false;
    }

    return false;
  }

  static Future<ResponseGetDemandesList>
      getListDemandeFromLocalAndINternet() async {
    ResponseGetDemandesList responseGetDemandesList;

    if (await Tools.tryConnection()) {
      print("read from ws");
      responseGetDemandesList = await Tools.getDemandes();
    } else {
      responseGetDemandesList = Tools.readfileDemandesList();
    }

    return responseGetDemandesList;
  }

  static Future<bool> callWsLogin(Map<String, dynamic> formDateValues) async {
    print("Tools.deviceToken = " + Tools.deviceToken);

    formDateValues.addAll({"registration_id": Tools.deviceToken});

    print(formDateValues);

    FormData formData = FormData.fromMap(formDateValues);

    Response apiRespon;
    try {
      print("************** callWsLogin ***********");
      Dio dio = new Dio();

      apiRespon = await dio.post("${Tools.baseUrl}/users/login_android",
          data: formData,
          options: Options(
            // followRedirects: false,
            // validateStatus: (status) { return status < 500; },
            method: "POST",
            headers: {
              'Content-Type': 'multipart/form-data;charset=UTF-8',
              'Charset': 'utf-8',
              'Accept': 'application/json',
            },
          ));

      print(apiRespon);

      Map result = json.decode(apiRespon.data) as Map;

      String userId = result["id"];
      String userName = result["name"];

      if (userId.isNotEmpty && userId != "0") {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isOnline', true);
        await prefs.setString('userId', userId);
        await prefs.setString('userName', userName);
        await prefs.setString('userEmail', formDateValues["username"]);

        Tools.userId = userId;
        Tools.userName = userName;
        Tools.userEmail = formDateValues["username"];

        return true;
      }
      // print(json.decode(apiRespon).toString());
    } on DioError catch (e) {
      print("**************DioError***********");
      print(e);
      // The request was made and the server responded with a status code
      // that falls out of the range of 2xx and is also not 304.
      if (e.response != null) {
        //        print(e.response.data);
        //        print(e.response.headers);
        //        print(e.response.);
        //           print("**->REQUEST ${e.response?.re.uri}#${Transformer.urlEncodeMap(e.response?.request.data)} ");
        throw (e.response?.statusMessage ?? "");
      } else {
        // Something happened in setting up or sending the request that triggered an Error
        //        print(e.request);
        print(e.message);
        throw (e);
      }
    } catch (e) {
      // throw ('API ERROR');
      print("API ERROR ${e}");
      return false;
    }

    return false;
  }

  static Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      // return Future.error('Location services are disabled.');
      return Future.error('Les services de localisation sont désactivés.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        // return Future.error('Location permissions are denied');
        return Future.error('Les autorisations de localisation sont refusées');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      // return Future.error(
      //     'Location permissions are permanently denied, we cannot request permissions.');
      return Future.error(
          'Les autorisations de localisation sont définitivement refusées, nous ne pouvons pas demander d\'autorisations.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  static Future<bool> refreshSelectedDemande() async {
    print("****** callWSRefreshSelectedDEmande ***");

    FormData formData =
        FormData.fromMap({"demande_id": Tools.selectedDemande?.id ?? ""});

    print(formData);

    Response apiRespon;
    try {
      print("************** getDemandes ***********");
      Dio dio = new Dio();
      dio.interceptors.add(dioLoggerInterceptor);

      apiRespon = await dio.post("${Tools.baseUrl}/demandes/get_demandes_byid",
          data: formData,
          options: Options(
            // followRedirects: false,
            // validateStatus: (status) { return status < 500; },
            method: "POST",
            headers: {
              'Content-Type': 'multipart/form-data;charset=UTF-8',
              'Charset': 'utf-8',
              'Accept': 'application/json',
            },
          ));

      print('Response status: ${apiRespon.statusCode}');
      print('Response body: ${apiRespon.data}');

      if (apiRespon.statusCode == 200) {
        var responseApiHome = jsonDecode(apiRespon.data);

        ResponseGetDemandesList demandesList =
            ResponseGetDemandesList.fromJson(responseApiHome);
        print(demandesList);

        Tools.selectedDemande = demandesList.demandes?.first;

        int? selectedIndex = Tools.demandesListSaved?.demandes
            ?.indexWhere((element) => element.id == Tools.selectedDemande?.id);

        if (selectedIndex != null && Tools.selectedDemande != null) {
          Tools.demandesListSaved?.demandes?[selectedIndex] =
              Tools.selectedDemande!;
        }

        return true;
      } else {
        throw Exception('error fetching posts');
      }
    } on DioError catch (e) {
      print("**************DioError***********");
      print(e);
      // The request was made and the server responded with a status code
      // that falls out of the range of 2xx and is also not 304.
      if (e.response != null) {
        //        print(e.response.data);
        //        print(e.response.headers);
        //        print(e.response.);
        //           print("**->REQUEST ${e.response?.re.uri}#${Transformer.urlEncodeMap(e.response?.request.data)} ");
        throw (e.response?.statusMessage ?? "");
      } else {
        // Something happened in setting up or sending the request that triggered an Error
        //        print(e.request);
        //        print(e.message);
      }
    } catch (e) {
      // throw ('API ERROR');
      print("API ERROR ${e}");
      return false;
    }

    return false;
  }

  // static Future<File?> compressAndGetFile(File file, String targetPath) async {
  //   var result = await FlutterImageCompress.compressAndGetFile(
  //       file.absolute.path, targetPath,
  //       quality: 60, minWidth: 800, minHeight: 600);
  //
  //   return result;
  // }

  static ConnectivityResult? connectivityResult;

  static getStateFromConnectivity() {
    if (Tools.connectivityResult == ConnectivityResult.wifi) {
      return InternetConnected(connectionType: ConnectionType.wifi);
    } else if (Tools.connectivityResult == ConnectivityResult.mobile) {
      return InternetConnected(connectionType: ConnectionType.mobile);
    } else if (Tools.connectivityResult == ConnectivityResult.none) {
      return InternetDisconnected();
    }

    return InternetLoading();
  }

  static Future<String> getAddressFromLatLng() async {
    print("call function getAddressFromLatLng");
    String coordinateString = "";

    // try {

    Position? position = await determinePosition();

    if (position != null) {
      coordinateString =
          "( latitude = ${position.latitude}   longitude =  ${position.longitude} )";

      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];
      print(place);

      String fullAddess =
          " ${place.locality}, ${place.postalCode}, ${place.country}";

      return coordinateString + " " + fullAddess;
      // return "${position.}, ${place.postalCode}, ${place.country}"
    }

    // } catch (e) {
    //   // print()
    //   print(e);
    // }

    return coordinateString;
  }

  // static Future<XFile?> compressAndGetFile(File file, String targetPath,
  //     [int quality = 80]) async {
  //   var result = await FlutterImageCompress.compressAndGetFile(
  //     file.absolute.path,
  //     targetPath,
  //     quality: quality,
  //   );
  //
  //   print(file.lengthSync());
  //   // print(result?.lengthSync());
  //
  //   return result;
  // }

  static getColorByEtatId(String? etatId) {
    if (etatId != null) {
      if (etatId == Tools.ETAT_EN_COURS) {
        return Colors.transparent;
      } else if (etatId == Tools.ETAT_PLANIFIE) {
        return Colors.orange;
      } else if (etatId == Tools.ETAT_RESOLU) {
        return Colors.green;
      } else if (etatId == Tools.ETAT_ANNULE) {
        return Colors.red;
      }
    }

    return Colors.transparent;
  }
}
