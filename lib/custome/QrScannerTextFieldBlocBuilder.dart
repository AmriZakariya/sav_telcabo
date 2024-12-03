import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';

class QrScannerTextFieldBlocBuilder extends StatefulWidget {
  final TextFieldBloc<dynamic> qrCodeTextFieldBloc;
  final FormBloc formBloc;
  final Widget iconField;
  final String labelText;

  QrScannerTextFieldBlocBuilder({
    Key? key,
    required this.qrCodeTextFieldBloc,
    required this.formBloc,
    required this.iconField,
    required this.labelText,
  })  : assert(qrCodeTextFieldBloc != null),
        assert(formBloc != null),
        super(key: key);

  @override
  State<QrScannerTextFieldBlocBuilder> createState() =>
      _QrScannerTextFieldBlocBuilderState();
}

class _QrScannerTextFieldBlocBuilderState
    extends State<QrScannerTextFieldBlocBuilder> {


  @override
  Widget build(BuildContext context) {
    // print("MediaQuery.of(context).size.width / 4.9");
    // print(MediaQuery.of(context).size.width / 4.9);

    Future<dynamic> _popTime() async {
      Navigator.of(context).pop();
    }

    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller


    // Future<String> _showDialog() async {
    //   String barcodeScanRes;
    //
    //   try {
    //     barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
    //         '#ff6666', 'Cancel', true, ScanMode.QR);
    //     print(barcodeScanRes);
    //   } on PlatformException {
    //     barcodeScanRes = 'Failed to get platform version.';
    //   }
    //
    //   return barcodeScanRes;
    // }

    return BlocBuilder<TextFieldBloc, TextFieldBlocState>(
      bloc: widget.qrCodeTextFieldBloc,
      builder: (context, state) {
        return Container(
            child: Row(
          children: [
            Flexible(
              child: TextFieldBlocBuilder(
                // isEnabled: false,
                textFieldBloc: widget.qrCodeTextFieldBloc,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: widget.labelText,
                  prefixIcon: widget.iconField,
                  disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        width: 1,
                        // color: Tools.colorPrimary
                      ),
                      borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
            Visibility(
              visible: widget.formBloc.state
                  .fieldBlocs()
                  ?.containsKey(widget.qrCodeTextFieldBloc.name) ??
                  true,
              child: ElevatedButton(
                onPressed: () async {
                  // Navigator.of(context).push(MaterialPageRoute(
                  //   builder: (context) => const QRViewExample(),
                  // ));

                  // final result = await _showDialog();
                  final result = "";
              //                            final image = await ImagePicker.pickImage(
              //                              source: ImageSource.gallery,
              //                            );

                  if (widget.qrCodeTextFieldBloc.name == "adresse_mac") {
                    String formattedMAC = "";
                    for (int i = 0; i < result.length; i++) {
                      var char = result[i];
                      formattedMAC += char;
                      if ((i % 2 != 0) && (i < result.length - 1)) {
                        formattedMAC += "-";
                      }
                    }

                    widget.qrCodeTextFieldBloc.updateValue(formattedMAC);
                  } else {
                    widget.qrCodeTextFieldBloc
                        .updateValue(result);
                  }
                                },
                style: ElevatedButton.styleFrom(
                  // primary: Tools.colorPrimary,
                  shape: CircleBorder(),
                  padding: EdgeInsets.all(10),
                ),
                child: const Icon(Icons.qr_code),
              ),
            ),
          ],
        ));
      },
    );
  }
}
