import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:dio_logger/dio_logger.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as imagePlugin;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telcabo/custome/ConnectivityCheckBlocBuilder.dart';
import 'package:telcabo/models/response_get_demandes.dart';
import 'models/response_get_liste_pannes.dart';

class Tools {
  // Base URL for the APIs
  static String baseUrl = "https://sav.crmtelcabo.com";

  // Configurations and constants
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

  // Demand states
  static String ETAT_EN_COURS = "1";
  static String ETAT_PLANIFIE = "2";
  static String ETAT_RESOLU = "3";
  static String ETAT_ANNULE = "4";

  // Language code
  static String languageCode = "ar";

  // Colors
  static final Color colorPrimary = const Color(0xff3f4d67);
  static final Color colorSecondary = const Color(0xfff99e25);
  static final Color colorBackground = const Color(0xfff3f1ef);

  // Local files
  static File filePannesList = File("");
  static File fileDemandesList = File("");
  static File fileTraitementList = File("");

  // Connectivity result
  static ConnectivityResult? connectivityResult;

  /// Returns the readable language name from languageCode.
  static String getLanguageName() {
    switch (languageCode) {
      case "ar":
        return "العربية";
      case "fr":
        return "Français";
      default:
        return languageCode;
    }
  }

  /// Initialize local files used to store offline data.
  static void initFiles() {
    getApplicationDocumentsDirectory().then((Directory directory) {
      filePannesList = File("${directory.path}/filePannesList.json");
      fileDemandesList = File("${directory.path}/fileDemandesList.json");
      fileTraitementList = File("${directory.path}/fileTraitementList.json");

      if (!filePannesList.existsSync()) filePannesList.createSync();
      if (!fileDemandesList.existsSync()) fileDemandesList.createSync();
      if (!fileTraitementList.existsSync()) fileTraitementList.createSync();
    }).catchError((e) {
      print("initFiles exception: $e");
    });
  }

  /// Calls the web service to get pannes list.
  /// Falls back to local file if API fails.
  static Future<ResponseGetListPannes> callWSGetPannes() async {
    print("[INFO] callWSGetPannes started");
    try {
      Dio dio = Dio();
      dio.interceptors.add(dioLoggerInterceptor);
      final response = await dio.get("$baseUrl/pannes/get_pannes");

      print("[DEBUG] GET_PANNES status: ${response.statusCode}");
      if (response.statusCode == 200 && response.data != null && response.data.isNotEmpty) {
        final responseApiHome = jsonDecode(response.data);
        writeToFilePannesList(responseApiHome);
        return ResponseGetListPannes.fromJson(responseApiHome);
      } else {
        print("[ERROR] Empty or invalid response from GET_PANNES");
        throw Exception(
            "Empty response");
      }
    } on DioError catch (e) {
      print("[ERROR] DioError in callWSGetPannes: ${e.message}");
      return readfilePannesList();
    } catch (e) {
      print("[ERROR] Exception in callWSGetPannes: $e");
      return readfilePannesList();
    }
  }

  /// Calls the web service to get demandes.
  /// Updates local file on success, otherwise returns empty list or fallback.
  static Future<ResponseGetDemandesList> getDemandes() async {
    print("[INFO] getDemandes started");
    FormData formData = FormData.fromMap({"user_id": userId});
    print("[DEBUG] formData for getDemandes: ${formData.fields}");

    try {
      Dio dio = Dio();
      dio.interceptors.add(dioLoggerInterceptor);
      Response apiRespon = await dio.post(
        "$baseUrl/demandes/get_demandes",
        data: formData,
        options: Options(
          method: "POST",
          headers: {
            'Content-Type': 'multipart/form-data;charset=UTF-8',
            'Accept': 'application/json',
          },
        ),
      );

      print("[DEBUG] getDemandes status: ${apiRespon.statusCode}");
      if (apiRespon.statusCode == 200) {
        var responseApiHome = jsonDecode(apiRespon.data);
        writeToFileDemandeList(responseApiHome);
        return ResponseGetDemandesList.fromJson(responseApiHome);
      } else {
        print("[ERROR] Non-200 response in getDemandes");
        return ResponseGetDemandesList(demandes: []);
      }
    } on DioError catch (e) {
      print("[ERROR] DioError in getDemandes: ${e.message}");
      return ResponseGetDemandesList(demandes: []);
    } catch (e) {
      print("[ERROR] Exception in getDemandes: $e");
      return ResponseGetDemandesList(demandes: []);
    }
  }

