
/*

class LatitudeLongitudeTextFieldsBlocBuilder extends StatelessWidget {
  final TextFieldBloc<dynamic> latitudeTextFieldBloc;
  final TextFieldBloc<dynamic> longitudeTextFieldBloc;
  final FormBloc formBloc;
  final Widget iconField;
  final String labelText;

  LatitudeLongitudeTextFieldsBlocBuilder({
    Key? key,
    required this.latitudeTextFieldBloc,
    required this.longitudeTextFieldBloc,
    required this.formBloc,
    required this.iconField,
    required this.labelText,
  })  : super(key: key);



  @override
  Widget build(BuildContext context) {


    Future<dynamic> _popTime() async {
      Navigator.of(context).pop();
    }

    return Container(
        child: Row(
          children: [
            Flexible(
              flex: 5,
              child: Container(
                child: Column(
                  children: [
                    TextFieldBlocBuilder(
                      isEnabled: false,
                      textFieldBloc: formBloc.latitudeTextField,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: "Latitude :",
                        prefixIcon:  Icon(Icons.location_on),
                        disabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              width: 1,
                              // color: Tools.colorPrimary
                            ),
                            borderRadius:
                            BorderRadius.circular(20)),

                      ),
                    ),
                    TextFieldBlocBuilder(
                      isEnabled: false,
                      textFieldBloc: formBloc.longintudeTextField,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: "Longitude :",
                        prefixIcon:  Icon(Icons.location_on),
                        disabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              width: 1,
                              // color: Tools.colorPrimary
                            ),
                            borderRadius:
                            BorderRadius.circular(20)),

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

                  Position? position = await _determinePosition();
                  if(position != null) {
                    formBloc.latitudeTextField.updateValue(
                        position.latitude.toStringAsFixed(4));
                    formBloc.longintudeTextField.updateValue(
                        position.longitude.toStringAsFixed(4));
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
        ));


    return Column(
      children: [
        BlocBuilder<TextFieldBloc, TextFieldBlocState>(
          bloc: latitudeTextFieldBloc,
          builder: (context, state) {
            return Container(
                child: Row(
                  children: [
                    Flexible(
                      child: TextFieldBlocBuilder(
                        // isEnabled: false,
                        textFieldBloc: qrCodeTextFieldBloc,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: labelText,
                          prefixIcon: iconField,
                          disabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                width: 1,
                                // color: Tools.colorPrimary
                              ),
                              borderRadius:
                              BorderRadius.circular(20)),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        // Navigator.of(context).push(MaterialPageRoute(
                        //   builder: (context) => const QRViewExample(),
                        // ));

                        final barCodeResult = await _showDialog();
//                            final image = await ImagePicker.pickImage(
//                              source: ImageSource.gallery,
//                            );

                        if (barCodeResult != null) {
                          qrCodeTextFieldBloc.updateValue(barCodeResult.code ?? "000000");
                        }




                      },
                      style: ElevatedButton.styleFrom(
                        // primary: Tools.colorPrimary,
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(10),
                      ),
                      child: const Icon(Icons.qr_code),
                    ),
                  ],
                ));
          },
        ),
      ],
    );
  }
}*/
