import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:telcabo/Tools.dart';

class UploadTest extends StatelessWidget {
  UploadTest({Key? key}) : super(key: key);
  late XFile _imageFile;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upload Image to Server',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: Stack(children: [
          CircleAvatar(
            radius: 72.0,
            backgroundColor: Colors.transparent,
            backgroundImage: NetworkImage(
                "https://www.whatsappprofiledpimages.com/wp-content/uploads/2021/08/Profile-Photo-Wallpaper.jpg"),
          ),
          Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    width: 4,
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                  color: Colors.red,
                ),
                child: TextButton(
                  onPressed: () {
                    _pickImage();
                  },
                  child: Icon(
                    Icons.edit,
                    color: Colors.white,
                  ),
                ),
              )),
        ]),
      ),
    );
  }

  final ImagePicker _picker = ImagePicker();

  void _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      _imageFile = pickedFile!;

      await uploadImage();
    } catch (e) {
      print("Image picker error " + e.toString());
    }
  }

  late FormData formData;

  uploadImage() async {
    print("Image picker uploading11 ");
    // File file = File(_imageFile);
    // try {
    //   Map fileMap = {};
    //
    //   String fileName = "profile_pic";
    //   fileMap["profile_picture"] = MultipartFile(
    //       file.openRead(), await file.length(),
    //       filename: fileName);
    //
    //
    // } catch (e) {
    //   print("Image picker error " + e.toString());
    // }

    formData = FormData.fromMap(
        {"id": "34",
          "profile_picture": "",
          "sendimage": await MultipartFile.fromFile(_imageFile.path,filename: _imageFile.name)
        });


    Dio dio = Dio();
    dio
      ..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        // Do something before request is sent

        return handler.next(options); //continue
      }, onResponse: (response, handler) {
        return handler.next(response); // continue
      }, onError: (DioError e, handler) {
        return handler.next(e); //continue
      }));

    Response apiRespon =
        await dio.post("${Tools.baseUrl}/traitements/add_mobile",
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

    if (apiRespon.statusCode == 201) {
      apiRespon.statusCode == 201;
    } else {
      print('errr');
    }
  }
}