  /// Calls the web service to send mail for selected demande.
  static Future<bool> callWSSendMail() async {
    print("[INFO] callWSSendMail started");
    FormData formData = FormData.fromMap({"demande_id": selectedDemande?.id});
    try {
      Dio dio = Dio();
      Response apiRespon = await dio.post(
        "$baseUrl/traitements/send_mail",
        data: formData,
        options: Options(
          method: "POST",
          headers: {
            'Content-Type': 'multipart/form-data;charset=UTF-8',
            'Accept': 'application/json',
          },
        ),
      );

      print("[DEBUG] callWSSendMail status: ${apiRespon.statusCode}, body: ${apiRespon.data}");
      if (apiRespon.statusCode == 200 && apiRespon.data == "000") {
        return true;
      }
      return false;
    } on DioError catch (e) {
      print("[ERROR] DioError in callWSSendMail: ${e.message}");
      return false;
    } catch (e) {
      print("[ERROR] Exception in callWSSendMail: $e");
      return false;
    }
  }

  /// Writes pannes list to local file.
  static void writeToFilePannesList(Map jsonMapContent) {
    try {
      filePannesList.writeAsStringSync(json.encode(jsonMapContent));
    } catch (e) {
      print("[ERROR] writeToFilePannesList exception: $e");
    }
  }

  /// Writes demandes list to local file.
  static void writeToFileDemandeList(Map jsonMapContent) {
    try {
      fileDemandesList.writeAsStringSync(json.encode(jsonMapContent));
    } catch (e) {
      print("[ERROR] writeToFileDemandeList exception: $e");
    }
  }

  /// Reads traitement list from local file and tries to sync them via API.
  static Future<void> readFileTraitementList() async {
    print("[INFO] readFileTraitementList started");
    try {
      String fileContent = fileTraitementList.readAsStringSync();
      if (fileContent.isNotEmpty) {
        Map<String, dynamic> demandeListMap = json.decode(fileContent);
        List traitementList = demandeListMap.values.elementAt(0);
        List traitementListResult = [];

        for (var element in traitementList) {
          var isUpdated = await callWsAddMobileFromLocale(jsonDecode(element));
          if (!isUpdated) {
            traitementListResult.add(element);
          }
        }
        Map rsultMap = {"traitementList": traitementListResult};
        fileTraitementList.writeAsStringSync(json.encode(rsultMap));
      }
    } catch (e) {
      print("[ERROR] readFileTraitementList exception: $e");
    }
  }

  /// Uploads and processes offline traitement data.
  /// Adds watermark if enabled and attempts to send data to server.
  static Future<bool> callWsAddMobileFromLocale(Map<String, dynamic> jsonMapContent) async {
    print("[INFO] callWsAddMobileFromLocale started");
    String currentAddress;
    try {
      currentAddress = await getAddressFromLatLng();
    } catch (e) {
      print("[ERROR] getAddressFromLatLng failed: $e");
      return false;
    }

    String currentDate = jsonMapContent["date"];
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();

    // Fields that may contain image paths
    List<String> imageFields = [
      "p_pbi_avant",
      "p_pbi_apres",
      "p_pbo_avant",
      "p_pbo_apres",
      "p_equipement_installe",
      "p_test_signal",
      "p_etiquetage_indoor",
      "p_etiquetage_outdoor",
      "p_passage_cable",
      "p_fiche_instalation",
      "p_dos_routeur",
      "p_speed_test",
      "photo_blocage1",
      "photo_blocage2"
    ];

    for (var mapKey in imageFields) {
      try {
        if (jsonMapContent[mapKey] != null &&
            jsonMapContent[mapKey] != "null" &&
            jsonMapContent[mapKey] != "") {
          final splitted = jsonMapContent[mapKey].split(";;");
          if (localWatermark) {
            final fileResult = File(splitted[0]);
            final image = imagePlugin.decodeImage(fileResult.readAsBytesSync());
            if (image != null) {
              // Add watermark or custom text if needed
              Directory dir = await getApplicationDocumentsDirectory();
              File fileResultWithWatermark = File("${dir.path}/$fileName.png");
              fileResultWithWatermark.writeAsBytesSync(imagePlugin.encodePng(image));
              XFile xfileResult = XFile(fileResultWithWatermark.path);
              jsonMapContent[mapKey] = MultipartFile.fromFileSync(
                xfileResult.path,
                filename: xfileResult.name,
              );
            }
          } else {
            jsonMapContent[mapKey] = MultipartFile.fromFileSync(
              splitted[0],
              filename: splitted[1],
            );
          }
        }
      } catch (e) {
        print("[ERROR] Processing image field $mapKey failed: $e");
        jsonMapContent[mapKey] = null;
      }
    }

    jsonMapContent.addAll({"isOffline": true});
    FormData formData = FormData.fromMap(jsonMapContent);

    try {
      Dio dio = Dio();
      dio.interceptors.add(dioLoggerInterceptor);
      Response apiRespon = await dio.post(
        "$baseUrl/traitements/add_mobile",
        data: formData,
        options: Options(
          method: "POST",
          headers: {
            'Content-Type': 'multipart/form-data;charset=UTF-8',
          },
        ),
      );

      print("[DEBUG] callWsAddMobileFromLocale response: ${apiRespon.data}");
      if (apiRespon.data == "000") {
        return true;
      }
    } on DioError catch (e) {
      print("[ERROR] DioError in callWsAddMobileFromLocale: ${e.message}");
      return false;
    } catch (e) {
      print("[ERROR] Exception in callWsAddMobileFromLocale: $e");
      return false;
    }
    return false;
  }

