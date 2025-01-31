import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart' as auth;


import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:dio_logger/dio_logger.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image/image.dart' as imagePlugin;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telcabo/DemandeList.dart';
import 'package:telcabo/custome/ConnectivityCheckBlocBuilder.dart';
import 'package:telcabo/models/response_get_demandes.dart';
import 'models/response_get_liste_pannes.dart';

/// Utility class for network calls, file handling, and data caching.
class Tools {
  static String baseUrl = "https://sav.crmtelcabo.com";
  static bool localWatermark = false;

  // Selected demande and cached data
  static Demande? selectedDemande;
  static ResponseGetDemandesList? demandesListSaved;

  // Common fields
  static int currentStep = 1;
  static Map? searchFilter = {};
  static String currentDemandesEtatFilter = "";
  static String deviceToken = "";
    static String fcmToken = "";
  static String userId = "";
  static String userName = "";
  static String userEmail = "";

  // Demand states
  static const String ETAT_EN_COURS = "1";
  static const String ETAT_PLANIFIE = "2";
  static const String ETAT_RESOLU = "3";
  static const String ETAT_ANNULE = "4";

  // Language and colors
  static String languageCode = "ar";
  static final Color colorPrimary = const Color(0xff3f4d67);
  static final Color colorSecondary = const Color(0xfff99e25);
  static final Color colorBackground = const Color(0xfff3f1ef);

  // Local files
  static File filePannesList = File("");
  static File fileDemandesList = File("");
  static File fileTraitementList = File("");

  // Connectivity
  static ConnectivityResult? connectivityResult;

  /// Unified logging method for easier log filtering.
  static void _log(String message) {
    print("[Tools] $message");
  }

  /// Unified error logging method.
  static void _logError(String message, [dynamic error, StackTrace? stackTrace]) {
    print("[Tools:ERROR] $message");
    if (error != null) print("[Tools:ERROR] Error: $error");
    if (stackTrace != null) print("[Tools:ERROR] StackTrace: $stackTrace");
  }

