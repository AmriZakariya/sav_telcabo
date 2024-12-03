import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:signature/signature.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SignatureFieldBlocBuilder extends StatefulWidget {
  final InputFieldBloc<File?, Object> signatureFieldBloc;
  final FormBloc formBloc;
  final String labelText;

  const SignatureFieldBlocBuilder({
    Key? key,
    required this.signatureFieldBloc,
    required this.formBloc,
    required this.labelText,
  }) : super(key: key);

  @override
  _SignatureFieldBlocBuilderState createState() =>
      _SignatureFieldBlocBuilderState();
}

class _SignatureFieldBlocBuilderState extends State<SignatureFieldBlocBuilder> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  Future<File?> _saveSignature() async {
    try {
      if (_controller.isEmpty) return null;

      // Get the image (ui.Image) and handle it safely
      final ui.Image? image = await _controller.toImage();
      if (image == null) return null;

      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final signatureFile = File('${tempDir.path}/signature.png');
      await signatureFile.writeAsBytes(pngBytes);
      return signatureFile;
    } catch (e) {
      debugPrint('Error saving signature: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InputFieldBloc<File?, Object>,
        InputFieldBlocState<File?, Object>>(
        bloc: widget.signatureFieldBloc,
        builder: (context, fieldBlocState) {
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(widget.labelText),
    const SizedBox(height: 10),
    Container(
    decoration: BoxDecoration(
    border: Border.all(color: Colors.grey),
    ),
    child: Signature(
    controller: _controller,
    height: 200,
    backgroundColor: Colors.white,
    ),
    ),
    const SizedBox(height: 10),
    Row(
    children: [
    ElevatedButton(
    onPressed: () async {
    final signatureFile = await _saveSignature();
    if (signatureFile != null) {
    widget.signatureFieldBloc.updateValue(signatureFile);
    }
    },
    child: const Text("Save Signature"),
    ),
    const SizedBox(width: 10),
    ElevatedButton(
    onPressed: () {
    _controller.clear();
    widget.signatureFieldBloc.updateValue(null);
    },
    child: const Text("Clear"),
    ),
    ],
    ),
    if (fieldBlocState.value != null)
    Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Image.file(
    fieldBlocState.value!,
    height: 100,
    fit: BoxFit.contain,
    ),
    ),
    if (fieldBlocState.hasError)
    Padding(
    padding: const EdgeInsets.only(top: 5),

