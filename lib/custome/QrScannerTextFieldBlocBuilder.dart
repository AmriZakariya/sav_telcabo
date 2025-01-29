import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
  }) : super(key: key);

  @override
  State<QrScannerTextFieldBlocBuilder> createState() =>
      _QrScannerTextFieldBlocBuilderState();
}

class _QrScannerTextFieldBlocBuilderState
    extends State<QrScannerTextFieldBlocBuilder> {
  @override
  Widget build(BuildContext context) {
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(width: 1),
                  ),
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
                  final scannedValue = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ScannerPage(),
                    ),
                  );

                  if (scannedValue != null && scannedValue is String) {
                    String formattedValue = scannedValue;

                    if (widget.qrCodeTextFieldBloc.name == "adresse_mac") {
                      formattedValue = _formatMacAddress(scannedValue);
                    }

                    setState(() {
                      widget.qrCodeTextFieldBloc.updateValue(formattedValue);
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(10),
                  iconSize: 25,
                ),
                child: const Icon(Icons.qr_code),
              ),
            ),
          ]),
        );
      },
    );
  }

  /// Formats MAC Address
  String _formatMacAddress(String raw) {
    String formattedMAC = "";
    for (int i = 0; i < raw.length; i++) {
      formattedMAC += raw[i];
      if ((i % 2 != 0) && (i < raw.length - 1)) {
        formattedMAC += "-";
      }
    }
    return formattedMAC;
  }
}

class ScannerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Code"),
      ),
      body: MobileScanner(
        onDetect: (BarcodeCapture capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final String? scannedValue = barcodes.first.rawValue;
            if (scannedValue != null) {
              Navigator.of(context).pop(scannedValue); // Return scanned value
            }
          }
        },
      ),
    );
  }
}