  /// Generic file reader with JSON parsing.
  static T _readFile<T>(
      File file,
      T Function(Map<String, dynamic>) fromJson,
      T emptyResponse,
      ) {
    print("[INFO] Reading file: ${file.path}");
    try {
      String fileContent = file.readAsStringSync();
      if (fileContent.isNotEmpty) {
        Map<String, dynamic> dataMap = json.decode(fileContent);
        return fromJson(dataMap);
      } else {
        print("[WARNING] File is empty: ${file.path}");
      }
    } catch (e, stackTrace) {
      print("[ERROR] Exception while reading ${file.path}: $e");
      print("[ERROR] StackTrace: $stackTrace");
    }
    return emptyResponse;
  }

  /// Reads pannes list from local file.
  static ResponseGetListPannes readfilePannesList() {
    return _readFile<ResponseGetListPannes>(
      filePannesList,
          (data) => ResponseGetListPannes.fromJson(data),
      ResponseGetListPannes(pannes: []),
    );
  }

  /// Reads demandes list from local file.
  static ResponseGetDemandesList readfileDemandesList() {
    return _readFile<ResponseGetDemandesList>(
      fileDemandesList,
          (data) => ResponseGetDemandesList.fromJson(data),
      ResponseGetDemandesList(demandes: []),
    );
  }

  /// Tries to get pannes list from internet, if no connection uses local file.
  static Future<ResponseGetListPannes> getPannesListFromLocalAndInternet() async {
    print("[INFO] getPannesListFromLocalAndInternet started");
    if (await tryConnection()) {
      return callWSGetPannes();
    } else {
      return readfilePannesList();
    }
  }

