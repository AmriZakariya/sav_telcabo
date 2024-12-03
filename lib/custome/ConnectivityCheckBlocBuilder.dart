
import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:telcabo/Tools.dart';

enum ConnectionType {
  wifi,
  mobile,
}

@immutable
abstract class InternetState extends Equatable {}

class InternetLoading extends InternetState {
  @override
  List<Object?> get props => [];
}

class InternetConnected extends InternetState {
  final ConnectionType connectionType;

  InternetConnected({required this.connectionType});

  @override
  List<Object?> get props => [];
}

class InternetDisconnected extends InternetState {

  @override
  List<Object?> get props => [];
}



class InternetCubit extends Cubit<InternetState> {
  final Connectivity connectivity;
  Timer? timer;

  StreamSubscription? connectivityStreamSubscription;
  InternetCubit({required this.connectivity})
      : assert(connectivity != null),
        super(Tools.getStateFromConnectivity() ) {

    tryConnection() ;
    timer = Timer.periodic(Duration(seconds: 30), (Timer t) => tryConnection());

    connectivityStreamSubscription =
        connectivity.onConnectivityChanged.listen((connectivityResult) {
          // if (connectivityResult == ConnectivityResult.wifi) {
          //   emitInternetConnected(ConnectionType.wifi);
          // } else if (connectivityResult == ConnectivityResult.mobile) {
          //   emitInternetConnected(ConnectionType.mobile);
          // } else if (connectivityResult == ConnectivityResult.none) {
          //   emitInternetDisconnected();
          // }
          tryConnection();
        });
  }



  Future<void> tryConnection() async {

    var connectivityResult = await connectivity.checkConnectivity();
    print("tryConnection ==> connectivityResult : ${connectivityResult}");

    if (connectivityResult == ConnectivityResult.none) {
      emitInternetDisconnected();
      return ;
    }


    try {
      final response = await InternetAddress.lookup('www.google.com');

      print("tryConnection ==> response : ${response}");
      if (response.isNotEmpty && response[0].rawAddress.isNotEmpty) {
        if (connectivityResult == ConnectivityResult.wifi) {
          emitInternetConnected(ConnectionType.wifi);

        } else if (connectivityResult == ConnectivityResult.mobile) {
          emitInternetConnected(ConnectionType.mobile);

        }
      }else{
        emitInternetDisconnected();
      }




      } on SocketException catch (e) {
      print("tryConnection ==> SocketException : ${e}");

      emitInternetDisconnected();
      return ;
    }






  }


  void emitInternetConnected(ConnectionType _connectionType) {
      emit(InternetConnected(connectionType: _connectionType));
  }

  void emitInternetDisconnected() => emit(InternetDisconnected());

  @override
  Future<void> close() {
    timer?.cancel();
    connectivityStreamSubscription?.cancel();
    return super.close();
  }
}