  /// Gets a human-readable language name.
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

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );

  /// Initialize local files used for caching.
  static void initFiles() {
    _log("initFiles started");
    getApplicationDocumentsDirectory().then((Directory directory) {
      filePannesList = File("${directory.path}/filePannesList.json");
      fileDemandesList = File("${directory.path}/fileDemandesList.json");
      fileTraitementList = File("${directory.path}/fileTraitementList.json");

      if (!filePannesList.existsSync()) filePannesList.createSync();
      if (!fileDemandesList.existsSync()) fileDemandesList.createSync();
      if (!fileTraitementList.existsSync()) fileTraitementList.createSync();
    }).catchError((e) {
      _logError("initFiles exception", e);
    });
  }

  /// Attempts a network call and on failure returns fallback data.
  static Future<T> _callApiWithFallback<T>({
    required Future<T> Function() apiCall,
    required T Function() fallback,
    String apiName = "",
  }) async {
    _log("$apiName: API call started");
    try {
      return await apiCall();
    } catch (e) {
      _logError("$apiName: Exception caught", e);
      _log("$apiName: Falling back to local data");
      return fallback();
    }
  }

  /// Generic method to decode response data (assumes `response.data` is a JSON string).
  static dynamic _decodeResponseData(Response response, String apiName) {
    if (response.statusCode == 200 && response.data != null && response.data.toString().isNotEmpty) {
      try {
        return jsonDecode(response.data);
      } catch (e) {
        _logError("$apiName: JSON decode error", e);
        return null;
      }
    } else {
      _logError("$apiName: Empty or invalid response");
      return null;
    }
  }

  /// Fetches the pannes list from API or local file.
  static Future<ResponseGetListPannes> callWSGetPannes() async {
    Dio dio = Dio()..interceptors.add(dioLoggerInterceptor);
    return _callApiWithFallback<ResponseGetListPannes>(
      apiCall: () async {
        _log("callWSGetPannes: calling API");
        final response = await dio.get("$baseUrl/pannes/get_pannes");
        final decoded = _decodeResponseData(response, "callWSGetPannes");
        if (decoded != null) {
          writeToFilePannesList(decoded);
          return ResponseGetListPannes.fromJson(decoded);
        }
        throw Exception("Invalid response from server");
      },
      fallback: readfilePannesList,
      apiName: "callWSGetPannes",
    );
  }

  /// Fetches the demandes list from API or returns empty on failure.
  static Future<ResponseGetDemandesList> getDemandes() async {
    Dio dio = Dio()..interceptors.add(dioLoggerInterceptor);
    FormData formData = FormData.fromMap({"user_id": userId});
    return _callApiWithFallback<ResponseGetDemandesList>(
      apiCall: () async {
        _log("getDemandes: calling API with formData: ${formData.fields}");
        final response = await dio.post(
          "$baseUrl/demandes/get_demandes",
          data: formData,
          options: Options(method: "POST", headers: {
            'Content-Type': 'multipart/form-data;charset=UTF-8',
            'Accept': 'application/json',
          }),
        );
        final decoded = _decodeResponseData(response, "getDemandes");
        if (decoded != null) {
          writeToFileDemandeList(decoded);
          return ResponseGetDemandesList.fromJson(decoded);
        }
        return ResponseGetDemandesList(demandes: []);
      },
      fallback: () => ResponseGetDemandesList(demandes: []),
      apiName: "getDemandes",
    );
  }

  /// Sends an email for the selected demande.
  static Future<bool> callWSSendMail() async {
    Dio dio = Dio();
    FormData formData = FormData.fromMap({"demande_id": selectedDemande?.id});
    try {
      _log("callWSSendMail: calling API");
      Response apiRespon = await dio.post(
        "$baseUrl/traitements/send_email",
        data: formData,
        options: Options(
          method: "POST",
          headers: {
            'Content-Type': 'multipart/form-data;charset=UTF-8',
            'Accept': 'application/json',
          },
        ),
      );
      _log("callWSSendMail: Response ${apiRespon.statusCode}, body: ${apiRespon.data}");
      return (apiRespon.statusCode == 200 && apiRespon.data == "000");
    } catch (e, st) {
      _logError("callWSSendMail: Exception", e, st);
      return false;
    }
  }

  /// Write pannes list to local file
  static void writeToFilePannesList(Map jsonMapContent) {
    _log("writeToFilePannesList");
    try {
      filePannesList.writeAsStringSync(json.encode(jsonMapContent));
    } catch (e, st) {
      _logError("writeToFilePannesList exception", e, st);
    }
  }

  /// Write demandes list to local file
  static void writeToFileDemandeList(Map jsonMapContent) {
    _log("writeToFileDemandeList");
    try {
      fileDemandesList.writeAsStringSync(json.encode(jsonMapContent));
    } catch (e, st) {
      _logError("writeToFileDemandeList exception", e, st);
    }
  }

  /// Reads the traitement list from local file and tries to sync it with API.
  static Future<void> readFileTraitementList() async {
    _log("readFileTraitementList started");
    try {
      String fileContent = fileTraitementList.readAsStringSync();
      if (fileContent.isNotEmpty) {
        _log("readFileTraitementList: file content: $fileContent");
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
      } else {
        _log("readFileTraitementList: empty file");
      }
    } catch (e, st) {
      _logError("readFileTraitementList exception", e, st);
    }
  }

  /// Prepares a single image field (apply watermark if needed).
  static Future<void> _prepareImageField(
      Map<String, dynamic> jsonMapContent, String field, String currentDate, String currentAddress) async {
    if (jsonMapContent[field] == null ||
        jsonMapContent[field] == "null" ||
        jsonMapContent[field] == "") return;

    final splitted = jsonMapContent[field].split(";;");
    String imagePath = splitted[0];
    String imageName = splitted[1];

    try {
      if (localWatermark) {
        final fileResult = File(imagePath);
        final image = imagePlugin.decodeImage(fileResult.readAsBytesSync());
        if (image != null) {
          // Add watermark text if needed:
          // For example:
          // imagePlugin.drawString(image, imagePlugin.arial_24, 0, 0, currentDate);
          // imagePlugin.drawString(image, imagePlugin.arial_24, 0, 32, currentAddress);

          Directory dir = await getApplicationDocumentsDirectory();
          File fileResultWithWatermark = File("${dir.path}/${DateTime.now().millisecondsSinceEpoch}.png");
          fileResultWithWatermark.writeAsBytesSync(imagePlugin.encodePng(image));
          XFile xfileResult = XFile(fileResultWithWatermark.path);

          jsonMapContent[field] = MultipartFile.fromFileSync(
            xfileResult.path,
            filename: xfileResult.name,
          );
        }
      } else {
        jsonMapContent[field] = MultipartFile.fromFileSync(
          imagePath,
          filename: imageName,
        );
      }
    } catch (e, st) {
      _logError("_prepareImageField: Exception for field $field", e, st);
      jsonMapContent[field] = null;
    }
  }

  /// Calls API to add mobile data from locale.
  static Future<bool> callWsAddMobileFromLocale(Map<String, dynamic> jsonMapContent) async {
    _log("callWsAddMobileFromLocale started");
    String currentAddress;
    try {
      currentAddress = await getAddressFromLatLng();
    } catch (e) {
      _logError("callWsAddMobileFromLocale: Failed to get address", e);
      return false;
    }

    String currentDate = jsonMapContent["date"];

    // List of fields that might contain images
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

    // Prepare image fields
    for (var field in imageFields) {
      await _prepareImageField(jsonMapContent, field, currentDate, currentAddress);
    }

    jsonMapContent.addAll({"isOffline": true});
    FormData formData = FormData.fromMap(jsonMapContent);

    try {
      Dio dio = Dio()..interceptors.add(dioLoggerInterceptor);
      _log("callWsAddMobileFromLocale: calling API");
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

      _log("callWsAddMobileFromLocale: Response ${apiRespon.data}");
      return (apiRespon.data == "000");
    } catch (e, st) {
      _logError("callWsAddMobileFromLocale: Exception", e, st);
      return false;
    }
  }

  /// Generic file reader with JSON parsing and fallback to empty response.
  static T _readFile<T>(
      File file,
      T Function(Map<String, dynamic>) fromJson,
      T emptyResponse,
      ) {
    _log("Reading file: ${file.path}");
    try {
      String fileContent = file.readAsStringSync();
      if (fileContent.isNotEmpty) {
        Map<String, dynamic> dataMap = json.decode(fileContent);
        return fromJson(dataMap);
      } else {
        _log("File is empty: ${file.path}");
      }
    } catch (e, st) {
      _logError("Exception while reading ${file.path}", e, st);
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

  /// Gets pannes list from either API or local cache.
  static Future<ResponseGetListPannes> getPannesListFromLocalAndInternet() async {
    _log("getPannesListFromLocalAndInternet started");
    if (await tryConnection()) {
      return callWSGetPannes();
    } else {
      return readfilePannesList();
    }
  }

  /// Checks if the device has internet connectivity.
  static Future<bool> tryConnection() async {
    _log("tryConnection started");
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _log("No internet connectivity");
      return false;
    }
    try {
      final response = await InternetAddress.lookup('www.google.com');
      bool hasConnection = response.isNotEmpty && response[0].rawAddress.isNotEmpty;
      _log("tryConnection: $hasConnection");
      return hasConnection;
    } on SocketException catch (e) {
      _logError("SocketException in tryConnection", e);
      return false;
    }
  }

  /// Gets demandes list from either API or local cache.
  static Future<ResponseGetDemandesList> getListDemandeFromLocalAndINternet() async {
    _log("getListDemandeFromLocalAndINternet started");
    if (await tryConnection()) {
      return getDemandes();
    } else {
      return readfileDemandesList();
    }
  }
  static Future<bool> callWsLogin(Map<String, dynamic> formDateValues) async {
    _log("callWsLogin started");

    formDateValues["registration_id"] = deviceToken;
    formDateValues["fcm_token"] = await getAccessTokenFromServiceAccount();
    _log("Request Data: ${formDateValues.toString()}");

    final formData = FormData.fromMap(formDateValues);
    final dio = Dio();

    try {
      _log("callWsLogin: calling API");
      final response = await dio.post(
        "$baseUrl/users/login_android",
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data;charset=UTF-8',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final result = json.decode(response.data);
        final uid = result["id"]?.toString() ?? "";
        final uname = result["name"]?.toString() ?? "";
        _log("Response Data: $result");

        if (uid.isNotEmpty && uid != "0") {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isOnline', true);
          await prefs.setString('userId', uid);
          await prefs.setString('userName', uname);
          await prefs.setString('userEmail', formDateValues["username"] ?? "");
          userId = uid;
          userName = uname;
          userEmail = formDateValues["username"] ?? "";
          return true;
        }
      }
    } catch (e, st) {
      _logError("callWsLogin: Exception", e, st);
    }

    return false;
  }

  /// Determines the device's current position.
  static Future<Position> determinePosition() async {
    _log("determinePosition started");
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

  /// Refreshes the selected demande from API and updates the local cache.
  static Future<bool> refreshSelectedDemande() async {
    _log("refreshSelectedDemande started");
    FormData formData = FormData.fromMap({"demande_id": selectedDemande?.id ?? ""});

    try {
      Dio dio = Dio()..interceptors.add(dioLoggerInterceptor);
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

      var decoded = _decodeResponseData(apiRespon, "refreshSelectedDemande");
      if (decoded != null) {
        ResponseGetDemandesList demandesList = ResponseGetDemandesList.fromJson(decoded);
        selectedDemande = demandesList.demandes?.first;

        int? selectedIndex = demandesListSaved?.demandes
            ?.indexWhere((element) => element.id == selectedDemande?.id);

        if (selectedIndex != null && selectedIndex >= 0 && selectedDemande != null) {
          demandesListSaved?.demandes?[selectedIndex] = selectedDemande!;

          // Notify UI that the demandes list has been updated
          demandeListKey.currentState?.filterListByMap();
        }
        return true;
      }
      return false;
    } catch (e, st) {
      _logError("refreshSelectedDemande: Exception", e, st);
      return false;
    }
  }


  /// Returns the current connectivity state.
  static getStateFromConnectivity() {
    _log("getStateFromConnectivity started");
    if (connectivityResult == ConnectivityResult.wifi) {
      return InternetConnected(connectionType: ConnectionType.wifi);
    } else if (connectivityResult == ConnectivityResult.mobile) {
      return InternetConnected(connectionType: ConnectionType.mobile);
    } else if (connectivityResult == ConnectivityResult.none) {
      return InternetDisconnected();
    }
    return InternetLoading();
  }

  /// Returns an address string based on current location.
  static Future<String> getAddressFromLatLng() async {
    _log("getAddressFromLatLng started");
    Position position = await determinePosition();
    String coordinateString = "( latitude = ${position.latitude} longitude = ${position.longitude} )";
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark place = placemarks[0];
    String fullAddress = " ${place.locality}, ${place.postalCode}, ${place.country}";
    return "$coordinateString $fullAddress";
  }

  /// Returns a color corresponding to the demande state.
  static Color getColorByEtatId(String? etatId) {
    switch (etatId) {
      case ETAT_EN_COURS:
        return Colors.transparent;
      case ETAT_PLANIFIE:
        return Colors.orange;
      case ETAT_RESOLU:
        return Colors.green;
      case ETAT_ANNULE:
        return Colors.red;
      default:
        return Colors.transparent;
    }
  }

  static Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // `googleAuth.aLiscessToken` and `googleAuth.idToken` can be sent to your backend
      // to verify and create a session. You can also integrate these tokens with
      // Firebase Auth or any other auth system if needed.

      print("User signed in: ${googleUser.displayName}");
      print("User email: ${googleUser.email}");
      print("Access Token: ${googleAuth.accessToken}");
      print("ID Token: ${googleAuth.idToken}");

      // You can store user info or navigate to a new screen after successful sign-in.

    } catch (error) {
      print("Google sign-in failed: $error");
    }
  }


  static Future<String?> getAccessTokenFromServiceAccount() async {
    final jsonStr = await rootBundle.loadString('assets/service-account.json');
    final credentials = jsonDecode(jsonStr);

    final serviceAccountCredentials = auth.ServiceAccountCredentials(
      credentials['client_email'],
      auth.ClientId(credentials['client_id'], null),
      credentials['private_key'],
    );

    final scopes = ['https://www.googleapis.com/auth/cloud-platform'];
    final client = await auth.clientViaServiceAccount(serviceAccountCredentials, scopes);
    final token = client.credentials.accessToken.data;
    client.close();

    // log(token);
    print("getAccessTokenFromServiceAccount => Token: $token");
    return token;
  }

  static String getMsgShare() {
    final demande = Tools.selectedDemande;
    return '''REF: ${demande?.ref ?? ""}
        CASE ID: ${demande?.caseId ?? ""}
        VILLE: ${demande?.ville ?? ""}
        CLIENT: ${demande?.client ?? ""}
        LOGIN_SIP: ${demande?.accesReseau ?? ""}
        PANNES: ${demande?.getPannesListString() ?? ""}
        SOLUTIONS: ${demande?.getSolutionsListString() ?? ""}''';
  }
}
