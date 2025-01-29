import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:image/image.dart' as imagePlugin;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:telcabo/Tools.dart';

class ImageFieldBlocBuilder extends StatefulWidget {
  final InputFieldBloc<XFile?, Object> fileFieldBloc;
  final FormBloc formBloc;
  final Widget iconField;
  final String labelText;

  ImageFieldBlocBuilder({
    Key? key,
    required this.fileFieldBloc,
    required this.formBloc,
    required this.iconField,
    required this.labelText,
  })  : assert(fileFieldBloc != null),
        assert(formBloc != null),
        super(key: key);

  @override
  State<ImageFieldBlocBuilder> createState() => _ImageFieldBlocBuilderState();
}

class _ImageFieldBlocBuilderState extends State<ImageFieldBlocBuilder> {
  final ImagePicker _picker = ImagePicker();
  String imageSrc = "camera";
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InputFieldBloc<XFile?, Object>,
        InputFieldBlocState<XFile?, Object>>(
      bloc: widget.fileFieldBloc,
      builder: (context, fieldBlocState) {
        return BlocBuilder<FormBloc, FormBlocState>(
          bloc: widget.formBloc,
          builder: (context, formBlocState) {
            return Visibility(
              visible: widget.formBloc.state
                      .fieldBlocs()
                      ?.containsKey(widget.fileFieldBloc.name) ??
                  true,
              child: Column(
                children: [
                  isLoading
                      ? Center(child: CircularProgressIndicator())
                      : GestureDetector(
                          onTap: formBlocState.canSubmit
                              ? () async {
                                  await _showDialog();
                                  if (imageSrc != "none") {
                                    setState(() => isLoading = true);
                                    try {
                                      final imageResult = await _pickImage();
                                      if (imageResult != null) {
                                        // final compressedImage =
                                        //     await _compressImage(imageResult);
                                        widget.fileFieldBloc.updateValue(
                                            XFile(imageResult.path));
                                      }
                                    } finally {
                                      setState(() => isLoading = false);
                                    }
                                  }
                                }
                              : null,
                          child: _buildImageDisplay(fieldBlocState),
                        ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ElevatedButton.icon(
                onPressed: () {
                  imageSrc = "camera";
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Caméra'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  imageSrc = "gallery";
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.image_outlined),
                label: const Text('Galerie'),
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton.icon(
              onPressed: () {
                imageSrc = "none";
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.cancel),
              label: const Text('Annuler'),
            ),
          ],
        );
      },
    );
  }

  Future<XFile?> _pickImage() async {
    return await _picker.pickImage(
      source: imageSrc == "camera" ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 50,
    );
  }

  Future<File> _compressImage(XFile imageFile) async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;

    return compute(_compressImageInBackground, {
      'path': imageFile.path,
      'destination':
          '$path/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
    });
  }

  Widget _buildImageDisplay(
      InputFieldBlocState<XFile?, Object> fieldBlocState) {
    return Column(
      children: [
        Center(child: Text(widget.labelText, textAlign: TextAlign.center)),
        const SizedBox(height: 10),
        Stack(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: fieldBlocState.value != null
                    ? Image.file(
                        File(fieldBlocState.value!.path),
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      )
                    : _buildPlaceholder(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (fieldBlocState.canShowError) _buildErrorText(),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Image.network(
      getImagePickerExistImageUrl(),
      width: 90,
      height: 90,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Icon(Icons.image_not_supported_outlined, size: 40),
        );
      },
    );
  }

  Widget _buildErrorText() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        "Ce champ est obligatoire",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.red, fontSize: 12),
      ),
    );
  }

  String getImagePickerExistImageUrl() {
    String imageUrl = "${Tools.baseUrl}/img/demandes/";

    final imageMappings = {
      "photo_probleme": Tools.selectedDemande?.photoProbleme ?? "",
      "photo_signal": Tools.selectedDemande?.photoSignal ?? "",
      "photo_resolution_probleme":
          Tools.selectedDemande?.photoResolutionProbleme ?? "",
      "photo_sup1": Tools.selectedDemande?.photoSup1 ?? "",
      "photo_sup2": Tools.selectedDemande?.photoSup2 ?? "",
    };

    // Append the corresponding value based on the fileFieldBloc name
    imageUrl += imageMappings[widget.fileFieldBloc.name] ?? "";

    return imageUrl;
  }
}

Future<File> _compressImageInBackground(Map<String, String> params) async {
  final originalImage =
      imagePlugin.decodeImage(File(params['path']!).readAsBytesSync());
  final resizedImage = imagePlugin.copyResize(originalImage!, width: 120);
  final compressedImage = File(params['destination']!)
    ..writeAsBytesSync(imagePlugin.encodeJpg(resizedImage, quality: 85));
  return compressedImage;
}