  /// Checks internet connectivity by pinging Google.
  static Future<bool> tryConnection() async {
    print("[INFO] tryConnection started");
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      print("[DEBUG] No internet connectivity");
      return false;
    }
    try {
      final response = await InternetAddress.lookup('www.google.com');
      return response.isNotEmpty && response[0].rawAddress.isNotEmpty;
    } on SocketException catch (e) {
      print("[ERROR] SocketException in tryConnection: $e");
      return false;
    }
  }

  /// Tries to get demandes list from internet, if no connection uses local file.
  static Future<ResponseGetDemandesList> getListDemandeFromLocalAndINternet() async {
    print("[INFO] getListDemandeFromLocalAndINternet started");
    if (await tryConnection()) {
      return getDemandes();
    } else {
      return readfileDemandesList();
    }
  }

  /// Calls login API and stores user info if successful.
  static Future<bool> callWsLogin(Map<String, dynamic> formDateValues) async {
    print("[INFO] callWsLogin started");
    formDateValues["registration_id"] = deviceToken;
    FormData formData = FormData.fromMap(formDateValues);

    try {
      Dio dio = Dio();
      Response apiRespon = await dio.post(
        "$baseUrl/users/login_android",
        data: formData,
        options: Options(
          method: "POST",
          headers: {
            'Content-Type': 'multipart/form-data;charset=UTF-8',
            'Accept': 'application/json',
          },
        ),
      );

      Map result = json.decode(apiRespon.data) as Map;
      String uid = result["id"];
      String uname = result["name"];

      if (uid.isNotEmpty && uid != "0") {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isOnline', true);
        await prefs.setString('userId', uid);
        await prefs.setString('userName', uname);
        await prefs.setString('userEmail', formDateValues["username"]);
        userId = uid;
        userName = uname;
        userEmail = formDateValues["username"];
        return true;
      }
    } on DioError catch (e) {
      print("[ERROR] DioError in callWsLogin: ${e.message}");
      return false;
    } catch (e) {
      print("[ERROR] Exception in callWsLogin: $e");
      return false;
    }
    return false;
  }

  /// Determines the device's current position, handling all permission checks.
  static Future<Position> determinePosition() async {
    print("[INFO] determinePosition started");
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Les services de localisation sont désactivés.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Les autorisations de localisation sont refusées');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Les autorisations de localisation sont définitivement refusées.');
    }

    return await Geolocator.getCurrentPosition();
  }

  /// Refreshes the selected demande by calling the API.
  static Future<bool> refreshSelectedDemande() async {
    print("[INFO] refreshSelectedDemande started");
    FormData formData = FormData.fromMap({"demande_id": selectedDemande?.id ?? ""});
    try {
      Dio dio = Dio();
      dio.interceptors.add(dioLoggerInterceptor);
      Response apiRespon = await dio.post(
        "$baseUrl/demandes/get_demandes_byid",
        data: formData,
        options: Options(
          method: "POST",
          headers: {
            'Content-Type': 'multipart/form-data;charset=UTF-8',
            'Accept': 'application/json',
          },
        ),
      );

      if (apiRespon.statusCode == 200) {
        var responseApiHome = jsonDecode(apiRespon.data);
        ResponseGetDemandesList demandesList =
        ResponseGetDemandesList.fromJson(responseApiHome);
        selectedDemande = demandesList.demandes?.first;

        int? selectedIndex = demandesListSaved?.demandes
            ?.indexWhere((element) => element.id == selectedDemande?.id);

        if (selectedIndex != null && selectedIndex >= 0 && selectedDemande != null) {
          demandesListSaved?.demandes?[selectedIndex] = selectedDemande!;
        }
        return true;
      } else {
        print("[ERROR] Non-200 response in refreshSelectedDemande");
        return false;
      }
    } on DioError catch (e) {
      print("[ERROR] DioError in refreshSelectedDemande: ${e.message}");
      return false;
    } catch (e) {
      print("[ERROR] Exception in refreshSelectedDemande: $e");
      return false;
    }
  }

  /// Returns the appropriate state from the connectivity result.
  static getStateFromConnectivity() {
    print("[INFO] getStateFromConnectivity started");
    if (connectivityResult == ConnectivityResult.wifi) {
      return InternetConnected(connectionType: ConnectionType.wifi);
    } else if (connectivityResult == ConnectivityResult.mobile) {
      return InternetConnected(connectionType: ConnectionType.mobile);
    } else if (connectivityResult == ConnectivityResult.none) {
      return InternetDisconnected();
    }
    return InternetLoading();
  }

  /// Attempts to get a formatted address from the current latitude and longitude.
  static Future<String> getAddressFromLatLng() async {
    print("[INFO] getAddressFromLatLng started");
    Position position = await determinePosition();
    String coordinateString =
        "( latitude = ${position.latitude} longitude = ${position.longitude} )";
    List<Placemark> placemarks =
    await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark place = placemarks[0];
    String fullAddress = " ${place.locality}, ${place.postalCode}, ${place.country}";
    return "$coordinateString $fullAddress";
  }

  /// Returns a color based on the state ID.
  static Color getColorByEtatId(String? etatId) {
    if (etatId == ETAT_EN_COURS) return Colors.transparent;
    if (etatId == ETAT_PLANIFIE) return Colors.orange;
    if (etatId == ETAT_RESOLU) return Colors.green;
    if (etatId == ETAT_ANNULE) return Colors.red;
    return Colors.transparent;
  }
}
