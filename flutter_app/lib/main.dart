import 'dart:async';
import 'dart:core';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/providerclass.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'JsonConversor.dart';

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  if (await Permission.camera.request().isGranted) {
    final cameras = await availableCameras();

    // Get a specific camera from the list of available cameras.
    final firstCamera = cameras.first;

    runApp(
      ChangeNotifierProvider(
        create: (context) => JsonProvider(),
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: TakePictureScreen(
            // Pass the appropriate camera to the TakePictureScreen widget.
            camera: firstCamera,
          ),
        ),
      ),
    );
  } else {
    runApp(
      MaterialApp(
          theme: ThemeData.dark(),
          home: AlertDialog(
            title: Text("Please give camera permissions"),
            actions: <Widget>[
              FlatButton(
                  child: Text('Ok'),
                  onPressed: () {
                    exit(0);
                  })
            ],
          )),
    );
  }
}

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  const TakePictureScreen({
    Key key,
    @required this.camera,
  }) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  CameraController _controller;
  Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Take a picture')),
      // Wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner
      // until the controller has finished initializing.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera_alt),
        // Provide an onPressed callback.
        onPressed: () async {
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          try {
            // Ensure that the camera is initialized.
            await _initializeControllerFuture;

            // Construct the path where the image should be saved using the
            // pattern package.
            final path = join(
              // Store the picture in the temp directory.
              // Find the temp directory using the `path_provider` plugin.
              (await getExternalStorageDirectory()).path,
              '${DateTime.now()}.png',
            );

            // Attempt to take a picture and log where it's been saved.
            await _controller.takePicture(path);

            // If the picture was taken, display it on a new screen.
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DisplayPictureScreen(imagePath: path),
              ),
            );
          } catch (e) {
            // If an error occurs, log the error to the console.
            print(e);
          }
        },
      ),
    );
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({Key key, this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isPhone = MediaQuery.of(context).size.shortestSide < 600;

    final provider = Provider.of<JsonProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Display the Picture')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Center(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.file(
          File(imagePath),
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          scale: isPhone ? 1 : 0.30,
        ),
      )),

      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.send),
        onPressed: () {
          provider.setImagePath(imagePath);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return DisplayCroppedPicture(
                  imagePath: imagePath,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class DisplayCroppedPicture extends StatelessWidget {
  final String imagePath;

  const DisplayCroppedPicture({Key key, this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isPhone = MediaQuery.of(context).size.shortestSide < 600;

    return Scaffold(
        appBar: AppBar(title: Text('Display the Picture')),
        // The image is stored as a file on the device. Use the `Image.file`
        // constructor with the given path to display the image.
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.home),
          onPressed: () async {
            Navigator.popUntil(context, ModalRoute.withName("/"));
          },
        ),
        body: FutureBuilder<JsonConversor>(
          future: Provider.of<JsonProvider>(context).sendPost(),
          builder: (context, snapshot) {
            //  aFIXME cuando me devuelve más de 1 crop dar todas las opciones
            if (snapshot.hasData) {
              return OrientationBuilder(builder: (context, orientation) {
                return ListView.builder(
                    itemCount: snapshot.data.result.croppings.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      final width = snapshot
                          .data.result.croppings[index].targetWidth
                          .toDouble();
                      final height = snapshot
                          .data.result.croppings[index].targetHeight
                          .toDouble();
                      return ListView(
                        shrinkWrap: true,
                        children: [
                          Center(
                              child: Padding(
                                  padding: orientation == Orientation.landscape
                                      ? const EdgeInsets.all(10.0)
                                      : const EdgeInsets.all(40.0),
                                  child: Text(
                                    'Cropped Image',
                                    style: TextStyle(
                                        fontFamily: 'avenir',
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        fontSize: isPhone ? 24 : 56),
                                  ))),
                          Center(
                              child: Padding(
                            padding: orientation == Orientation.landscape
                                ? const EdgeInsets.all(10.0)
                                : const EdgeInsets.all(40.0),
                            child: Image.file(File(imagePath),
                                width: isPhone ? width : width * 3.0,
                                height: isPhone ? height : height * 3.0,
                                fit: BoxFit.fitWidth),
                          )),
                          Center(
                              child: Padding(
                                  padding: orientation == Orientation.landscape
                                      ? const EdgeInsets.all(10.0)
                                      : const EdgeInsets.all(40.0),
                                  child: Text(
                                    "New Width : " +
                                        snapshot.data.result.croppings[index]
                                            .targetWidth
                                            .toString() +
                                        "\nNew Height : " +
                                        snapshot.data.result.croppings[index]
                                            .targetHeight
                                            .toString(),
                                    style: TextStyle(
                                        fontFamily: 'avenir',
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        fontSize: isPhone ? 24 : 56),
                                  ))),
                          Divider(color: Colors.white,)
                        ],
                      );
                    });
              });
            } else if (snapshot.hasError) {
              return AlertDialog(
                title: Text("Not able to connect to the server."),
                actions: <Widget>[
                  FlatButton(
                      child: Text('Ok'),
                      onPressed: () {
                        exit(0);
                      })
                ],
              );
            }
            return Center(child: CircularProgressIndicator());
          },
        ));
  }
}
