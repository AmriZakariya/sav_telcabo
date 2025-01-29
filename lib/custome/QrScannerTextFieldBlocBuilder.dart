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

class ScannerPage extends StatefulWidget {
  @override
  _ScannerPageState createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final MobileScannerController controller = MobileScannerController();

  @override
  void dispose() {
    controller.dispose(); // Release camera resources
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background for better contrast
      appBar: AppBar(
        title: const Text("Scanner un QR Code"),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (BarcodeCapture capture) async {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? scannedValue = barcodes.first.rawValue;
                if (scannedValue != null) {
                  await controller.stop(); // Stop scanner before closing
                  if (context.mounted) {
                    Navigator.of(context).pop(scannedValue);
                  }
                }
              }
            },
          ),

          // Overlay to indicate scan area
          Center(
            child: Stack(
              children: [
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        "Placez le code dans le cadre",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,

                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Animated Scan Line
          Positioned(
            top: MediaQuery.of(context).size.height / 2 - 125,
            left: MediaQuery.of(context).size.width / 2 - 125,
            child: SizedBox(
              width: 250,
              height: 250,
              child: AnimatedAlign(
                alignment: Alignment.bottomCenter,
                duration: const Duration(seconds: 2),
                curve: Curves.easeInOut,
                child: Container(
                  width: 250,
                  height: 2,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

